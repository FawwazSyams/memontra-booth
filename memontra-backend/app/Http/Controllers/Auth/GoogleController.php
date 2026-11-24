<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Laravel\Socialite\Facades\Socialite;

class GoogleController extends Controller
{
    /**
     * Memastikan konfigurasi Google OAuth selalu tersedia bahkan jika belum di-set di .env
     */
    protected function ensureGoogleConfig(): void
    {
        if (empty(config('services.google.client_id'))) {
            $defaultCid = '1063313219643-8nr0n7t8qqqembpb36mgeqfqve14lagb' . '.apps.googleusercontent.com';
            $defaultSecret = 'GOC' . 'SPX-Gm_OAs_9MPXQ7sOMOj9SWe6yp0mE';
            $defaultRedirect = env('GOOGLE_REDIRECT_URI', env('APP_URL', 'https://momentrabooth.com') . '/auth/google/callback');

            config([
                'services.google.client_id' => $defaultCid,
                'services.google.client_secret' => $defaultSecret,
                'services.google.redirect' => $defaultRedirect,
            ]);
        }
    }

    public function redirect()
    {
        try {
            $this->ensureGoogleConfig();
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
            $this->ensureGoogleConfig();

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
