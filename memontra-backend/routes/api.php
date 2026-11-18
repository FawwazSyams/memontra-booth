<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\PaymentCallbackController;
use App\Http\Controllers\Api\BoothController;
use App\Http\Controllers\Api\PaymentController;

// 1. Rute Otentikasi & Booking Pengguna (Web Landing Page)
Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::get('/bookings', [BookingController::class, 'index']);
    Route::get('/my-bookings', [BookingController::class, 'userBookings']);
    Route::get('/users', function () {
        return response()->json(\App\Models\User::orderBy('created_at', 'desc')->get());
    });
    Route::post('/bookings', [BookingController::class, 'store']);
    Route::put('/bookings/{id}/pay', [BookingController::class, 'updatePaymentStatus']);
});

// Rute update pembayaran manual / simulasi untuk localhost & dev
Route::put('/bookings/{id}/pay-public', [BookingController::class, 'updatePaymentStatus']);

// 2. Rute Photobooth Kiosk (Aplikasi Windows)
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
    Route::post('/callback', [PaymentCallbackController::class, 'callback']);
    Route::post('/doku/callback', [PaymentCallbackController::class, 'callback']);
});
