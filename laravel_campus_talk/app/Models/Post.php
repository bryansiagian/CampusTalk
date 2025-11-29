<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'category_id',
        'title',
        'content',
        'media_path', // <--- Tambahkan
        'media_type',
        'views',
    ];

    // Relasi: Post dimiliki oleh satu User (penulis)
    public function author()
    {
        return $this->belongsTo(User::class, 'user_id'); // 'user_id' adalah foreign key
    }

    // Relasi: Post dimiliki oleh satu Category
    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    // Relasi: Post memiliki banyak Komentar
    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    // Relasi: Post memiliki banyak Like
    public function likes()
    {
        return $this->hasMany(Like::class);
    }

    // Relasi: Post memiliki banyak Tag (Many-to-Many)
    public function tags()
    {
        return $this->belongsToMany(Tag::class, 'post_tags');
    }

    // Helper untuk mendapatkan jumlah like
    public function totalLikes()
    {
        return $this->likes()->count();
    }

    // Helper untuk mendapatkan jumlah komentar
    public function totalComments()
    {
        return $this->comments()->count();
    }

    public function getMediaUrlAttribute()
    {
        if ($this->media_path) {
            return asset('storage/' . $this->media_path);
        }
        return null;
    }

    protected $appends = ['media_url'];
}