<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Booking;
use Midtrans\Notification;
use Midtrans\Config;

class PaymentCallbackController extends Controller
{
    public function callback(Request $request)
    {
        // 1. Konfigurasi Midtrans
        Config::$serverKey = env('MIDTRANS_SERVER_KEY');
        Config::$isProduction = false;
        
        try {
            // 2. Inisiasi instance Notification
            $notification = new Notification();
            
            $transactionStatus = $notification->transaction_status;
            $paymentType = $notification->payment_type;
            $orderId = $notification->order_id;
            $fraudStatus = $notification->fraud_status;

            // Extract Booking ID from INV-MB-{id}-{timestamp}
            $orderIdParts = explode('-', $orderId);
            $bookingId = $orderIdParts[2]; // Index 2 is the ID

            // 3. Cari Booking yang sesuai
            $booking = Booking::find($bookingId);
            
            if (!$booking) {
                return response()->json(['message' => 'Booking not found'], 404);
            }

            // 4. Update Status Pembayaran berdasarkan respon Midtrans
            if ($transactionStatus == 'capture') {
                if ($paymentType == 'credit_card') {
                    if ($fraudStatus == 'challenge') {
                        $booking->payment_status = 'pending';
                    } else {
                        $booking->payment_status = 'paid';
                    }
                }
            } else if ($transactionStatus == 'settlement') {
                $booking->payment_status = 'paid';
            } else if ($transactionStatus == 'pending') {
                $booking->payment_status = 'pending';
            } else if ($transactionStatus == 'deny') {
                $booking->payment_status = 'failed';
            } else if ($transactionStatus == 'expire') {
                $booking->payment_status = 'expired';
            } else if ($transactionStatus == 'cancel') {
                $booking->payment_status = 'failed';
            }

            // Simpan perubahan ke database
            $booking->save();

            return response()->json(['message' => 'Callback handled successfully']);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to process callback',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
