<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Memontra Booth - Galeri Softfile & Foto Strip</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            background: linear-gradient(135deg, #07101E 0%, #0B192C 50%, #1E3E62 100%);
            color: #FFFFFF;
            font-family: 'Plus Jakarta Sans', sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px 16px;
        }
        .container {
            width: 100%;
            max-width: 540px;
            background: rgba(255, 255, 255, 0.08);
            backdrop-filter: blur(24px);
            -webkit-backdrop-filter: blur(24px);
            padding: 30px 22px;
            border-radius: 28px;
            border: 1px solid rgba(255, 255, 255, 0.16);
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.55);
            text-align: center;
        }
        .badge {
            display: inline-block;
            background: rgba(242, 169, 0, 0.18);
            color: #F2A900;
            border: 1px solid rgba(242, 169, 0, 0.45);
            padding: 6px 16px;
            border-radius: 999px;
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 0.5px;
            text-transform: uppercase;
            margin-bottom: 12px;
        }
        h1 {
            color: #FFFFFF;
            font-size: 26px;
            font-weight: 800;
            margin-bottom: 6px;
        }
        p.subtitle {
            color: rgba(255, 255, 255, 0.75);
            font-size: 14px;
            line-height: 1.5;
            margin-bottom: 22px;
        }

        /* SHOWCASE HASIL FOTO STRIP + FRAME */
        .strip-showcase {
            background: rgba(0, 0, 0, 0.45);
            border-radius: 22px;
            padding: 16px;
            border: 2px solid rgba(242, 169, 0, 0.55);
            box-shadow: 0 12px 36px rgba(242, 169, 0, 0.2);
            margin-bottom: 22px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .strip-badge-label {
            display: flex;
            align-items: center;
            gap: 6px;
            color: #F2A900;
            font-size: 13px;
            font-weight: 800;
            margin-bottom: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .strip-preview-wrapper {
            width: 100%;
            max-width: 260px;
            aspect-ratio: 1 / 3;
            border-radius: 14px;
            overflow: hidden;
            background: #fff;
            box-shadow: 0 8px 24px rgba(0,0,0,0.5);
            margin-bottom: 14px;
        }
        .strip-preview-img {
            width: 100%;
            height: 100%;
            object-fit: contain;
            display: block;
        }
        .btn-strip-download {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            width: 100%;
            padding: 14px 20px;
            background: linear-gradient(135deg, #F2A900 0%, #E08E00 100%);
            color: #07101E;
            text-decoration: none;
            font-weight: 800;
            border-radius: 16px;
            font-size: 15px;
            box-shadow: 0 6px 20px rgba(242, 169, 0, 0.38);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .btn-strip-download:active {
            transform: scale(0.98);
        }

        /* GIF Boomerang Player */
        .gif-container {
            position: relative;
            background: #000;
            border-radius: 20px;
            overflow: hidden;
            border: 1px solid rgba(255, 255, 255, 0.15);
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
            margin-bottom: 18px;
            aspect-ratio: 4 / 3;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .gif-frame {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: none;
        }
        .gif-frame.active {
            display: block;
        }
        .gif-badge {
            position: absolute;
            top: 12px;
            left: 12px;
            background: rgba(0, 0, 0, 0.65);
            backdrop-filter: blur(8px);
            color: #F2A900;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 6px;
            border: 1px solid rgba(242, 169, 0, 0.3);
        }

        /* Tombol Aksi */
        .action-group {
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-bottom: 24px;
        }
        .btn-main {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            width: 100%;
            padding: 13px 20px;
            background: rgba(255, 255, 255, 0.15);
            color: #FFFFFF;
            text-decoration: none;
            font-weight: 700;
            border-radius: 14px;
            font-size: 14px;
            border: 1px solid rgba(255, 255, 255, 0.25);
            transition: background 0.2s;
        }
        .btn-main:hover {
            background: rgba(255, 255, 255, 0.25);
        }
        .btn-secondary {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            width: 100%;
            padding: 12px 20px;
            background: rgba(255, 255, 255, 0.08);
            color: rgba(255, 255, 255, 0.9);
            text-decoration: none;
            font-weight: 600;
            border-radius: 14px;
            font-size: 13.5px;
            border: 1px solid rgba(255, 255, 255, 0.15);
        }

        /* Daftar Semua Foto Satuan */
        .section-title {
            font-size: 15px;
            font-weight: 700;
            text-align: left;
            margin-bottom: 12px;
            color: rgba(255, 255, 255, 0.9);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            margin-bottom: 20px;
        }
        .photo-card {
            background: rgba(0, 0, 0, 0.35);
            border-radius: 16px;
            overflow: hidden;
            border: 1px solid rgba(255, 255, 255, 0.08);
            display: flex;
            flex-direction: column;
        }
        .photo-thumb {
            width: 100%;
            aspect-ratio: 4 / 3;
            object-fit: cover;
            display: block;
        }
        .btn-single-download {
            padding: 10px;
            background: rgba(242, 169, 0, 0.18);
            color: #F2A900;
            text-decoration: none;
            font-size: 13px;
            font-weight: 700;
            border-top: 1px solid rgba(255, 255, 255, 0.08);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }
        .btn-single-download:active {
            background: rgba(242, 169, 0, 0.35);
        }

        .empty-state {
            padding: 30px 10px;
            color: rgba(255, 255, 255, 0.7);
        }
        .btn-refresh {
            display: inline-block;
            margin-top: 14px;
            padding: 10px 24px;
            background: rgba(255, 255, 255, 0.14);
            color: #FFFFFF;
            text-decoration: none;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 600;
        }
        .footer {
            margin-top: 20px;
            font-size: 12px;
            color: rgba(255, 255, 255, 0.45);
        }
    </style>
</head>
<body>
    <div class="container">
        <span class="badge">Memontra Photobooth</span>
        <h1>Koleksi Fotomu Siap! ✨</h1>
        <p class="subtitle">Unduh hasil foto strip lengkap beserta frame atau jepretan satuan pose.</p>

        @php
            $stripPhoto = $photos->firstWhere('sequence_number', 0);
            $posePhotos = $photos->where('sequence_number', '>', 0);
        @endphp

        <!-- 1. HASIL FOTO STRIP + FRAME LENGKAP (PRIORITAS UTAMA) -->
        @if($stripPhoto)
            <div class="strip-showcase">
                <div class="strip-badge-label">
                    <span>🖼️ Foto Strip + Frame Kamu</span>
                </div>
                <div class="strip-preview-wrapper">
                    <img src="{{ url('/download/' . $sessionId . '/view-strip') }}" 
                         alt="Foto Strip dan Frame Memontra" 
                         class="strip-preview-img">
                </div>
                <a href="{{ url('/download/' . $sessionId . '/strip') }}" class="btn-strip-download">
                    <span>⬇ Unduh Foto Strip + Frame (.PNG)</span>
                </a>
            </div>
        @endif

        @if($posePhotos->count() > 0)
            <!-- Pemutar Live Animasi GIF / Boomerang -->
            <div class="gif-container" id="gifPlayer">
                <span class="gif-badge">🎬 Live Animasi GIF</span>
                @foreach($posePhotos as $index => $photo)
                    <img src="{{ url('/download/' . $sessionId . '/view-photo/' . $photo->id) }}" 
                         alt="Pose {{ $photo->sequence_number }}" 
                         class="gif-frame {{ $index === 0 ? 'active' : '' }}" 
                         data-index="{{ $index }}">
                @endforeach
            </div>

            <!-- Tombol Unduh Tambahan (ZIP & GIF) -->
            <div class="action-group">
                <a href="{{ url('/download/' . $sessionId . '/zip') }}" class="btn-main">
                    <span>📦 Unduh Semua Foto & Frame (File .ZIP)</span>
                </a>
                <a href="{{ url('/download/' . $sessionId . '/gif') }}" class="btn-secondary">
                    <span>🎬 Simpan Animasi (.GIF)</span>
                </a>
            </div>

            <!-- Koleksi Seluruh Foto Satuan Sesi Ini -->
            <div class="section-title">
                <span>Daftar Pose Foto ({{ $posePhotos->count() }} Jepretan)</span>
                <span style="font-size: 12px; color: rgba(255,255,255,0.5);">Unduh satuan</span>
            </div>

            <div class="photo-grid">
                @foreach($posePhotos as $photo)
                    <div class="photo-card">
                        <img src="{{ url('/download/' . $sessionId . '/view-photo/' . $photo->id) }}" 
                             alt="Foto #{{ $photo->sequence_number }}" 
                             class="photo-thumb" 
                             loading="lazy">
                        <a href="{{ url('/download/' . $sessionId . '/photo/' . $photo->id) }}" class="btn-single-download">
                            ⬇ Pose #{{ $photo->sequence_number }}
                        </a>
                    </div>
                @endforeach
            </div>
        @elseif(!$stripPhoto)
            <div class="empty-state">
                <p>Foto untuk sesi ini sedang diunggah dari booth atau belum tersedia.</p>
                <a href="javascript:location.reload()" class="btn-refresh">🔄 Muat Ulang Halaman</a>
            </div>
        @endif

        <div class="footer">
            ID Sesi: <code>{{ $sessionId }}</code><br>
            © Memontra Booth. Simpan ke ponselmu sebelum kedaluwarsa.
        </div>
    </div>

    <!-- Script Pemutar Animasi GIF Boomerang Otomatis -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const frames = document.querySelectorAll('.gif-frame');
            if (frames.length > 1) {
                let currentIndex = 0;
                setInterval(() => {
                    frames[currentIndex].classList.remove('active');
                    currentIndex = (currentIndex + 1) % frames.length;
                    frames[currentIndex].classList.add('active');
                }, 500);
            }
        });
    </script>
</body>
</html>
