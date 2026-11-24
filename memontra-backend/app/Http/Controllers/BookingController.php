<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Booking;
use App\Services\DokuService;
use Illuminate\Support\Facades\Log;

class BookingController extends Controller
{
    protected DokuService $dokuService;

    public function __construct(DokuService $dokuService)
    {
        $this->dokuService = $dokuService;
    }

    public function index()
    {
        // Untuk admin, ambil semua booking
        $bookings = Booking::with('user')->orderBy('created_at', 'desc')->get();
        return response()->json($bookings);
    }

    public function userBookings(Request $request)
    {
        // Untuk user, ambil booking miliknya sendiri
        $bookings = $request->user()->bookings()->orderBy('created_at', 'desc')->get();
        return response()->json($bookings);
    }

    public function updatePaymentStatus(Request $request, $id)
    {
        $booking = Booking::findOrFail($id);
        
        try {
            $booking->update(['payment_status' => 'paid']);
            return response()->json([
                'message' => 'Status pembayaran berhasil diperbarui menjadi paid',
                'booking' => $booking
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal update status', 'error' => $e->getMessage()], 500);
        }
    }

    public function store(Request $request)
    {
        Log::info('Incoming booking:', $request->all());

        // Verifikasi Email Check: Wajib verifikasi email sebelum bisa booking
        if (!$request->user()->hasVerifiedEmail()) {
            return response()->json([
                'message' => 'Silakan verifikasi email Anda terlebih dahulu sebelum membuat pesanan booking. Cek inbox atau folder spam email Anda.',
                'must_verify_email' => true,
            ], 403);
        }

        // 1. Validasi data yang masuk
        $validated = $request->validate([
            'package' => 'required|string',
            'date' => 'required|date',
            'time' => 'required',
            'city' => 'required|string',
            'event_type' => 'required|string',
            'address' => 'required|string',
            'latitude' => 'nullable|string',
            'longitude' => 'nullable|string',
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

        // 3. Buat Pembayaran DOKU Checkout
        $orderId = 'INV-MB-' . $booking->id . '-' . time();
        $customerName = $request->user()->name ?? 'Pelanggan Memontra';
        $customerEmail = $request->user()->email ?? 'customer@memontrabooth.com';
        $callbackUrl = env('FRONTEND_URL', 'https://momentrabooth.com') . '/riwayat-booking?status=success&booking_id=' . $booking->id;

        $dokuResponse = $this->dokuService->createCheckout(
            $orderId,
            $booking->total_price,
            $customerName,
            $customerEmail,
            $callbackUrl
        );

        $paymentUrl = $dokuResponse['payment_url'] ?? null;

        // Simpan token / URL pembayaran ke database
        $booking->update([
            'snap_token' => $paymentUrl ?? $orderId,
        ]);

        return response()->json([
            'message' => 'Booking berhasil dibuat!',
            'gateway' => 'doku',
            'order_id' => $orderId,
            'payment_url' => $paymentUrl,
            'snap_token' => $paymentUrl ?? $orderId,
            'booking' => $booking,
        ], 201);
    }
}
