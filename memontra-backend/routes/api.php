<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\BoothController;
use App\Http\Controllers\Api\PaymentController;

// 1. Rute Otentikasi & Booking Pengguna (Web Landing Page - Jika Controller ada)
if (class_exists(\App\Http\Controllers\BookingController::class)) {
    Route::middleware(['auth:sanctum'])->group(function () {
        Route::get('/user', function (Request $request) {
            return $request->user();
        });

        Route::get('/bookings', [\App\Http\Controllers\BookingController::class, 'index']);
        Route::get('/my-bookings', [\App\Http\Controllers\BookingController::class, 'userBookings']);
        Route::get('/users', function () {
            return response()->json(\App\Models\User::orderBy('created_at', 'desc')->get());
        });
        Route::post('/bookings', [\App\Http\Controllers\BookingController::class, 'store']);
        Route::put('/bookings/{id}/pay', [\App\Http\Controllers\BookingController::class, 'updatePaymentStatus']);
    });

    Route::put('/bookings/{id}/pay-public', [\App\Http\Controllers\BookingController::class, 'updatePaymentStatus']);
}

// 2. Rute Photobooth Kiosk (Aplikasi Windows & Standalone)
Route::prefix('booth')->group(function () {
    Route::get('/event/active', [BoothController::class, 'getActiveEvent']);
    Route::post('/sessions', [BoothController::class, 'startSession']);
    Route::post('/sessions/{sessionId}/photos', [BoothController::class, 'uploadPhoto']);
    Route::post('/sessions/{sessionId}/strip', [BoothController::class, 'uploadStrip']);
});

// 3. Rute Gateway Pembayaran DOKU (Kiosk & Web)
Route::prefix('payment')->group(function () {
    Route::post('/qris', [PaymentController::class, 'generateQris']);
    Route::get('/status/{orderId}', [PaymentController::class, 'checkStatus']);

    if (class_exists(\App\Http\Controllers\PaymentCallbackController::class)) {
        Route::post('/callback', [\App\Http\Controllers\PaymentCallbackController::class, 'callback']);
        Route::post('/doku/callback', [\App\Http\Controllers\PaymentCallbackController::class, 'callback']);
    }
});

// 4. Rute Diagnostik Server & Health Check (Selalu siap diakses via Nginx)
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'time' => now()->toIso8601String(),
        'php_version' => PHP_VERSION,
        'app' => config('app.name'),
        'version' => '2.0.0',
    ]);
});

Route::get('/debug-log', function () {
    $logFile = storage_path('logs/laravel.log');
    if (file_exists($logFile)) {
        $lines = file($logFile);
        return response('<pre>' . htmlspecialchars(implode("", array_slice($lines, -100))) . '</pre>');
    }
    return response('Log file tidak ditemukan di: ' . $logFile, 200);
});
