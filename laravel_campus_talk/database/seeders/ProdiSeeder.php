<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Prodi;

class ProdiSeeder extends Seeder
{
    public function run()
    {
        $prodis = [
            'D3 Teknologi Informasi',
            'D3 Teknologi Komputer',
            'D4 Teknologi Rekayasa Perangkat Lunak',
            'S1 Informatika',
            'S1 Sistem Informasi',
            'S1 Teknik Elektro',
            'S1 Manajemen Rekayasa',
            'S1 Teknik Metalurgi',
            'S1 Bioproses',
            'S1 Bioteknologi',
        ];

        foreach ($prodis as $name) {
            Prodi::create(['name' => $name]);
        }
    }
}