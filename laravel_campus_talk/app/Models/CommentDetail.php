<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CommentDetail extends Model
{
    use HasFactory;

    // Nama tabel/view di database
    protected $table = 'comment_details_view';

    // Kunci utama untuk view ini (berdasarkan alias di view)
    protected $primaryKey = 'comment_id';

    // View biasanya tidak memiliki auto-incrementing ID
    public $incrementing = false;

    // View biasanya tidak memiliki timestamps 'created_at' dan 'updated_at'
    // (kecuali Anda secara eksplisit memilihnya di view)
    public $timestamps = false;

    // Kolom yang bisa diisi (jika Anda berencana melakukan insert/update via model ini,
    // yang jarang dilakukan untuk view, tetapi baik untuk didefinisikan)
    protected $fillable = [
        'comment_id',
        'comment_content',
        'commenter_name',
        'post_title',
        'comment_created_at',
    ];
}