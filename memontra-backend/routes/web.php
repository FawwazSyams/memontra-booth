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
Route::get('/auth/google', [GoogleController::class, 'redirect']);
Route::get('/auth/google/callback', [GoogleController::class, 'callback']);

// =========================================================================
// SOFTFILE DOWNLOAD ROUTES (HASIL FOTO + FRAME UNTUK CUSTOMER)
// =========================================================================

// Halaman utama galeri softfile foto untuk customer booth
Route::get('/download/{sessionId}', function ($sessionId) {
    $photos = collect([]);

    // 1. Coba ambil dari database jika database aktif
    try {
        $session = Session::with('photos')->find($sessionId);
        if ($session && $session->photos) {
            $photos = $session->photos->sortBy('sequence_number');
        }
    } catch (\Throwable $e) {
        Log::warning('DB error in /download route: ' . $e->getMessage());
    }

    // 2. Fallback cerdas: Jika belum ada di database, cari file foto langsung dari storage disk
    if ($photos->isEmpty()) {
        $diskPhotos = collect([]);

        // Cek file strip komposit
        $stripPath = 'photos/strip_' . $sessionId . '.png';
        if (Storage::disk('public')->exists($stripPath)) {
            $diskPhotos->push((object)[
                'id' => 'strip',
                'session_id' => $sessionId,
                'file_path' => $stripPath,
                'sequence_number' => 0,
            ]);
        }

        // Cek file-file pose foto di disk
        $files = Storage::disk('public')->files('photos');
        foreach ($files as $file) {
            if (str_contains($file, $sessionId) && !str_contains($file, 'strip_')) {
                // Ekstrak sequence number dari nama file jika ada
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

        if ($diskPhotos->isNotEmpty()) {
            $photos = $diskPhotos->sortBy('sequence_number');
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
        storage_path('app/photos/strip_' . $sessionId . '.png'),
    ];

    try {
        $photo = Photo::where('session_id', $sessionId)->where('sequence_number', 0)->first();
        if ($photo) {
            array_unshift($candidates, storage_path('app/public/' . $photo->file_path));
        }
    } catch (\Throwable $e) {}

    foreach ($candidates as $file) {
        if (file_exists($file)) {
            return response()->file($file, [
                'Content-Type' => 'image/png',
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
        storage_path('app/photos/strip_' . $sessionId . '.png'),
    ];

    try {
        $photo = Photo::where('session_id', $sessionId)->where('sequence_number', 0)->first();
        if ($photo) {
            array_unshift($candidates, storage_path('app/public/' . $photo->file_path));
        }
    } catch (\Throwable $e) {}

    foreach ($candidates as $filePath) {
        if (file_exists($filePath)) {
            $downloadName = 'Memontra-PhotoStrip-' . substr($sessionId, 0, 8) . '.png';
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
        $stripFile = storage_path('app/public/photos/strip_' . $sessionId . '.png');
        if (file_exists($stripFile)) {
            $zip->addFile($stripFile, 'Memontra-FotoStrip-Frame.png');
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
    return redirect('/download/' . $sessionId . '/zip');
});

require __DIR__ . '/auth.php';
