<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Comment extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'post_id',
        'parent_comment_id',
        'content',
    ];

    // Relasi: Comment dimiliki oleh satu User (penulis komentar)
    public function author()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    // Relasi: Comment dimiliki oleh satu Post
    public function post()
    {
        return $this->belongsTo(Post::class);
    }

    // Relasi: Comment bisa memiliki komentar induk (parent)
    public function parent()
    {
        return $this->belongsTo(Comment::class, 'parent_comment_id');
    }

    // Relasi: Comment bisa memiliki banyak balasan (replies)
    public function replies()
    {
        return $this->hasMany(Comment::class, 'parent_comment_id')->with('author', 'replies'); // Dengan eager loading rekursif
    }
}