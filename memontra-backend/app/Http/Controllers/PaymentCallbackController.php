<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Booking;
use App\Services\DokuService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class PaymentCallbackController extends Controller
{
    protected DokuService $dokuService;

    public function __construct(DokuService $dokuService)
    {
        $this->dokuService = $dokuService;
    }

    /**
     * Webhook Callback Utama DOKU Payment Gateway
     */
    public function callback(Request $request)
    {
        Log::info('DOKU Webhook Received:', [
            'headers' => $request->headers->all(),
            'body' => $request->all()
        ]);

        try {
            // Ambil detail transaksi dari DOKU
            $orderId = $request->input('order.invoice_number')
                ?? $request->input('invoice_number')
                ?? $request->input('order_id')
                ?? $request->input('order.id');

            $status = $request->input('transaction.status')
                ?? $request->input('status')
                ?? $request->input('transaction_status')
                ?? 'SUCCESS';

            if (!$orderId) {
                return response()->json(['message' => 'Invoice number / Order ID not found'], 400);
            }

            // Simpan status pembayaran ke Cache agar booth kiosk Windows langsung mendeteksi pembayaran realtime
            if (in_array(strtoupper($status), ['SUCCESS', 'SETTLEMENT', 'PAID'])) {
                Cache::put("payment_status_{$orderId}", 'settlement', now()->addHours(2));
                Log::info("Transaction #$orderId marked as SETTLEMENT in Cache");
            }

            // Jika transaksi untuk Booking Website (format: INV-MB-{id}-{timestamp})
            if (str_starts_with($orderId, 'INV-MB-')) {
                $orderIdParts = explode('-', $orderId);
                $bookingId = $orderIdParts[2] ?? null;

                if ($bookingId) {
                    $booking = Booking::find($bookingId);
                    if ($booking) {
                        if (strtoupper($status) === 'SUCCESS' || strtolower($status) === 'settlement') {
                            $booking->update(['payment_status' => 'paid']);
                            Log::info("Booking #$bookingId payment status updated to PAID via DOKU");
                        } elseif (in_array(strtolower($status), ['failed', 'cancel', 'expire', 'expired'])) {
                            $booking->update(['payment_status' => 'failed']);
                        }
                    }
                }
            }

            // Respons standar DOKU acknowledgement
            return response()->json([
                'status' => 'OK',
                'message' => 'Notification processed successfully'
            ], 200);

        } catch (\Exception $e) {
            Log::error('Error processing DOKU webhook: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to process callback',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
