<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rules;
use Illuminate\Validation\ValidationException;

class RegisteredUserController extends Controller
{
    /**
     * Handle an incoming registration request.
     *
     * @throws ValidationException
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'lowercase', 'email', 'max:255', 'unique:'.User::class],
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->string('password')),
            'email_verified_at' => null, // Wajib verifikasi email untuk pendaftaran biasa
        ]);

        // Kirim email notifikasi verifikasi secara aman
        try {
            event(new Registered($user));
        } catch (\Throwable $e) {
            Log::warning("Gagal mengirim email verifikasi ke {$user->email}: " . $e->getMessage());
        }

        Auth::login($user);

        return response()->json([
            'status' => 'success',
            'message' => 'Registrasi berhasil! Tautan verifikasi telah dikirim ke email Anda.',
            'user' => $user,
            'must_verify_email' => true,
        ], 201);
    }
}
