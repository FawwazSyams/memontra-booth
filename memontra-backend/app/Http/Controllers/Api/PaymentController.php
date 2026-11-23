<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use App\Services\DokuService;
use Illuminate\Support\Facades\Cache;
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
            $tokenId = $result['token_id'] ?? null;
            if ($tokenId) {
                Cache::put("doku_token_{$orderId}", $tokenId, now()->addMinutes(30));
            }

            return response()->json([
                'status' => 'success',
                'gateway' => 'doku',
                'order_id' => $orderId,
                'token_id' => $tokenId,
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
    public function checkStatus(Request $request, $orderId)
    {
        // 1. Cek dari Cache (diset oleh webhook callback DOKU saat pembayaran sukses)
        $cachedStatus = Cache::get("payment_status_{$orderId}");
        if ($cachedStatus) {
            return response()->json([
                'gateway' => 'doku',
                'order_id' => $orderId,
                'transaction_status' => $cachedStatus,
            ], 200);
        }

        // 2. Query status ke API DOKU (bisa via token_id atau invoice_number)
        $tokenId = $request->query('token_id') ?? Cache::get("doku_token_{$orderId}");
        $dokuStatus = $this->dokuService->checkTransactionStatus($orderId, $tokenId);

        if ($dokuStatus) {
            $normalizedStatus = in_array(strtoupper($dokuStatus), ['SUCCESS', 'SETTLEMENT', 'PAID'])
                ? 'settlement'
                : strtolower($dokuStatus);

            if ($normalizedStatus === 'settlement') {
                Cache::put("payment_status_{$orderId}", 'settlement', now()->addHours(2));
            }

            return response()->json([
                'gateway' => 'doku',
                'order_id' => $orderId,
                'transaction_status' => $normalizedStatus,
            ], 200);
        }

        return response()->json([
            'gateway' => 'doku',
            'order_id' => $orderId,
            'transaction_status' => 'pending',
        ], 200);
    }
}
