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
     * Simpan token DOKU dengan multi-tier fallback (Cache file + Disk file)
     * Dijamin tidak pernah crash 500 walau database cache tidak terhubung
     */
    public static function storeToken(string $orderId, string $tokenId): void
    {
        try {
            Cache::put("doku_token_{$orderId}", $tokenId, now()->addMinutes(30));
        } catch (\Throwable $e) {
            Log::warning("Cache put doku_token note: " . $e->getMessage());
        }

        try {
            $dir = storage_path('app/doku_tokens');
            if (!is_dir($dir)) {
                @mkdir($dir, 0775, true);
            }
            @file_put_contents("{$dir}/{$orderId}.txt", $tokenId);
        } catch (\Throwable $e) {}
    }

    /**
     * Ambil token DOKU dari Cache atau fallback Disk file
     */
    public static function getToken(string $orderId): ?string
    {
        try {
            $token = Cache::get("doku_token_{$orderId}");
            if ($token) {
                return $token;
            }
        } catch (\Throwable $e) {}

        try {
            $file = storage_path("app/doku_tokens/{$orderId}.txt");
            if (file_exists($file)) {
                return trim(@file_get_contents($file));
            }
        } catch (\Throwable $e) {}

        return null;
    }

    /**
     * Simpan status pembayaran dengan multi-tier fallback
     */
    public static function storeStatus(string $orderId, string $status): void
    {
        try {
            Cache::put("payment_status_{$orderId}", $status, now()->addHours(2));
        } catch (\Throwable $e) {
            Log::warning("Cache put payment_status note: " . $e->getMessage());
        }

        try {
            $dir = storage_path('app/doku_status');
            if (!is_dir($dir)) {
                @mkdir($dir, 0775, true);
            }
            @file_put_contents("{$dir}/{$orderId}.txt", $status);
        } catch (\Throwable $e) {}
    }

    /**
     * Ambil status pembayaran dari Cache atau fallback Disk file
     */
    public static function getStatus(string $orderId): ?string
    {
        try {
            $status = Cache::get("payment_status_{$orderId}");
            if ($status) {
                return $status;
            }
        } catch (\Throwable $e) {}

        try {
            $file = storage_path("app/doku_status/{$orderId}.txt");
            if (file_exists($file)) {
                return trim(@file_get_contents($file));
            }
        } catch (\Throwable $e) {}

        return null;
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
                self::storeToken($orderId, $tokenId);
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
        // 1. Cek dari Cache / file disk (diset oleh webhook callback DOKU)
        $cachedStatus = self::getStatus($orderId);
        if ($cachedStatus) {
            return response()->json([
                'gateway' => 'doku',
                'order_id' => $orderId,
                'transaction_status' => $cachedStatus,
            ], 200);
        }

        // 2. Query status ke API DOKU (bisa via token_id atau invoice_number)
        $tokenId = $request->query('token_id') ?? self::getToken($orderId);
        $dokuStatus = $this->dokuService->checkTransactionStatus($orderId, $tokenId);

        if ($dokuStatus) {
            $normalizedStatus = in_array(strtoupper($dokuStatus), ['SUCCESS', 'SETTLEMENT', 'PAID'])
                ? 'settlement'
                : strtolower($dokuStatus);

            if ($normalizedStatus === 'settlement') {
                self::storeStatus($orderId, 'settlement');
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
