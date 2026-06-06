<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BookingController;

use App\Http\Controllers\PaymentCallbackController;

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::post('/bookings', [BookingController::class, 'store']);
});

// Midtrans Webhook Callback (Public route)
Route::post('/payment/callback', [PaymentCallbackController::class, 'callback']);
