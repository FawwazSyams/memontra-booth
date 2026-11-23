<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\GoogleController;
use App\Models\Session;
use App\Models\Photo;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

Route::get('/', function () {
    return response()->json([
        'app' => 'Memontra Booth API',
        'status' => 'online',
        'version' => '2.0.0',
        'gateway' => 'doku'
    ]);
});

// Google Authentication
if (class_exists(\App\Http\Controllers\Auth\GoogleController::class)) {
    Route::get('/auth/google', [\App\Http\Controllers\Auth\GoogleController::class, 'redirect']);
    Route::get('/auth/google/callback', [\App\Http\Controllers\Auth\GoogleController::class, 'callback']);
}

// Debugging Helpers
Route::get('/debug-error', function () {
    $logFile = storage_path('logs/laravel.log');
    if (file_exists($logFile)) {
        $lines = file($logFile);
        return response('<pre>' . htmlspecialchars(implode("", array_slice($lines, -100))) . '</pre>');
    }
    return 'Log file not found at: ' . $logFile;
});

Route::get('/test-db', function () {
    try {
        \Illuminate\Support\Facades\DB::connection()->getPdo();
        return 'DB Connected successfully: ' . \Illuminate\Support\Facades\DB::connection()->getDatabaseName();
    } catch (\Throwable $e) {
        return 'DB Error: ' . $e->getMessage();
    }
});

// =========================================================================
// SOFTFILE DOWNLOAD ROUTES (HASIL FOTO + FRAME UNTUK CUSTOMER)
// =========================================================================

// Halaman utama galeri softfile foto untuk customer booth
Route::get('/download/{sessionId}', function ($sessionId) {
    $photos = collect([]);

    // 1. Coba ambil dari database jika database aktif
    try {
        if (class_exists(\App\Models\Photo::class)) {
            $dbPhotos = Photo::where('session_id', $sessionId)->orderBy('sequence_number')->get();
            if ($dbPhotos->isNotEmpty()) {
                $photos = $dbPhotos;
            }
        }
        if ($photos->isEmpty() && class_exists(\App\Models\Session::class)) {
            $session = Session::with('photos')->find($sessionId);
            if ($session && $session->photos) {
                $photos = $session->photos->sortBy('sequence_number');
            }
        }
    } catch (\Throwable $e) {
        // Fallback jika database belum aktif atau sesi belum tersimpan di DB
    }

    // 2. Fallback cerdas: Scan disk jika foto belum lengkap di database
    try {
        $diskPhotos = collect([]);

        // Cek file-file pose foto di disk
        $files = Storage::disk('public')->files('photos');
        foreach ($files as $file) {
            if (str_contains($file, $sessionId) && !str_contains($file, 'strip_')) {
                preg_match('/_pose_(\d+)_/', $file, $matches);
                $seq = isset($matches[1]) ? (int)$matches[1] : 1;

                $diskPhotos->push((object)[
                    'id' => md5($file),
                    'session_id' => $sessionId,
                    'file_path' => $file,
                    'sequence_number' => $seq,
                ]);
            }
        }

        if ($photos->isEmpty() && $diskPhotos->isNotEmpty()) {
            $photos = $diskPhotos->sortBy('sequence_number');
        }
    } catch (\Throwable $e) {
        // Storage fallback scan error handling
    }

    // 3. Selalu pastikan foto strip komposit + frame (sequence 0) diperiksa di disk
    $hasStrip = $photos->contains('sequence_number', 0);
    if (!$hasStrip) {
        $stripCandidates = [
            'photos/strip_' . $sessionId . '.png',
            'photos/strip_' . $sessionId . '.jpg',
            'photos/strip_' . $sessionId . '.jpeg',
            'photos/' . $sessionId . '_strip.png',
            'photos/' . $sessionId . '_strip.jpg',
        ];
        foreach ($stripCandidates as $stripPath) {
            if (Storage::disk('public')->exists($stripPath) || file_exists(storage_path('app/public/' . $stripPath))) {
                $photos->prepend((object)[
                    'id' => 'strip',
                    'session_id' => $sessionId,
                    'file_path' => $stripPath,
                    'sequence_number' => 0,
                ]);
                $hasStrip = true;
                break;
            }
        }
    }

    // 4. Fallback Pembuatan Strip Otomatis: Jika strip belum ada tapi ada pose foto
    if (!$hasStrip && $photos->isNotEmpty()) {
        try {
            $poseItems = $photos->where('sequence_number', '>', 0)->values();
            if ($poseItems->isNotEmpty() && function_exists('imagecreatetruecolor')) {
                $stripWidth = 1200;
                $stripHeight = 3600;
                $stripCanvas = imagecreatetruecolor($stripWidth, $stripHeight);
                $white = imagecolorallocate($stripCanvas, 255, 255, 255);
                imagefill($stripCanvas, 0, 0, $white);

                $slotY = [185, 1190, 2190];
                $slotW = 1020;
                $slotH = 830;
                $slotX = 90;

                for ($i = 0; $i < min(3, count($poseItems)); $i++) {
                    $item = $poseItems[$i];
                    $pPath = storage_path('app/public/' . $item->file_path);
                    if (file_exists($pPath)) {
                        $pImg = @imagecreatefromjpeg($pPath) ?: @imagecreatefrompng($pPath);
                        if ($pImg) {
                            $origW = imagesx($pImg);
                            $origH = imagesy($pImg);
                            imagecopyresampled(
                                $stripCanvas, $pImg,
                                $slotX, $slotY[$i], 0, 0,
                                $slotW, $slotH, $origW, $origH
                            );
                            imagedestroy($pImg);
                        }
                    }
                }

                // Coba muat frame overlay dari berbagai lokasi kandidat
                $frameCandidates = [
                    base_path('resources/frames/strip1.png'),
                    public_path('assets/frames/strip1.png'),
                    base_path('../public_html/assets/frames/strip1.png'),
                    base_path('resources/frames/strip2.png'),
                    public_path('assets/frames/strip2.png'),
                ];
                foreach ($frameCandidates as $fc) {
                    if (file_exists($fc)) {
                        $fImg = @imagecreatefrompng($fc);
                        if ($fImg) {
                            imagecopyresampled(
                                $stripCanvas, $fImg,
                                0, 0, 0, 0,
                                $stripWidth, $stripHeight, imagesx($fImg), imagesy($fImg)
                            );
                            imagedestroy($fImg);
                            break;
                        }
                    }
                }

                $genStripPng = storage_path('app/public/photos/strip_' . $sessionId . '.png');
                $genStripJpg = storage_path('app/public/photos/strip_' . $sessionId . '.jpg');
                @mkdir(dirname($genStripPng), 0775, true);
                imagepng($stripCanvas, $genStripPng);
                imagejpeg($stripCanvas, $genStripJpg, 90);
                imagedestroy($stripCanvas);

                if (file_exists($genStripPng)) {
                    $photos->prepend((object)[
                        'id' => 'strip',
                        'session_id' => $sessionId,
                        'file_path' => 'photos/strip_' . $sessionId . '.png',
                        'sequence_number' => 0,
                    ]);
                }
            }
        } catch (\Throwable $e) {
            Log::warning('Fallback strip auto-composite note: ' . $e->getMessage());
        }
    }

    return view('download_softfile', [
        'sessionId' => $sessionId,
        'photos' => $photos
    ]);
});

