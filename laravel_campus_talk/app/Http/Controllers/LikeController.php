<?php

namespace App\Http\Controllers;

use App\Models\Like;
use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class LikeController extends Controller
{
    public function togglePostLike($postId)
    {
        $post = Post::find($postId);

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan'], 404);
        }

        $userId = auth()->id();

        $like = Like::where('user_id', $userId)
                    ->where('post_id', $postId)
                    ->first();

        if ($like) {
            // Sudah like, hapus like-nya (unlike)
            $like->delete();
            return response()->json(['message' => 'Unlike berhasil!', 'liked' => false]);
        } else {
            // Belum like, tambahkan like
            Like::create([
                'user_id' => $userId,
                'post_id' => $postId,
            ]);
            return response()->json(['message' => 'Like berhasil!', 'liked' => true], 201);
        }
    }

    // Anda bisa membuat fungsi toggleLike untuk komentar juga jika diinginkan
    // public function toggleCommentLike($commentId) { ... }
}