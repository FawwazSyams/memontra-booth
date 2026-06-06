<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Laravel\Socialite\Facades\Socialite;
use Exception;

class GoogleController extends Controller
{
    public function redirect()
    {
        return Socialite::driver('google')->redirect();
    }

    public function callback()
    {
        try {
            // Ambil data user dari Google
            $googleUser = Socialite::driver('google')->user();

            // Cari user berdasarkan email atau google_id
            $user = User::where('email', $googleUser->email)->orWhere('google_id', $googleUser->id)->first();

            if (!$user) {
                // Kalau user belum pernah daftar sama sekali, buatin akun baru
                $user = User::create([
                    'name' => $googleUser->name,
                    'email' => $googleUser->email,
                    'google_id' => $googleUser->id,
                    'password' => null, // Bebas password
                    'email_verified_at' => now(), // Otomatis terverifikasi karena dari Google
                ]);
            } else {
                // Kalau emailnya udah ada (pernah daftar manual), update google_id-nya
                $user->update([
                    'google_id' => $googleUser->id,
                    'email_verified_at' => $user->email_verified_at ?? now(),
                ]);
            }

            // Loginkan user ke sistem Laravel
            Auth::login($user);

            // Redirect balik ke React (Frontend)
            // Pastikan URL ini sesuai dengan URL React kamu berjalan
            return redirect('http://localhost:5173/');

        } catch (Exception $e) {
            // Kalau gagal/cancel, lempar balik ke halaman login React
            return redirect('http://localhost:5173/login?error=google_auth_failed');
        }
    }
}