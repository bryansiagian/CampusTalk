<?php

// database/migrations/xxxx_xx_xx_xxxxxx_create_roles_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->id(); // Ini akan menjadi SERIAL PRIMARY KEY
            $table->string('name', 50)->unique();
            $table->timestamps(); // Menambahkan created_at dan updated_at
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('roles');
    }
};