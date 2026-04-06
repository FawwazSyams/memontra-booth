<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Booking;

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

        // 2. Simpan ke database, otomatis dikaitkan dengan user yang sedang login
        $booking = $request->user()->bookings()->create($validated);

        // 3. Kembalikan respons sukses ke React
        return response()->json([
            'message' => 'Booking berhasil dibuat!',
            'booking' => $booking
        ], 201);
    }
}
