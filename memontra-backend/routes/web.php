<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\GoogleController;
use App\Models\Session;
use App\Models\Photo;
use Illuminate\Support\Facades\Storage;

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

// Halaman utama download softfile foto untuk customer booth
Route::get('/download/{sessionId}', function ($sessionId) {
    $session = Session::with('photos')->find($sessionId);
    $photos = $session ? $session->photos->sortBy('sequence_number') : collect([]);

    return view('download_softfile', [
        'sessionId' => $sessionId,
        'session' => $session,
        'photos' => $photos
    ]);
});

// Unduh Foto Strip Komposit + Frame (sequence_number = 0)
Route::get('/download/{sessionId}/strip', function ($sessionId) {
    $photo = Photo::where('session_id', $sessionId)->where('sequence_number', 0)->first();

    if (!$photo) {
        abort(404, 'Hasil foto strip + frame belum tersedia untuk sesi ini.');
    }

    $filePath = storage_path('app/public/' . $photo->file_path);
    if (!file_exists($filePath)) {
        abort(404, 'File foto strip tidak ditemukan di server.');
    }

    $downloadName = 'Memontra-PhotoStrip-' . substr($sessionId, 0, 8) . '.png';
    return response()->download($filePath, $downloadName);
});

// Unduh satu foto satuan (Pose #1, #2, dst.)
Route::get('/download/{sessionId}/photo/{photoId}', function ($sessionId, $photoId) {
    $photo = Photo::where('session_id', $sessionId)->where('id', $photoId)->firstOrFail();
    $filePath = storage_path('app/public/' . $photo->file_path);

    if (!file_exists($filePath)) {
        abort(404, 'File foto tidak ditemukan di server.');
    }

    $downloadName = 'Memontra-Pose-' . $photo->sequence_number . '.jpg';
    return response()->download($filePath, $downloadName);
});

// Unduh SEMUA foto dan frame dalam 1 file ZIP
Route::get('/download/{sessionId}/zip', function ($sessionId) {
    $session = Session::with('photos')->findOrFail($sessionId);
    $photos = $session->photos->sortBy('sequence_number');

    if ($photos->isEmpty()) {
        abort(404, 'Belum ada foto yang diunggah untuk sesi ini.');
    }

    $zip = new \ZipArchive();
    $zipFileName = 'Memontra-Sesi-' . substr($sessionId, 0, 8) . '.zip';
    $tempDir = storage_path('app/public/photos');
    if (!file_exists($tempDir)) {
        mkdir($tempDir, 0775, true);
    }
    $zipPath = $tempDir . '/' . $zipFileName;

    if ($zip->open($zipPath, \ZipArchive::CREATE | \ZipArchive::OVERWRITE) === true) {
        // 1. Tambahkan hasil foto strip + frame komposit jika ada
        $stripPhoto = $photos->firstWhere('sequence_number', 0);
        if ($stripPhoto) {
            $stripPath = storage_path('app/public/' . $stripPhoto->file_path);
            if (file_exists($stripPath)) {
                $zip->addFile($stripPath, 'Memontra-FotoStrip-Frame.png');
            }
        }

        // 2. Tambahkan jepretan pose-pose foto satuan
        foreach ($photos->where('sequence_number', '>', 0) as $photo) {
            $filePath = storage_path('app/public/' . $photo->file_path);
            if (file_exists($filePath)) {
                $zip->addFile($filePath, 'Memontra-Pose-' . $photo->sequence_number . '.jpg');
            }
        }
        $zip->close();
    }

    return response()->download($zipPath, $zipFileName)->deleteFileAfterSend(true);
});

// Unduh Animasi GIF Boomerang
Route::get('/download/{sessionId}/gif', function ($sessionId) {
    $session = Session::with('photos')->findOrFail($sessionId);
    $photos = $session->photos->where('sequence_number', '>', 0)->sortBy('sequence_number');

    if ($photos->isEmpty()) {
        return redirect('/download/' . $sessionId . '/zip');
    }

    if (extension_loaded('imagick')) {
        try {
            $imagick = new \Imagick();
            $imagick->setFormat("gif");

            foreach ($photos as $photo) {
                $filePath = storage_path('app/public/' . $photo->file_path);
                if (file_exists($filePath)) {
                    $frame = new \Imagick($filePath);
                    $frame->resizeImage(600, 0, \Imagick::FILTER_LANCZOS, 1);
                    $frame->setImageDelay(50); // 500ms per pose
                    $imagick->addImage($frame);
                }
            }

            return response($imagick->getImagesBlob())
                ->header('Content-Type', 'image/gif')
                ->header('Content-Disposition', 'attachment; filename="Memontra-Animasi-' . substr($sessionId, 0, 8) . '.gif"');
        } catch (\Exception $e) {
            // fallback
        }
    }

    return redirect('/download/' . $sessionId . '/zip');
});

require __DIR__ . '/auth.php';
