<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            // Relasi ke tabel users (siapa yang booking)
            $table->foreignId('user_id')->constrained()->onDelete('cascade');

            // Data Pesanan
            $table->string('package');
            $table->date('date');
            $table->time('time');
            $table->string('city');
            $table->string('event_type');
            $table->text('address');

            // Status pesanan (pending, confirmed, completed, cancelled)
            $table->string('status')->default('pending');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
