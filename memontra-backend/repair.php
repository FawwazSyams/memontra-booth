<?php
/**
 * Memontra Booth - Self-Healing & Diagnostic Utility for cPanel Dewabiz
 * Akses di browser: https://momentrabooth.com/repair.php
 */

header('Content-Type: text/html; charset=utf-8');

$coreDir = dirname(__DIR__) . '/memontra-core';
if (!is_dir($coreDir)) {
    $coreDir = __DIR__ . '/../memontra-core';
}

echo "<!DOCTYPE html><html><head><title>Memontra Booth Repair & Diagnostics</title>";
echo "<style>
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0b192c; color: #fff; padding: 24px; }
.card { background: rgba(255,255,255,0.08); border-radius: 12px; padding: 20px; margin-bottom: 20px; border: 1px solid rgba(255,255,255,0.15); }
.success { color: #4ade80; font-weight: bold; }
.error { color: #f87171; font-weight: bold; }
.warning { color: #fbbf24; font-weight: bold; }
pre { background: #000; padding: 14px; border-radius: 8px; overflow-x: auto; font-size: 12px; color: #38bdf8; max-height: 400px; }
h1, h2 { color: #f2a900; }
a.btn { display: inline-block; background: #f2a900; color: #000; padding: 10px 20px; border-radius: 8px; text-decoration: none; font-weight: bold; margin-top: 10px; }
</style></head><body>";

echo "<h1>🛠️ Memontra Booth - Server Diagnostic & Auto-Repair</h1>";
echo "<p>Path Memontra Core: <code>" . htmlspecialchars(realpath($coreDir) ?: $coreDir) . "</code></p>";

// 1. Bersihkan Bootstrap Cache yang usang (Penyebab utama error route / class not found)
echo "<div class='card'><h2>1. Membersihkan Cache Laravel</h2>";
$cacheDir = $coreDir . '/bootstrap/cache';
if (is_dir($cacheDir)) {
    $files = glob($cacheDir . '/*.php');
    $cleared = 0;
    foreach ($files as $file) {
        if (@unlink($file)) {
            $cleared++;
            echo "<p class='success'>✓ Berhasil menghapus cache: " . basename($file) . "</p>";
        } else {
            echo "<p class='warning'>⚠ Gagal menghapus: " . basename($file) . " (Silakan hapus manual jika perlu)</p>";
        }
    }
    if ($cleared === 0) {
        echo "<p class='success'>✓ Cache bootstrap sudah bersih (tidak ada cache usang).</p>";
    }
} else {
    echo "<p class='error'>✗ Folder bootstrap/cache tidak ditemukan!</p>";
}
echo "</div>";

// 2. Bersihkan View Cache & Periksa Permission Storage
echo "<div class='card'><h2>2. Memeriksa Folder Storage & Views</h2>";
$storageDirs = [
    $coreDir . '/storage/logs',
    $coreDir . '/storage/framework/views',
    $coreDir . '/storage/framework/sessions',
    $coreDir . '/storage/framework/cache',
    $coreDir . '/storage/app/public/photos',
];

foreach ($storageDirs as $dir) {
    if (!file_exists($dir)) {
        @mkdir($dir, 0775, true);
    }
    @chmod($dir, 0775);
    $writable = is_writable($dir);
    $rel = str_replace($coreDir . '/', '', $dir);
    if ($writable) {
        echo "<p class='success'>✓ <code>$rel</code>: Writable (Siap digunakan)</p>";
    } else {
        echo "<p class='error'>✗ <code>$rel</code>: TIDAK WRITABLE! Ubah permission folder ini ke 775 atau 777 di cPanel File Manager.</p>";
    }
}

// Hapus cache views lama agar view template terbaru ter-compile ulang
$viewCacheFiles = glob($coreDir . '/storage/framework/views/*.php');
$viewsCleared = 0;
if ($viewCacheFiles) {
    foreach ($viewCacheFiles as $vf) {
        if (@unlink($vf)) $viewsCleared++;
    }
}
echo "<p class='success'>✓ Membersihkan $viewsCleared file cache view lama.</p>";
echo "</div>";

// 3. Tes Booting Laravel Kernel & Route Test
echo "<div class='card'><h2>3. Pengujian Booting Laravel & Rute Download</h2>";
try {
    if (!file_exists($coreDir . '/vendor/autoload.php')) {
        throw new Exception("File vendor/autoload.php tidak ditemukan di $coreDir");
    }
    require_once $coreDir . '/vendor/autoload.php';

    if (!file_exists($coreDir . '/bootstrap/app.php')) {
        throw new Exception("File bootstrap/app.php tidak ditemukan di $coreDir");
    }
    $app = require_once $coreDir . '/bootstrap/app.php';
    $kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

    // Tes route /download/test-session
    $request = Illuminate\Http\Request::create('/download/test-session', 'GET');
    $response = $kernel->handle($request);
    $status = $response->getStatusCode();

    if ($status === 200) {
        echo "<p class='success'>🎉 RUTE /download/{sessionId} BERHASIL DI-LOAD DENGAN STATUS 200 OK!</p>";
        echo "<p>Halaman softfile sudah aktif dan tidak error lagi.</p>";
        echo "<a class='btn' href='/download/test-session' target='_blank'>Coba Buka Halaman Softfile Test</a>";
    } else {
        echo "<p class='error'>✗ Rute /download/test-session mengembalikan HTTP $status</p>";
        echo "<pre>" . htmlspecialchars(substr($response->getContent(), 0, 1000)) . "</pre>";
    }
} catch (\Throwable $e) {
    echo "<p class='error'>✗ FATAL ERROR SAAT BOOTING LARAVEL:</p>";
    echo "<p><strong>Pesan:</strong> " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<p><strong>File:</strong> " . htmlspecialchars($e->getFile()) . " (Baris: " . $e->getLine() . ")</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}
echo "</div>";

// 4. Tampilkan Log Laravel Terbaru
echo "<div class='card'><h2>4. Log Error Laravel Terbaru (storage/logs/laravel.log)</h2>";
$logFile = $coreDir . '/storage/logs/laravel.log';
if (file_exists($logFile)) {
    $lines = file($logFile);
    if (!empty($lines)) {
        $recent = array_slice($lines, -60);
        echo "<pre>" . htmlspecialchars(implode("", $recent)) . "</pre>";
    } else {
        echo "<p class='success'>Log file kosong (tidak ada error tercatat).</p>";
    }
} else {
    echo "<p class='warning'>Belum ada file log di: " . htmlspecialchars($logFile) . "</p>";
}
echo "</div>";

echo "<p style='color: rgba(255,255,255,0.6);'>Setelah masalah teratasi, silakan hapus file <code>repair.php</code> dari <code>public_html</code> demi keamanan.</p>";
echo "</body></html>";
