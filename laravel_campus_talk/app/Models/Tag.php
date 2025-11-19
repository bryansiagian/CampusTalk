<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tag extends Model
{
    use HasFactory;

    protected $fillable = [
        'name'
    ];

    // Relasi: Tag dimiliki oleh banyak Postingan (Many-to-Many)
    public function posts()
    {
        return $this->belongsToMany(Post::class, 'post_tags'); // 'post_tags' adalah tabel pivot
    }
}