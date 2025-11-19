<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Like extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'post_id',
        'comment_id',
    ];

    // Relasi: Like dimiliki oleh satu User
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Relasi: Like bisa untuk satu Post
    public function post()
    {
        return $this->belongsTo(Post::class);
    }

    // Relasi: Like bisa untuk satu Comment
    public function comment()
    {
        return $this->belongsTo(Comment::class);
    }
}