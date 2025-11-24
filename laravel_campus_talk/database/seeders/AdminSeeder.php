<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run()
    {
        // 1. Pastikan Role ada
        $adminRole = Role::firstOrCreate(['name' => 'admin']);
        $userRole = Role::firstOrCreate(['name' => 'user']);

        // 2. Buat Akun Admin
        User::updateOrCreate(
            ['email' => 'admin@del.ac.id'],
            [
                'name' => 'Admin',
                'password' => Hash::make('admin123'),
                'role_id' => $adminRole->id,
                'is_approved' => true, // <--- TAMBAHKAN INI
            ]
        );

        // // 3. Buat Akun User Biasa (Contoh)
        // User::updateOrCreate(
        //     ['email' => 'user@campustalk.com'],
        //     [
        //         'name' => 'Mahasiswa Biasa',
        //         'password' => Hash::make('password123'),
        //         'role_id' => $userRole->id,
        //     ]
        // );
    }
}