<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Laravel\Socialite\Facades\Socialite;

class GoogleController extends Controller
{
    public function redirect()
    {
        try {
            return Socialite::driver('google')->redirect();
        } catch (\Throwable $e) {
            Log::error('Google Redirect Error: ' . $e->getMessage());
            $frontendUrl = rtrim(env('FRONTEND_URL', env('APP_URL', 'https://momentrabooth.com')), '/');
            return redirect($frontendUrl . '/login?error=google_config_error');
        }
    }

    public function callback()
    {
        $frontendUrl = rtrim(env('FRONTEND_URL', env('APP_URL', 'https://momentrabooth.com')), '/');

        try {
            // Ambil data user dari Google
            $googleUser = Socialite::driver('google')->user();

            if (!$googleUser || !$googleUser->getEmail()) {
                return redirect($frontendUrl . '/login?error=google_email_not_provided');
            }

            // Cari user berdasarkan email atau google_id
            $user = User::where('email', $googleUser->getEmail())
                ->orWhere('google_id', $googleUser->getId())
                ->first();

            if (!$user) {
                // Buat akun baru jika belum terdaftar
                $user = User::create([
                    'name' => $googleUser->getName() ?? 'Pengguna Google',
                    'email' => $googleUser->getEmail(),
                    'google_id' => $googleUser->getId(),
                    'password' => null,
                    'email_verified_at' => now(), // Otomatis terverifikasi via Google OAuth
                ]);
            } else {
                // Update info google_id dan verifikasi email jika sudah ada
                $user->update([
                    'google_id' => $googleUser->getId(),
                    'email_verified_at' => $user->email_verified_at ?? now(),
                ]);
            }

            // Loginkan user ke sistem Laravel session (remember = true)
            Auth::login($user, true);

            // Redirect balik ke React Frontend
            return redirect($frontendUrl . '/?login=google_success');

        } catch (\Throwable $e) {
            Log::error('Google Callback Error: ' . $e->getMessage());
            return redirect($frontendUrl . '/login?error=google_auth_failed');
        }
    }
}
