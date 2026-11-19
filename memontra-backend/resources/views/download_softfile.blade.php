<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Memontra Booth - Galeri Softfile & Foto Strip</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
    <!-- Lightweight Client-Side GIF Generator -->
    <script src="https://cdn.jsdelivr.net/npm/gifshot@0.4.5/dist/gifshot.min.js"></script>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-tap-highlight-color: transparent;
        }
        body {
            background: linear-gradient(135deg, #07101E 0%, #0B192C 50%, #1E3E62 100%);
            color: #FFFFFF;
            font-family: 'Plus Jakarta Sans', sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px 12px;
        }
        .container {
            width: 100%;
            max-width: 520px;
            background: rgba(255, 255, 255, 0.08);
            backdrop-filter: blur(24px);
            -webkit-backdrop-filter: blur(24px);
            padding: 24px 18px;
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
            padding: 5px 14px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 0.5px;
            text-transform: uppercase;
            margin-bottom: 10px;
        }
        h1 {
            color: #FFFFFF;
            font-size: 24px;
            font-weight: 800;
            margin-bottom: 4px;
        }
        p.subtitle {
            color: rgba(255, 255, 255, 0.75);
            font-size: 13px;
            line-height: 1.5;
            margin-bottom: 18px;
        }

        /* SHOWCASE HASIL FOTO STRIP + FRAME */
        .strip-showcase {
            background: rgba(0, 0, 0, 0.45);
            border-radius: 24px;
            padding: 16px;
            border: 2px solid rgba(242, 169, 0, 0.55);
            box-shadow: 0 12px 36px rgba(242, 169, 0, 0.2);
            margin-bottom: 20px;
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
            max-width: 250px;
            aspect-ratio: 1 / 3;
            border-radius: 14px;
            overflow: hidden;
            background: #fff;
            box-shadow: 0 10px 30px rgba(0,0,0,0.6);
            margin-bottom: 14px;
            position: relative;
        }
        .strip-preview-img {
            width: 100%;
            height: 100%;
            object-fit: contain;
            display: block;
            user-select: none;
            -webkit-user-select: none;
        }

        /* TIPS SENTUH UNTUK SMARTPHONE */
        .touch-tip {
            font-size: 11px;
            color: rgba(255, 255, 255, 0.65);
            margin-bottom: 14px;
            background: rgba(255, 255, 255, 0.06);
            padding: 6px 12px;
            border-radius: 10px;
            border: 1px dashed rgba(255, 255, 255, 0.2);
            line-height: 1.4;
        }

        /* TOMBOL UTAMA SIMPAN KE GALERI */
        .btn-gallery-primary {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            width: 100%;
            padding: 15px 18px;
            background: linear-gradient(135deg, #F2A900 0%, #E08E00 100%);
            color: #07101E;
            text-decoration: none;
            font-weight: 800;
            border-radius: 16px;
            font-size: 15px;
            box-shadow: 0 6px 20px rgba(242, 169, 0, 0.4);
            border: none;
            cursor: pointer;
            transition: transform 0.15s, box-shadow 0.15s;
            margin-bottom: 8px;
        }
        .btn-gallery-primary:active {
            transform: scale(0.98);
        }

        .btn-strip-direct {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            width: 100%;
            padding: 11px 16px;
            background: rgba(255, 255, 255, 0.12);
            color: #FFFFFF;
            text-decoration: none;
            font-weight: 700;
            border-radius: 14px;
            font-size: 13px;
            border: 1px solid rgba(255, 255, 255, 0.25);
            cursor: pointer;
        }
        .btn-strip-direct:active {
            background: rgba(255, 255, 255, 0.2);
        }

        /* GIF Boomerang Player */
        .gif-container {
            position: relative;
            background: #000;
            border-radius: 20px;
            overflow: hidden;
            border: 1px solid rgba(255, 255, 255, 0.15);
            aspect-ratio: 4 / 3;
            margin-bottom: 14px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.5);
        }
        .gif-frame {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            object-fit: cover;
            opacity: 0;
            transition: opacity 0.1s ease-in-out;
        }
        .gif-frame.active {
            opacity: 1;
        }
        .gif-badge {
            position: absolute;
            top: 12px;
            left: 12px;
            background: rgba(0, 0, 0, 0.7);
            color: #fff;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
            border: 1px solid rgba(255,255,255,0.25);
            z-index: 10;
        }

        /* TOMBOL AKSI GIF & ZIP */
        .action-group {
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-bottom: 22px;
        }
        .btn-gif-generate {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            width: 100%;
            padding: 13px 18px;
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
            color: #FFFFFF;
            border: none;
            font-weight: 800;
            border-radius: 16px;
            font-size: 14px;
            box-shadow: 0 6px 18px rgba(16, 185, 129, 0.35);
            cursor: pointer;
        }
        .btn-gif-generate:active {
            transform: scale(0.98);
        }

        .btn-zip-download {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            width: 100%;
            padding: 11px 16px;
            background: rgba(255, 255, 255, 0.08);
            color: rgba(255, 255, 255, 0.85);
            text-decoration: none;
            font-weight: 700;
            border-radius: 14px;
            font-size: 13px;
            border: 1px solid rgba(255, 255, 255, 0.18);
        }

        /* GRID FOTO SATUAN POSE */
        .section-title {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
            font-size: 14px;
            font-weight: 800;
            color: #F2A900;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 0 4px;
        }
        .photo-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            margin-bottom: 24px;
        }
        .photo-card {
            background: rgba(0, 0, 0, 0.4);
            border-radius: 16px;
            overflow: hidden;
            border: 1px solid rgba(255, 255, 255, 0.12);
            display: flex;
            flex-direction: column;
        }
        .photo-thumb {
            width: 100%;
            aspect-ratio: 4 / 3;
            object-fit: cover;
            display: block;
        }
        .photo-card-actions {
            padding: 8px;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .btn-card-save {
            background: #F2A900;
            color: #07101E;
            border: none;
            padding: 7px 10px;
            border-radius: 10px;
            font-size: 11px;
            font-weight: 800;
            cursor: pointer;
            text-align: center;
        }
        .btn-card-download {
            background: rgba(255, 255, 255, 0.1);
            color: #fff;
            text-decoration: none;
            padding: 6px 10px;
            border-radius: 10px;
            font-size: 11px;
            font-weight: 600;
            text-align: center;
            border: 1px solid rgba(255,255,255,0.15);
        }

        /* TOAST NOTIFIKASI */
        .toast {
            position: fixed;
            bottom: 24px;
            left: 50%;
            transform: translateX(-50%) translateY(100px);
            background: #0B192C;
            color: #F2A900;
            padding: 12px 24px;
            border-radius: 999px;
            font-size: 13px;
            font-weight: 700;
            border: 1px solid rgba(242, 169, 0, 0.4);
            box-shadow: 0 10px 30px rgba(0,0,0,0.8);
            transition: transform 0.3s cubic-bezier(0.18, 0.89, 0.32, 1.28);
            z-index: 9999;
            pointer-events: none;
        }
        .toast.show {
            transform: translateX(-50%) translateY(0);
        }

        .empty-state {
            padding: 36px 16px;
            color: rgba(255, 255, 255, 0.7);
            font-size: 14px;
            line-height: 1.6;
        }
        .btn-refresh {
            display: inline-block;
            margin-top: 14px;
            padding: 10px 20px;
            background: #F2A900;
            color: #07101E;
            text-decoration: none;
            font-weight: 700;
            border-radius: 12px;
        }
        .footer {
            margin-top: 20px;
            font-size: 11px;
            color: rgba(255, 255, 255, 0.45);
        }
    </style>
</head>
<body>
    <div class="container">
        <span class="badge">Memontra Photobooth</span>
        <h1>Koleksi Fotomu Siap! ✨</h1>
        <p class="subtitle">Simpan langsung ke galeri HP tanpa perlu ekstrak file.</p>

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
                         id="mainStripImg"
                         class="strip-preview-img">
                </div>
                <p class="touch-tip">💡 <strong>Pengguna HP:</strong> Tekan & tahan (long-press) foto di atas untuk opsi <em>"Simpan ke Foto"</em>.</p>

                <!-- Tombol Simpan Langsung ke Galeri (Web Share / Direct Save) -->
                <button type="button" 
                        class="btn-gallery-primary" 
                        onclick="saveImageToGallery('{{ url('/download/' . $sessionId . '/view-strip') }}', 'Memontra-PhotoStrip-{{ substr($sessionId, 0, 8) }}.png')">
                    <span>💾 Simpan Strip ke Galeri HP</span>
                </button>

                <!-- Tombol Unduh File PNG Biasa -->
                <a href="{{ url('/download/' . $sessionId . '/strip') }}" 
                   download="Memontra-PhotoStrip-{{ substr($sessionId, 0, 8) }}.png"
                   class="btn-strip-direct">
                    <span>⬇ Unduh Gambar (.PNG)</span>
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
                         data-src="{{ url('/download/' . $sessionId . '/view-photo/' . $photo->id) }}"
                         data-index="{{ $index }}">
                @endforeach
            </div>

            <!-- Tombol Aksi Animasi & ZIP Cadangan -->
            <div class="action-group">
                <!-- Generate & Simpan Animasi GIF Nyata -->
                <button type="button" class="btn-gif-generate" id="btnSaveGif" onclick="generateAndSaveGif()">
                    <span>🎬 Simpan Animasi (.GIF) ke Galeri</span>
                </button>

                <!-- Unduh ZIP untuk Laptop / Komputer -->
                <a href="{{ url('/download/' . $sessionId . '/zip') }}" class="btn-zip-download">
                    <span>📦 Unduh Semua Sekaligus (.ZIP untuk PC)</span>
                </a>
            </div>

            <!-- Koleksi Seluruh Foto Satuan Sesi Ini -->
            <div class="section-title">
                <span>Daftar Pose Foto ({{ $posePhotos->count() }} Jepretan)</span>
                <span style="font-size: 11px; color: rgba(255,255,255,0.5);">Simpan satuan</span>
            </div>

            <div class="photo-grid">
                @foreach($posePhotos as $photo)
                    <div class="photo-card">
                        <img src="{{ url('/download/' . $sessionId . '/view-photo/' . $photo->id) }}" 
                             alt="Foto #{{ $photo->sequence_number }}" 
                             class="photo-thumb" 
                             loading="lazy">
                        <div class="photo-card-actions">
                            <button type="button" 
                                    class="btn-card-save" 
                                    onclick="saveImageToGallery('{{ url('/download/' . $sessionId . '/view-photo/' . $photo->id) }}', 'Memontra-Pose-{{ $photo->sequence_number }}.jpg')">
                                💾 Simpan ke Galeri
                            </button>
                            <a href="{{ url('/download/' . $sessionId . '/photo/' . $photo->id) }}" 
                               download="Memontra-Pose-{{ $photo->sequence_number }}.jpg" 
                               class="btn-card-download">
                                ⬇ Unduh JPG
                            </a>
                        </div>
                    </div>
                @endforeach
            </div>
        @elseif(!$stripPhoto)
            <div class="empty-state">
                <p>Foto untuk sesi ini sedang diunggah dari booth atau sedang diproses.</p>
                <a href="javascript:location.reload()" class="btn-refresh">🔄 Muat Ulang Halaman</a>
            </div>
        @endif

        <div class="footer">
            ID Sesi: <code>{{ $sessionId }}</code><br>
            © Memontra Booth. Simpan ke ponselmu sebelum kedaluwarsa.
        </div>
    </div>

    <!-- Toast Feedback -->
    <div class="toast" id="toastMsg">Sedang memproses unduhan...</div>

    <script>
        // 1. Pemutar Live Animasi GIF Frame
        document.addEventListener('DOMContentLoaded', function() {
            const frames = document.querySelectorAll('.gif-frame');
            if (frames.length > 1) {
                let currentIndex = 0;
                setInterval(() => {
                    frames[currentIndex].classList.remove('active');
                    currentIndex = (currentIndex + 1) % frames.length;
                    frames[currentIndex].classList.add('active');
                }, 480);
            }
        });

        function showToast(text) {
            const toast = document.getElementById('toastMsg');
            toast.textContent = text;
            toast.classList.add('show');
            setTimeout(() => toast.classList.remove('show'), 3500);
        }

        // 2. Simpan Gambar Langsung ke Galeri (Web Share API untuk iOS / Android)
        async function saveImageToGallery(imageUrl, filename) {
            showToast('Menyiapkan gambar untuk galeri...');
            try {
                const response = await fetch(imageUrl);
                const blob = await response.blob();
                const mimeType = filename.endsWith('.png') ? 'image/png' : 'image/jpeg';
                const file = new File([blob], filename, { type: mimeType });

                // Cek apakah browser mendukung Web Share File (Mobile Safari / Android Chrome)
                if (navigator.canShare && navigator.canShare({ files: [file] })) {
                    await navigator.share({
                        files: [file],
                        title: 'Memontra Photo Booth',
                        text: 'Hasil Foto Memontra Booth'
                    });
                    showToast('Silakan pilih "Simpan Gambar" di menu HP!');
                    return;
                }
            } catch (err) {
                console.log('Web share fallback to direct download:', err);
            }

            // Fallback jika dibuka di desktop atau browser tidak dukung Web Share
            const a = document.createElement('a');
            a.href = imageUrl;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            showToast('Gambar berhasil diunduh ke perangkatmu!');
        }

        // 3. Generator & Simpan Animasi Nyata (.GIF)
        async function generateAndSaveGif() {
            const btn = document.getElementById('btnSaveGif');
            const frames = document.querySelectorAll('.gif-frame');
            if (!frames || frames.length === 0) {
                showToast('Tidak ada foto untuk dibuat animasi!');
                return;
            }

            btn.disabled = true;
            btn.innerHTML = '<span>⏳ Membuat Animasi GIF...</span>';
            showToast('Sedang membuat file animasi .GIF...');

            const imageUrls = [];
            frames.forEach(f => {
                const src = f.getAttribute('data-src') || f.src;
                if (src) imageUrls.push(src);
            });

            if (typeof gifshot !== 'undefined') {
                gifshot.createGIF({
                    images: imageUrls,
                    gifWidth: 600,
                    gifHeight: 450,
                    interval: 0.45,
                    numFrames: imageUrls.length,
                    frameDuration: 4,
                }, async function(obj) {
                    btn.disabled = false;
                    btn.innerHTML = '<span>🎬 Simpan Animasi (.GIF) ke Galeri</span>';

                    if (!obj.error) {
                        const base64Data = obj.image;
                        const res = await fetch(base64Data);
                        const blob = await res.blob();
                        const filename = 'Memontra-Boomerang.gif';
                        const file = new File([blob], filename, { type: 'image/gif' });

                        if (navigator.canShare && navigator.canShare({ files: [file] })) {
                            try {
                                await navigator.share({
                                    files: [file],
                                    title: 'Memontra Boomerang GIF',
                                    text: 'Animasi Boomerang Memontra Booth'
                                });
                                showToast('Pilih "Simpan Gambar" untuk simpan ke galeri!');
                                return;
                            } catch (_) {}
                        }

                        const a = document.createElement('a');
                        a.href = base64Data;
                        a.download = filename;
                        document.body.appendChild(a);
                        a.click();
                        document.body.removeChild(a);
                        showToast('Animasi GIF berhasil disimpan!');
                    } else {
                        showToast('Gagal membuat GIF, unduh foto pose satuan.');
                    }
                });
            } else {
                btn.disabled = false;
                btn.innerHTML = '<span>🎬 Simpan Animasi (.GIF) ke Galeri</span>';
                showToast('Fitur GIF sedang dimuat, coba lagi sebentar lagi.');
            }
        }
    </script>
</body>
</html>
