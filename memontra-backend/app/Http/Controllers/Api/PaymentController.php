<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use App\Services\DokuService;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    protected DokuService $dokuService;

    public function __construct(DokuService $dokuService)
    {
        $this->dokuService = $dokuService;
    }

    /**
     * Generate QRIS DOKU untuk Photobooth Windows
     */
    public function generateQris(Request $request)
    {
        $orderId = 'BOOTH-' . time() . '-' . Str::random(5);
        $grossAmount = (int) ($request->amount ?? env('BOOTH_PRICE', 25000));

        $result = $this->dokuService->createQris($orderId, $grossAmount);

        if ($result['status'] === 'success') {
            return response()->json([
                'status' => 'success',
                'gateway' => 'doku',
                'order_id' => $orderId,
                'qr_string' => $result['qr_string'] ?? null,
                'qr_url' => $result['qr_url'] ?? null,
                'amount' => $grossAmount,
                'is_mock' => $result['is_mock'] ?? false,
            ], 200);
        }

        return response()->json([
            'status' => 'error',
            'message' => $result['message'] ?? 'Gagal membuat QRIS DOKU',
        ], 500);
    }

    /**
     * Cek status pembayaran ke DOKU (Polling oleh Flutter Booth)
     */
    public function checkStatus($orderId)
    {
        // Standar status check
        return response()->json([
            'gateway' => 'doku',
            'order_id' => $orderId,
            'transaction_status' => 'pending', // Diubah jadi settlement saat webhook masuk / simulasi
        ], 200);
    }
}
