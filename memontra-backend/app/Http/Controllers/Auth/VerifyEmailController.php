<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Verified;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class VerifyEmailController extends Controller
{
    /**
     * Tandai email pengguna sebagai terverifikasi (support cross-device / link dari email).
     */
    public function __invoke(Request $request, $id, $hash): RedirectResponse
    {
        $frontendUrl = rtrim(env('FRONTEND_URL', env('APP_URL', 'https://momentrabooth.com')), '/');

        $user = $request->user() ?: User::find($id);

        if (!$user) {
            return redirect($frontendUrl . '/login?error=user_not_found');
        }

        if (!hash_equals((string) $hash, sha1($user->getEmailForVerification()))) {
            return redirect($frontendUrl . '/login?error=invalid_verification_hash');
        }

        if ($user->hasVerifiedEmail()) {
            return redirect($frontendUrl . '/login?verified=1');
        }

        if ($user->markEmailAsVerified()) {
            event(new Verified($user));
        }

        return redirect($frontendUrl . '/login?verified=1');
    }
}
