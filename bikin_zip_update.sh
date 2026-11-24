#!/bin/bash
# ==============================================================================
# Memontra Booth - Script Otomatis Pembuat Zip Update Deployment (Dewabiz cPanel)
# ==============================================================================

# Lokasi folder dasar proyek
PROJECT_DIR="/Users/macintoshhd/Documents/Memontra Booth"
BOOTH_REPO="$PROJECT_DIR/memontra-booth"
DEPLOY_DIR="$PROJECT_DIR/MemontraApp/DEWABIZ_DEPLOY"

echo "🚀 [1/4] Memulai pembuatan file update deployment..."

# 1. Build Frontend React
echo "📦 [2/4] Melakukan build frontend (memontra-web)..."
cd "$BOOTH_REPO/memontra-web" || exit 1
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build frontend gagal! Periksa error di atas."
    exit 1
fi

# 2. Sinkronisasi aset frontend ke public_html & update_frontend
echo "📂 Menyalin hasil build React ke folder public_html..."
cp -r "$BOOTH_REPO/memontra-web/dist/"* "$DEPLOY_DIR/public_html/"
cp -r "$BOOTH_REPO/memontra-web/dist/"* "$DEPLOY_DIR/update_frontend/"

# 3. Sinkronisasi backend terbaru ke memontra-core & update_backend
echo "📂 [3/4] Menyiapkan file backend terbaru..."
mkdir -p "$DEPLOY_DIR/update_backend/app" \
         "$DEPLOY_DIR/update_backend/bootstrap" \
         "$DEPLOY_DIR/update_backend/config" \
         "$DEPLOY_DIR/update_backend/routes" \
         "$DEPLOY_DIR/update_backend/resources" \
         "$DEPLOY_DIR/update_backend/vendor/laravel" \
         "$DEPLOY_DIR/update_backend/vendor/league"

cp -r "$BOOTH_REPO/memontra-backend/app/"* "$DEPLOY_DIR/update_backend/app/"
cp -r "$BOOTH_REPO/memontra-backend/bootstrap/"* "$DEPLOY_DIR/update_backend/bootstrap/"
cp -r "$BOOTH_REPO/memontra-backend/config/"* "$DEPLOY_DIR/update_backend/config/"
cp -r "$BOOTH_REPO/memontra-backend/routes/"* "$DEPLOY_DIR/update_backend/routes/"
cp -r "$BOOTH_REPO/memontra-backend/resources/"* "$DEPLOY_DIR/update_backend/resources/"
cp "$BOOTH_REPO/memontra-backend/composer.json" "$DEPLOY_DIR/update_backend/"

# Pastikan file repair.php tetap ada di public_html dan update_backend
if [ -f "$DEPLOY_DIR/public_html/repair.php" ]; then
    cp "$DEPLOY_DIR/public_html/repair.php" "$DEPLOY_DIR/update_backend/"
fi

# 4. Packaging ke file .ZIP
echo "🗜️ [4/4] Membungkus file ke format .ZIP..."
cd "$DEPLOY_DIR/public_html" && zip -r -q "$DEPLOY_DIR/public_html.zip" .
cd "$DEPLOY_DIR/update_backend" && zip -r -q "$DEPLOY_DIR/update_backend_v2.0.0.zip" .

echo "=========================================================="
echo "✅ SELESAI! File ZIP update siap diupload ke cPanel:"
echo "1. $DEPLOY_DIR/public_html.zip"
echo "2. $DEPLOY_DIR/update_backend_v2.0.0.zip"
echo "=========================================================="
