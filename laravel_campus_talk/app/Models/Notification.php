<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'source_id',
        'source_type',
        'message',
        'is_read',
        'sender_id',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    // Relasi: Notifikasi dimiliki oleh satu User (penerima)
    public function user()
    {
        return $this->belongsTo(User::class);
    }

     // Relasi: Pengguna yang memicu notifikasi
    public function sender() // <--- TAMBAHKAN INI
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    // Relasi Polimorfik: Sumber notifikasi (bisa Post atau Comment)
    public function source() // <--- TAMBAHKAN INI
    {
        return $this->morphTo();
    }
}