<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Role;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'if324029@students.del.ac.id'],
            [
                'name' => 'Bryan Torisi Siagian',
                'password' => Hash::make('bryan123'),
                'role_id' => 2,
                'nim' => '42324029',
                'prodi_id' => 1,
                'angkatan' => 2024,
                'is_approved' => true, // <--- TAMBAHKAN INI
            ]
        );
    }
}