// Stream Foto Strip Komposit langsung ke <img> (Bebas dari masalah Symlink Hosting)
Route::get('/download/{sessionId}/view-strip', function ($sessionId) {
    $candidates = [
        storage_path('app/public/photos/strip_' . $sessionId . '.png'),
        storage_path('app/public/photos/strip_' . $sessionId . '.jpg'),
        storage_path('app/public/photos/strip_' . $sessionId . '.jpeg'),
        storage_path('app/photos/strip_' . $sessionId . '.png'),
        storage_path('app/photos/strip_' . $sessionId . '.jpg'),
    ];

    try {
        $photo = Photo::where('session_id', $sessionId)->where('sequence_number', 0)->first();
        if ($photo) {
            array_unshift($candidates, storage_path('app/public/' . $photo->file_path));
        }
    } catch (\Throwable $e) {}

    foreach ($candidates as $file) {
        if (file_exists($file)) {
            $isPng = str_ends_with(strtolower($file), '.png');
            return response()->file($file, [
                'Content-Type' => $isPng ? 'image/png' : 'image/jpeg',
                'Cache-Control' => 'public, max-age=86400',
            ]);
        }
    }

    abort(404, 'Foto strip belum ditemukan di server');
});

// Stream Pose Foto langsung ke <img> (Bebas dari masalah Symlink Hosting)
Route::get('/download/{sessionId}/view-photo/{photoId}', function ($sessionId, $photoId) {
    $targetFile = null;

    try {
        $photo = Photo::where('session_id', $sessionId)->where('id', $photoId)->first();
        if (!$photo) {
            $photo = Photo::find($photoId);
        }
        if ($photo) {
            $targetFile = storage_path('app/public/' . $photo->file_path);
        }
    } catch (\Throwable $e) {}

    // Fallback scan disk jika ID berupa hash
    if (!$targetFile || !file_exists($targetFile)) {
        $files = Storage::disk('public')->files('photos');
        foreach ($files as $file) {
            if (md5($file) === (string)$photoId || str_contains($file, (string)$photoId)) {
                $targetFile = storage_path('app/public/' . $file);
                break;
            }
        }
    }

    if ($targetFile && file_exists($targetFile)) {
        return response()->file($targetFile, [
            'Content-Type' => 'image/jpeg',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    abort(404, 'File foto tidak ditemukan');
});

// Unduh Foto Strip Komposit + Frame (sequence_number = 0)
Route::get('/download/{sessionId}/strip', function ($sessionId) {
    $candidates = [
        storage_path('app/public/photos/strip_' . $sessionId . '.png'),
        storage_path('app/public/photos/strip_' . $sessionId . '.jpg'),
        storage_path('app/public/photos/strip_' . $sessionId . '.jpeg'),
        storage_path('app/photos/strip_' . $sessionId . '.png'),
        storage_path('app/photos/strip_' . $sessionId . '.jpg'),
    ];

    try {
        $photo = Photo::where('session_id', $sessionId)->where('sequence_number', 0)->first();
        if ($photo) {
            array_unshift($candidates, storage_path('app/public/' . $photo->file_path));
        }
    } catch (\Throwable $e) {}

    foreach ($candidates as $filePath) {
        if (file_exists($filePath)) {
            $ext = pathinfo($filePath, PATHINFO_EXTENSION);
            $downloadName = 'Memontra-PhotoStrip-' . substr($sessionId, 0, 8) . '.' . $ext;
            return response()->download($filePath, $downloadName);
        }
    }

    abort(404, 'Hasil foto strip + frame belum tersedia untuk sesi ini.');
});

// Unduh satu foto satuan (Pose #1, #2, dst.)
Route::get('/download/{sessionId}/photo/{photoId}', function ($sessionId, $photoId) {
    $filePath = null;
    $seq = 1;

    try {
        $photo = Photo::where('session_id', $sessionId)->where('id', $photoId)->first();
        if ($photo) {
            $filePath = storage_path('app/public/' . $photo->file_path);
            $seq = $photo->sequence_number;
        }
    } catch (\Throwable $e) {}

    if (!$filePath || !file_exists($filePath)) {
        $files = Storage::disk('public')->files('photos');
        foreach ($files as $file) {
            if (md5($file) === (string)$photoId || str_contains($file, (string)$photoId)) {
                $filePath = storage_path('app/public/' . $file);
                preg_match('/_pose_(\d+)_/', $file, $matches);
                $seq = isset($matches[1]) ? (int)$matches[1] : 1;
                break;
            }
        }
    }

    if ($filePath && file_exists($filePath)) {
        $downloadName = 'Memontra-Pose-' . $seq . '.jpg';
        return response()->download($filePath, $downloadName);
    }

    abort(404, 'File foto tidak ditemukan di server.');
});

// Unduh SEMUA foto dan frame dalam 1 file ZIP
Route::get('/download/{sessionId}/zip', function ($sessionId) {
    $zip = new \ZipArchive();
    $zipFileName = 'Memontra-Sesi-' . substr($sessionId, 0, 8) . '.zip';
    $tempDir = storage_path('app/public/photos');
    if (!file_exists($tempDir)) {
        @mkdir($tempDir, 0775, true);
    }
    $zipPath = $tempDir . '/' . $zipFileName;

    if ($zip->open($zipPath, \ZipArchive::CREATE | \ZipArchive::OVERWRITE) === true) {
        // 1. Coba masukkan strip
        $stripCandidates = [
            storage_path('app/public/photos/strip_' . $sessionId . '.png'),
            storage_path('app/public/photos/strip_' . $sessionId . '.jpg'),
        ];
        foreach ($stripCandidates as $stripFile) {
            if (file_exists($stripFile)) {
                $ext = pathinfo($stripFile, PATHINFO_EXTENSION);
                $zip->addFile($stripFile, 'Memontra-FotoStrip-Frame.' . $ext);
                break;
            }
        }

        // 2. Masukkan foto-foto pose sesi ini
        $files = Storage::disk('public')->files('photos');
        foreach ($files as $file) {
            if (str_contains($file, $sessionId) && !str_contains($file, 'strip_')) {
                preg_match('/_pose_(\d+)_/', $file, $matches);
                $seq = isset($matches[1]) ? $matches[1] : rand(1, 9);
                $fullPath = storage_path('app/public/' . $file);
                if (file_exists($fullPath)) {
                    $zip->addFile($fullPath, 'Memontra-Pose-' . $seq . '.jpg');
                }
            }
        }
        $zip->close();
    }

    if (file_exists($zipPath)) {
        return response()->download($zipPath, $zipFileName)->deleteFileAfterSend(true);
    }

    abort(404, 'Belum ada foto yang tersedia untuk diunduh.');
});

// Unduh Animasi GIF Boomerang
Route::get('/download/{sessionId}/gif', function ($sessionId) {
    $gifFile = storage_path('app/public/photos/gif_' . $sessionId . '.gif');
    if (file_exists($gifFile)) {
        return response()->download($gifFile, 'Memontra-Boomerang-' . substr($sessionId, 0, 8) . '.gif');
    }
    // Arahkan ke galeri untuk memutar & mengunduh animasi GIF nyata via web
    return redirect('/download/' . $sessionId . '#gifPlayer');
});

if (file_exists(__DIR__ . '/auth.php') && class_exists(\App\Http\Controllers\Auth\AuthenticatedSessionController::class)) {
    require __DIR__ . '/auth.php';
}
