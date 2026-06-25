# Pakai image PHP resmi
FROM php:8.2-cli

# Install system dependencies & ekstensi PHP yang dibutuhkan Laravel
RUN apt-get update -y && apt-get install -y \
    libmcrypt-dev \
    openssl \
    zip \
    unzip \
    git \
    libonig-dev \
    && docker-php-ext-install pdo mbstring pdo_mysql

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set folder kerja di dalam server
WORKDIR /app

# Copy semua file Laravel kamu ke dalam server Hugging Face
COPY . /app

# Install dependency Laravel
RUN composer install --no-dev --optimize-autoloader

# Beri izin akses ke folder storage dan cache
RUN chmod -R 777 storage bootstrap/cache

# Hugging Face WAJIB pakai port 7860
EXPOSE 7860

# Jalankan server Laravel di port 7860
CMD php artisan serve --host=0.0.0.0 --port=7860