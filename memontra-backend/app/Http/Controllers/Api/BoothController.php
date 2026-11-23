<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Session;
use App\Models\Photo;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class BoothController extends Controller
{
    /**
     * 1. Ambil data event yang sedang aktif saat ini
     */
    public function getActiveEvent()
    {
        try {
            $event = Event::where('is_active', true)->first();

            if (!$event) {
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

            return response()->json($event, 200);
        } catch (\Throwable $e) {
            Log::warning('Fallback getActiveEvent: ' . $e->getMessage());

            return response()->json([
                'id' => 1,
                'name' => 'Memontra Photobooth Event',
                'photo_count' => 3,
                'layout_type' => 'strip',
                'is_active' => true,
            ], 200);
        }
    }

    /**
     * 2. Flutter tap layar -> Mulai sesi baru
     */
    public function startSession(Request $request)
    {
        $sessionId = (string) Str::uuid();

        try {
            $eventId = $request->event_id ?? 1;

            $session = Session::create([
                'id' => $sessionId,
                'event_id' => $eventId,
                'status' => 'active'
            ]);

            return response()->json([
                'message' => 'Sesi berhasil dimulai',
                'data' => $session
            ], 201);
        } catch (\Throwable $e) {
            Log::warning('Fallback startSession: ' . $e->getMessage());

            return response()->json([
                'message' => 'Sesi berhasil dimulai (standalone mode)',
                'data' => [
                    'id' => $sessionId,
                    'event_id' => 1,
                    'status' => 'active'
                ]
            ], 201);
        }
    }

    /**
     * 3. Upload hasil jepretan satuan dari Flutter ke Laravel
     */
    public function uploadPhoto(Request $request, $sessionId)
    {
        $request->validate([
            'sequence_number' => 'required|integer',
            'photo' => 'nullable|file|max:30720',
            'photo_base64' => 'nullable|string',
        ]);

        $seq = (int) $request->sequence_number;
        $filename = 'photos/' . $sessionId . '_pose_' . $seq . '_' . Str::random(6) . '.jpg';

        try {
            if ($request->hasFile('photo')) {
                Storage::disk('public')->putFileAs('photos', $request->file('photo'), basename($filename));
            } elseif ($request->filled('photo_base64')) {
                $image = $request->photo_base64;
                if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
                    $image = substr($image, strpos($image, ',') + 1);
                }
                $image = str_replace(' ', '+', $image);
                $decoded = base64_decode($image);
                Storage::disk('public')->put($filename, $decoded);
            } else {
                return response()->json(['message' => 'Data foto tidak valid atau kosong.'], 400);
            }
        } catch (\Throwable $e) {
            Log::error('Error saving photo file to disk: ' . $e->getMessage());
            return response()->json(['message' => 'Gagal menyimpan file foto ke server disk.'], 500);
        }

        // Coba simpan ke database (jika database tersedia)
        try {
            $session = Session::find($sessionId);
            if (!$session) {
                $defaultEvent = Event::firstOrCreate(
                    ['id' => 1],
                    [
                        'name' => 'Memontra Photobooth Event',
                        'photo_count' => 3,
                        'layout_type' => 'strip',
                        'is_active' => true,
                    ]
                );
                Session::create([
                    'id' => $sessionId,
                    'event_id' => $defaultEvent->id,
                    'status' => 'active'
                ]);
            }

            $photo = Photo::create([
                'session_id' => $sessionId,
                'file_path' => $filename,
                'sequence_number' => $seq
            ]);

            return response()->json([
                'message' => 'Foto ke-' . $seq . ' berhasil disimpan',
                'data' => $photo
            ], 201);
        } catch (\Throwable $e) {
            Log::warning('DB error during uploadPhoto (file saved safely to disk): ' . $e->getMessage());

            return response()->json([
                'message' => 'Foto ke-' . $seq . ' berhasil disimpan di disk',
                'file_path' => $filename
            ], 201);
        }
    }

    /**
     * 4. Upload Hasil Foto Strip + Frame (Komposit Final) untuk Softfile Download
     * Menyimpan sekaligus sebagai PNG dan JPG agar selalu kompatibel & cepat dimuat
     */
    public function uploadStrip(Request $request, $sessionId)
    {
        $request->validate([
            'photo' => 'nullable|file|max:30720',
            'photo_base64' => 'nullable|string',
        ]);

        $pngName = 'photos/strip_' . $sessionId . '.png';
        $jpgName = 'photos/strip_' . $sessionId . '.jpg';

        try {
            $bytes = null;
            if ($request->hasFile('photo')) {
                $bytes = file_get_contents($request->file('photo')->getRealPath());
            } elseif ($request->filled('photo_base64')) {
                $image = $request->photo_base64;
                if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
                    $image = substr($image, strpos($image, ',') + 1);
                }
                $image = str_replace(' ', '+', $image);
                $bytes = base64_decode($image);
            }

            if (!$bytes) {
                return response()->json(['message' => 'Data foto strip kosong.'], 400);
            }

            // Simpan keduanya di storage public disk
            Storage::disk('public')->put($pngName, $bytes);
            Storage::disk('public')->put($jpgName, $bytes);

        } catch (\Throwable $e) {
            Log::error('Error saving strip file to disk: ' . $e->getMessage());
            return response()->json(['message' => 'Gagal menyimpan foto strip ke disk.'], 500);
        }

        // Coba sinkronisasi record database
        try {
            $session = Session::find($sessionId);
            if (!$session) {
                $defaultEvent = Event::firstOrCreate(
                    ['id' => 1],
                    [
                        'name' => 'Memontra Photobooth Event',
                        'photo_count' => 3,
                        'layout_type' => 'strip',
                        'is_active' => true,
                    ]
                );
                Session::create([
                    'id' => $sessionId,
                    'event_id' => $defaultEvent->id,
                    'status' => 'active'
                ]);
            }

            Photo::where('session_id', $sessionId)->where('sequence_number', 0)->delete();

            $photo = Photo::create([
                'session_id' => $sessionId,
                'file_path' => $pngName,
                'sequence_number' => 0
            ]);

            return response()->json([
                'message' => 'Foto strip komposit + frame berhasil disimpan',
                'data' => $photo
            ], 201);
        } catch (\Throwable $e) {
            Log::warning('DB error during uploadStrip: ' . $e->getMessage());

            return response()->json([
                'message' => 'Foto strip komposit + frame berhasil disimpan di disk',
                'file_path' => $pngName
            ], 201);
        }
    }
}
