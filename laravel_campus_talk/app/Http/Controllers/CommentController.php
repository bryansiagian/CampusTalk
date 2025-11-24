<?php

namespace App\Http\Controllers;

use App\Models\Comment;
use App\Models\CommentDetail;
use App\Models\Post;
use App\Models\Notification; // <--- Import Model Notification
use Illuminate\Http\Request;
use Illuminate\Support\Str; // <--- Untuk Str::limit
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CommentController extends Controller
{
    public function index($postId)
    {
        $post = Post::find($postId);

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan'], 404);
        }

        $comments = $post->comments()
                        ->whereNull('parent_comment_id')
                        ->with(['author.role', 'replies.author.role']) // Muat role untuk penulis komentar dan balasan
                        ->orderBy('created_at', 'asc')
                        ->get();

        return response()->json(['data' => $comments]);
    }

    public function store(Request $request, $postId)
    {
        // 1. Cek Postingan
        $post = Post::find($postId);

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan'], 404);
        }

        // 2. Validasi
        $request->validate([
            'content' => 'required|string',
            'parent_comment_id' => 'nullable|exists:comments,id',
        ]);

        // 3. Simpan Komentar
        // PERBAIKAN: Gunakan auth()->id() langsung, jangan pakai $commenterUser->id
        $comment = Comment::create([
            'user_id' => auth()->id(), // <--- Pakai ini agar tidak error Undefined variable
            'post_id' => $postId,
            'parent_comment_id' => $request->parent_comment_id,
            'content' => $request->content,
        ]);

        return response()->json([
            'message' => 'Komentar berhasil ditambahkan!',
            'data' => $comment->load('author.role')
        ], 201);
    }

    public function destroy($id)
    {
        $comment = \App\Models\Comment::find($id);

        if (!$comment) {
            return response()->json(['message' => 'Komentar tidak ditemukan'], 404);
        }

        // Logika: Boleh hapus jika (Milik Sendiri) ATAU (User adalah Admin)
        if ($comment->user_id != auth()->id() && !auth()->user()->isAdmin()) {
            return response()->json(['message' => 'Anda tidak berhak menghapus komentar ini'], 403);
        }

        $comment->delete();

        return response()->json(['message' => 'Komentar berhasil dihapus']);
    }

    public function getCommentDetails(Request $request)
    {
        $query = CommentDetail::query();

        // UBAH FILTER: Gunakan post_id agar spesifik ke postingan ini
        if ($request->has('post_id') && $request->post_id != null) {
            $query->where('post_id', $request->post_id);
        }

        // Filter search author (opsional)
        if ($request->has('author_name') && $request->author_name != null) {
            $query->where('commenter_name', 'ILIKE', '%' . $request->author_name . '%');
        }

        // Sorting
        $query->orderBy('comment_created_at', 'asc'); // Default urut dari lama ke baru (logis untuk chat)

        $commentsWithDetails = $query->paginate(100);

        return response()->json(['data' => $commentsWithDetails]);
    }
}