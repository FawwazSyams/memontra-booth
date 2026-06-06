<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Booking;

use Midtrans\Config;
use Midtrans\Snap;

class BookingController extends Controller
{
    public function store(Request $request)
    {
        // 1. Validasi data yang masuk
        $validated = $request->validate([
            'package' => 'required|string',
            'date' => 'required|date',
            'time' => 'required',
            'city' => 'required|string',
            'event_type' => 'required|string',
            'address' => 'required|string',
        ]);

        // Harga paket
        $price = 0;
        if ($validated['package'] === 'Silver') $price = 600000;
        else if ($validated['package'] === 'Gold') $price = 1000000;
        else if ($validated['package'] === 'Platinum') $price = 1500000;

        $validated['total_price'] = $price;
        $validated['payment_status'] = 'pending';

        // 2. Simpan ke database
        $booking = $request->user()->bookings()->create($validated);

        // 3. Konfigurasi Midtrans
        Config::$serverKey = env('MIDTRANS_SERVER_KEY', 'SB-Mid-server-YOUR_KEY_HERE'); 
        Config::$isProduction = false;
        Config::$isSanitized = true;
        Config::$is3ds = true;

        $params = [
            'transaction_details' => [
                'order_id' => 'INV-MB-' . $booking->id . '-' . time(),
                'gross_amount' => $booking->total_price,
            ],
            'customer_details' => [
                'first_name' => $request->user()->name,
                'email' => $request->user()->email,
            ],
            'item_details' => [
                [
                    'id' => 'PKG-' . strtoupper($booking->package),
                    'price' => $booking->total_price,
                    'quantity' => 1,
                    'name' => 'Memontra Booth - ' . $booking->package,
                ]
            ]
        ];

        try {
            // Generate Snap Token
            $snapToken = Snap::getSnapToken($params);
            
            // Simpan token ke database untuk riwayat
            $booking->update(['snap_token' => $snapToken]);

            // Kembalikan token ke React
            return response()->json([
                'message' => 'Booking berhasil dibuat!',
                'snap_token' => $snapToken,
                'booking' => $booking
            ], 201);
            
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal menyambung ke gateway pembayaran.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
