<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        Category::create(['name' => 'Tugas Kuliah']);
        Category::create(['name' => 'Kegiatan Kampus']);
        Category::create(['name' => 'Magang']);
        Category::create(['name' => 'Skripsi']);
        Category::create(['name' => 'Umum']);
    }
}