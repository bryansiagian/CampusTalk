<?php

// database/migrations/xxxx_xx_xx_xxxxxx_create_users_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->foreignId('role_id')->constrained('roles')->onDelete('restrict'); // Foreign key ke roles
            $table->string('name');
            $table->string('email')->unique();
            $table->string('nim')->unique()->nullable();
            $table->string('prodi')->nullable();
            $table->year('angkatan')->nullable();
            $table->string('password');
            $table->timestamp('email_verified_at')->nullable();
            $table->boolean('is_approved')->default(false);

            $table->rememberToken();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};