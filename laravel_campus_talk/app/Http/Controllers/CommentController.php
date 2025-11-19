<?php

namespace App\Http\Controllers;

use App\Models\Comment;
use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class CommentController extends Controller
{
    public function index($postId)
    {
        $post = Post::find($postId);

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan'], 404);
        }

        // Ambil komentar utama (parent_comment_id is NULL) beserta balasan dan penulisnya
        $comments = $post->comments()
                        ->whereNull('parent_comment_id')
                        ->with(['author', 'replies']) // Memuat balasan secara rekursif
                        ->orderBy('created_at', 'asc')
                        ->get();

        return response()->json(['data' => $comments]);
    }

    public function store(Request $request, $postId)
    {
        $post = Post::find($postId);

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan'], 404);
        }

        $request->validate([
            'content' => 'required|string',
            'parent_comment_id' => 'nullable|exists:comments,id',
        ]);

        $comment = Comment::create([
            'user_id' => auth()->id(),
            'post_id' => $postId,
            'parent_comment_id' => $request->parent_comment_id,
            'content' => $request->content,
        ]);

        // Trigger di PostgreSQL akan menangani notifikasi otomatis
        // Jika Anda ingin notifikasi real-time di Laravel, Anda bisa menggunakan Event dan Listener di sini

        return response()->json([
            'message' => 'Komentar berhasil ditambahkan!',
            'data' => $comment->load('author') // Load author untuk respons
        ], 201);
    }

    // Anda bisa menambahkan update dan destroy untuk komentar jika diinginkan
}