<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Admin User
        User::updateOrCreate(
            ['email' => 'momentrabooth@gmail.com'],
            [
                'name' => 'Admin Memontra',
                'password' => bcrypt('momentra2026'),
                'is_admin' => true,
            ]
        );
    }
}
