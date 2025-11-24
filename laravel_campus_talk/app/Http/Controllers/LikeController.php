<?php

namespace App\Http\Controllers;

use App\Models\Like;
use App\Models\Post;
// Hapus import Notification karena sudah tidak dipakai manual
use Illuminate\Http\Request;

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
            // --- UNLIKE ---
            // Cukup delete saja. Trigger 'trigger_remove_notify_like' akan otomatis jalan.
            $like->delete();

            return response()->json(['message' => 'Unlike berhasil!', 'liked' => false]);
        } else {
            // --- LIKE ---
            // Cukup create saja. Trigger Insert (sebelumnya) akan otomatis jalan.
            Like::create([
                'user_id' => $userId,
                'post_id' => $postId,
            ]);

            return response()->json(['message' => 'Like berhasil!', 'liked' => true], 201);
        }
    }
}