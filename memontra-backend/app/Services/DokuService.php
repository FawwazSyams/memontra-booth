<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class DokuService
{
    protected string $clientId;
    protected string $secretKey;
    protected bool $isProduction;
    protected string $baseUrl;

    public function __construct()
    {
        $this->clientId = env('DOKU_CLIENT_ID', 'BRN-0222-1794325816935');
        $this->secretKey = env('DOKU_SECRET_KEY', 'SK-17qzdFuXy8Wg6iR7OgWM');
        $this->isProduction = (bool) env('DOKU_IS_PRODUCTION', true);

        $this->baseUrl = $this->isProduction
            ? 'https://api.doku.com'
            : 'https://api-sandbox.doku.com';
    }

    /**
     * Generate Header Signature untuk Request ke DOKU (Jokul Checkout)
     */
    protected function generateHeaders(string $targetPath, array $body): array
    {
        $requestId = (string) Str::uuid();
        $timestamp = gmdate('Y-m-d\TH:i:s\Z');
        $bodyJson = json_encode($body, JSON_UNESCAPED_SLASHES);

        // 1. Hitung Digest (Base64 dari SHA-256 raw JSON body)
        $digest = base64_encode(hash('sha256', $bodyJson, true));

        // 2. Susun Component String sesuai spesifikasi DOKU
        $component = "Client-Id:" . $this->clientId . "\n"
            . "Request-Id:" . $requestId . "\n"
            . "Request-Timestamp:" . $timestamp . "\n"
            . "Request-Target:" . $targetPath . "\n"
            . "Digest:" . $digest;

        // 3. Hitung Signature HMAC-SHA256
        $signature = 'HMACSHA256=' . base64_encode(hash_hmac('sha256', $component, $this->secretKey, true));

        return [
            'Client-Id' => $this->clientId,
            'Request-Id' => $requestId,
            'Request-Timestamp' => $timestamp,
            'Signature' => $signature,
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
        ];
    }

    /**
     * Buat Transaksi DOKU Checkout (Untuk Pemesanan Paket di Website)
     */
    public function createCheckout(
        string $orderId,
        int $amount,
        string $customerName,
        string $customerEmail,
        ?string $callbackUrl = null
    ): array {
        $targetPath = '/checkout/v1/payment';
        $frontendUrl = env('FRONTEND_URL', 'https://momentrabooth.com');

        $payload = [
            'order' => [
                'invoice_number' => $orderId,
                'amount' => $amount,
                'callback_url' => $callbackUrl ?? "$frontendUrl/riwayat-booking?status=success&order_id=$orderId",
                'auto_redirect' => true,
            ],
            'payment' => [
                'payment_due_date' => 60, // 60 menit masa berlaku pembayaran
            ],
            'customer' => [
                'name' => $customerName,
                'email' => $customerEmail,
            ],
        ];

        // Jika kredensial masih demo/sandbox placeholder, buat link simulasi aman
        if (str_contains($this->clientId, 'DEMO') || empty($this->secretKey)) {
            Log::info('DOKU Mock Checkout generated for:', ['order_id' => $orderId, 'amount' => $amount]);
            return [
                'status' => 'success',
                'gateway' => 'doku',
                'order_id' => $orderId,
                'payment_url' => "https://sandbox.doku.com/checkout/link/simulasi-$orderId",
                'is_mock' => true,
            ];
        }

        try {
            $headers = $this->generateHeaders($targetPath, $payload);
            $response = Http::withHeaders($headers)
                ->timeout(15)
                ->post($this->baseUrl . $targetPath, $payload);

            if ($response->successful()) {
                $data = $response->json();
                $paymentUrl = $data['response']['payment']['url'] ?? null;

                return [
                    'status' => 'success',
                    'gateway' => 'doku',
                    'order_id' => $orderId,
                    'payment_url' => $paymentUrl,
                    'raw_response' => $data,
                ];
            }

            Log::error('DOKU Checkout API Error:', [
                'status' => $response->status(),
                'body' => $response->body()
            ]);

            return [
                'status' => 'error',
                'message' => $response->json('message') ?? 'Gagal menghubungi DOKU payment gateway',
                'error' => $response->body(),
            ];

        } catch (\Exception $e) {
            Log::error('DOKU Exception: ' . $e->getMessage());
            return [
                'status' => 'error',
                'message' => $e->getMessage(),
            ];
        }
    }

    /**
     * Buat Transaksi QRIS DOKU (Untuk Photobooth Kiosk Windows)
     */
    public function createQris(string $orderId, int $amount): array
    {
        $targetPath = '/checkout/v1/payment';

        $payload = [
            'order' => [
                'invoice_number' => $orderId,
                'amount' => $amount,
                'callback_url' => env('APP_URL', 'https://momentrabooth.com') . '/api/payment/doku/callback',
                'auto_redirect' => true,
            ],
            'payment' => [
                'payment_due_date' => 15, // 15 menit masa berlaku QRIS stand
                'payment_method_types' => ['QRIS'],
            ],
            'customer' => [
                'name' => 'Pelanggan Booth',
                'email' => 'customer@memontrabooth.com',
            ],
        ];

        // Jika kredensial masih demo/sandbox placeholder, buat QRIS string simulasi yang valid
        if (str_contains($this->clientId, 'DEMO') || empty($this->secretKey)) {
            Log::info('DOKU Mock QRIS generated for order:', ['order_id' => $orderId, 'amount' => $amount]);
            $mockQrString = "00020101021226600016ID.CO.DOKU.WWW01189360099900000000010215{$orderId}5204581253033605405{$amount}5802ID5914MEMONTRA BOOTH6007JAKARTA62070703A016304";

            return [
                'status' => 'success',
                'gateway' => 'doku',
                'order_id' => $orderId,
                'qr_string' => $mockQrString,
                'qr_url' => "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=" . urlencode($mockQrString),
                'amount' => $amount,
                'is_mock' => true,
            ];
        }

        try {
            $headers = $this->generateHeaders($targetPath, $payload);
            $response = Http::withHeaders($headers)
                ->timeout(15)
                ->post($this->baseUrl . $targetPath, $payload);

            if ($response->successful()) {
                $data = $response->json();
                $paymentUrl = $data['response']['payment']['url'] ?? null;
                $qrString = $data['response']['payment']['qr_string'] ?? $paymentUrl;

                return [
                    'status' => 'success',
                    'gateway' => 'doku',
                    'order_id' => $orderId,
                    'qr_string' => $qrString,
                    'qr_url' => $paymentUrl,
                    'amount' => $amount,
                    'raw_response' => $data,
                ];
            }

            Log::error('DOKU QRIS API Error:', [
                'status' => $response->status(),
                'body' => $response->body()
            ]);

            return [
                'status' => 'error',
                'message' => $response->json('message') ?? 'Gagal membuat QRIS DOKU',
                'raw_error' => $response->body(),
            ];

        } catch (\Exception $e) {
            return [
                'status' => 'error',
                'message' => $e->getMessage(),
            ];
        }
    }

    /**
     * Cek status transaksi langsung ke API DOKU
     */
    public function checkTransactionStatus(string $orderId): ?string
    {
        $targetPath = '/orders/v1/status/' . $orderId;

        try {
            $headers = $this->generateHeaders($targetPath, []);
            $response = Http::withHeaders($headers)
                ->timeout(10)
                ->get($this->baseUrl . $targetPath);

            if ($response->successful()) {
                $data = $response->json();
                return $data['transaction']['status']
                    ?? $data['response']['transaction']['status']
                    ?? $data['status']
                    ?? null;
            }
        } catch (\Exception $e) {
            Log::warning('DOKU checkTransactionStatus exception: ' . $e->getMessage());
        }

        return null;
    }

    /**
     * Verifikasi Signature Webhook Notification dari DOKU
     */
    public function verifyWebhookSignature(array $headers, string $rawBody, string $targetPath = '/api/payment/callback'): bool
    {
        $clientId = $headers['Client-Id'] ?? $headers['client-id'] ?? '';
        $requestId = $headers['Request-Id'] ?? $headers['request-id'] ?? '';
        $timestamp = $headers['Request-Timestamp'] ?? $headers['request-timestamp'] ?? '';
        $incomingSignature = $headers['Signature'] ?? $headers['signature'] ?? '';

        if (empty($incomingSignature) || empty($timestamp)) {
            return false;
        }

        $digest = base64_encode(hash('sha256', $rawBody, true));
        $component = "Client-Id:" . $clientId . "\n"
            . "Request-Id:" . $requestId . "\n"
            . "Request-Timestamp:" . $timestamp . "\n"
            . "Request-Target:" . $targetPath . "\n"
            . "Digest:" . $digest;

        $expectedSignature = 'HMACSHA256=' . base64_encode(hash_hmac('sha256', $component, $this->secretKey, true));

        return hash_equals($expectedSignature, $incomingSignature);
    }
}
