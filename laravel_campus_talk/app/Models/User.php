<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens; // Penting untuk Sanctum

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'role_id',
        'name',
        'email',
        'profile_picture',
        'password',
        'is_approved',
        'nim',
        'prodi_id',
        'angkatan',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    // Relasi: User memiliki satu Role
    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    // Relasi: User memiliki banyak Postingan
    public function posts()
    {
        return $this->hasMany(Post::class);
    }

    // Relasi: User memiliki banyak Komentar
    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    // Relasi: User memiliki banyak Like
    public function likes()
    {
        return $this->hasMany(Like::class);
    }

    // Relasi: User menerima banyak notifikasi
    public function notifications() // <--- TAMBAHKAN INI
    {
        return $this->hasMany(Notification::class);
    }

    // Cek apakah user adalah admin
    public function isAdmin()
    {
        return $this->role->name === 'admin';
    }

    public function prodi()
    {
        return $this->belongsTo(Prodi::class);
    }

    // Accessor untuk mendapatkan URL lengkap
    public function getProfilePictureUrlAttribute()
    {
        if ($this->profile_picture) {
            return asset('storage/' . $this->profile_picture);
        }
        return null;
    }

    protected $appends = ['profile_picture_url'];
}