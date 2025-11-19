<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    use HasFactory;

    protected $fillable = [
        'reporter_id',
        'reported_post_id',
        'reported_comment_id',
        'reason',
        'status',
        'resolved_at',
        'resolved_by',
    ];

    protected $casts = [
        'resolved_at' => 'datetime',
    ];

    // Relasi: Laporan dibuat oleh satu User
    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    // Relasi: Laporan bisa menarget satu Post
    public function reportedPost()
    {
        return $this->belongsTo(Post::class, 'reported_post_id');
    }

    // Relasi: Laporan bisa menarget satu Comment
    public function reportedComment()
    {
        return $this->belongsTo(Comment::class, 'reported_comment_id');
    }

    // Relasi: Laporan diselesaikan oleh satu User (admin)
    public function resolver()
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }
}