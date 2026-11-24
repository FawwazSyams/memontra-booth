<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class EmailVerificationNotificationController extends Controller
{
    /**
     * Send a new email verification notification.
     */
    public function store(Request $request): JsonResponse|RedirectResponse
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        if ($user->hasVerifiedEmail()) {
            return response()->json(['status' => 'already-verified', 'message' => 'Email Anda sudah terverifikasi']);
        }

        try {
            $user->sendEmailVerificationNotification();
            return response()->json([
                'status' => 'verification-link-sent',
                'message' => 'Tautan verifikasi baru berhasil dikirim ke email Anda.'
            ]);
        } catch (\Throwable $e) {
            Log::error('Resend verification mail error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal mengirim email verifikasi. Pastikan konfigurasi SMTP di server sudah benar.'
            ], 500);
        }
    }
}
