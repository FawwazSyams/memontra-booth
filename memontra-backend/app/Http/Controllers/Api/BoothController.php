<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Session;
use App\Models\Photo;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class BoothController extends Controller
{
    // 1. Ambil data event yang sedang aktif saat ini
    public function getActiveEvent()
    {
        $event = Event::where('is_active', true)->first();

        if (!$event) {
            // Buat event default jika belum ada
            $event = Event::firstOrCreate(
                ['id' => 1],
                [
                    'name' => 'Memontra Photobooth Event',
                    'photo_count' => 3,
                    'layout_type' => 'strip',
                    'is_active' => true,
                ]
            );
        }

        return response()->json($event);
    }

    // 2. Flutter tap layar -> Mulai sesi baru
    public function startSession(Request $request)
    {
        $eventId = $request->event_id;
        if (!$eventId) {
            $activeEvent = Event::where('is_active', true)->first();
            $eventId = $activeEvent ? $activeEvent->id : 1;
        }

        $session = Session::create([
            'event_id' => $eventId,
            'status' => 'active'
        ]);

        return response()->json([
            'message' => 'Sesi berhasil dimulai',
            'data' => $session
        ], 201);
    }

    // 3. Upload hasil jepretan satuan dari Flutter ke Laravel
    public function uploadPhoto(Request $request, $sessionId)
    {
        $request->validate([
            'sequence_number' => 'required|integer',
            'photo' => 'nullable|image|mimes:jpeg,png,jpg|max:20480',
            'photo_base64' => 'nullable|string',
        ]);

        $path = null;

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('photos', 'public');
        } elseif ($request->filled('photo_base64')) {
            $image = $request->photo_base64;
            if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
                $image = substr($image, strpos($image, ',') + 1);
            }
            $image = str_replace(' ', '+', $image);
            $decoded = base64_decode($image);
            
            $filename = 'photos/' . Str::random(40) . '.jpg';
            Storage::disk('public')->put($filename, $decoded);
            $path = $filename;
        }

        if (!$path) {
            return response()->json(['message' => 'Data foto tidak valid atau kosong.'], 400);
        }

        $photo = Photo::create([
            'session_id' => $sessionId,
            'file_path' => $path,
            'sequence_number' => $request->sequence_number
        ]);

        return response()->json([
            'message' => 'Foto ke-' . $request->sequence_number . ' berhasil disimpan',
            'data' => $photo
        ], 201);
    }

    // 4. Upload Hasil Foto Strip + Frame (Komposit Final) untuk Softfile Download
    public function uploadStrip(Request $request, $sessionId)
    {
        $request->validate([
            'photo' => 'nullable|image|mimes:jpeg,png,jpg|max:25600',
            'photo_base64' => 'nullable|string',
        ]);

        $path = null;

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('photos', 'public');
        } elseif ($request->filled('photo_base64')) {
            $image = $request->photo_base64;
            if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
                $image = substr($image, strpos($image, ',') + 1);
            }
            $image = str_replace(' ', '+', $image);
            $decoded = base64_decode($image);
            
            $filename = 'photos/strip_' . $sessionId . '_' . Str::random(8) . '.png';
            Storage::disk('public')->put($filename, $decoded);
            $path = $filename;
        }

        if (!$path) {
            return response()->json(['message' => 'Data foto strip tidak valid atau kosong.'], 400);
        }

        // Hapus strip komposit lama untuk sesi ini jika ada (agar tidak duplikat)
        Photo::where('session_id', $sessionId)->where('sequence_number', 0)->delete();

        $photo = Photo::create([
            'session_id' => $sessionId,
            'file_path' => $path,
            'sequence_number' => 0 // 0 menandakan foto strip komposit dengan frame
        ]);

        return response()->json([
            'message' => 'Foto strip komposit + frame berhasil disimpan',
            'data' => $photo
        ], 201);
    }
}
