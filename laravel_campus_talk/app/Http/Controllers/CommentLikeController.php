<?php
namespace App\Http\Controllers;
use App\Models\CommentLike;
use App\Models\Comment;
use Illuminate\Http\Request;

class CommentLikeController extends Controller
{
    public function toggle($commentId)
    {
        $comment = Comment::find($commentId);
        if (!$comment) return response()->json(['message' => 'Komentar tidak ditemukan'], 404);

        $userId = auth()->id();
        $like = CommentLike::where('user_id', $userId)->where('comment_id', $commentId)->first();

        if ($like) {
            $like->delete(); // Trigger hapus notif jalan otomatis
            return response()->json(['liked' => false]);
        } else {
            CommentLike::create(['user_id' => $userId, 'comment_id' => $commentId]); // Trigger buat notif jalan
            return response()->json(['liked' => true]);
        }
    }
}