<?php

namespace App\Http\Controllers;

use App\Models\Post;
use App\Models\Category; // Import Category
use App\Models\Tag;      // Import Tag
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB; // Untuk transaksi
use Illuminate\Validation\ValidationException;

class PostController extends Controller
{
    public function index(Request $request)
    {
        $query = Post::with(['author:id,name,email', 'category:id,name', 'tags:id,name'])
                    ->withCount('likes', 'comments'); // Hitung total likes dan comments

        // Filter berdasarkan kategori
        if ($request->has('category_id') && $request->category_id != null) {
            $query->where('category_id', $request->category_id);
        }

        // Pencarian berdasarkan judul atau konten
        if ($request->has('search') && $request->search != null) {
            $searchTerm = '%' . $request->search . '%';
            $query->where(function($q) use ($searchTerm) {
                $q->where('title', 'like', $searchTerm)
                  ->orWhere('content', 'like', $searchTerm);
            });
        }

        // Sorting
        if ($request->has('sort_by')) {
            switch ($request->sort_by) {
                case 'latest':
                    $query->orderBy('created_at', 'desc');
                    break;
                case 'oldest':
                    $query->orderBy('created_at', 'asc');
                    break;
                case 'popular':
                    // Menggunakan WITHCOUNT di atas
                    $query->orderBy('likes_count', 'desc')
                          ->orderBy('comments_count', 'desc');
                    break;
                default:
                    $query->orderBy('created_at', 'desc');
                    break;
            }
        } else {
            $query->orderBy('created_at', 'desc');
        }

        $posts = $query->paginate(10); // Paginate untuk performa

        return response()->json(['data' => $posts]);
    }

    public function show($id)
    {
        $post = Post::with(['author.role', 'category', 'tags'])
                    ->withCount('likes', 'comments')
                    ->find($id);

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan'], 404);
        }

        // Menambahkan informasi apakah user saat ini sudah like postingan ini
        $post->is_liked_by_current_user = $post->likes()->where('user_id', auth()->id())->exists();

        return response()->json(['data' => $post]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'category_id' => 'required|exists:categories,id',
            'tags' => 'array',
            'tags.*' => 'exists:tags,id',
        ]);

        // Menggunakan transaksi untuk memastikan post dan tags tersimpan bersamaan
        try {
            return DB::transaction(function () use ($request) {
                $post = Post::create([
                    'user_id' => auth()->id(), // Ambil ID user yang sedang login
                    'category_id' => $request->category_id,
                    'title' => $request->title,
                    'content' => $request->content,
                ]);

                if ($request->has('tags')) {
                    $post->tags()->attach($request->tags); // Menghubungkan tags
                }

                return response()->json([
                    'message' => 'Postingan berhasil dibuat!',
                    'data' => $post->load(['author', 'category', 'tags']) // Load relasi untuk respons
                ], 201);
            });
        } catch (\Exception $e) {
            throw ValidationException::withMessages([
                'error' => ['Gagal membuat postingan: ' . $e->getMessage()],
            ]);
        }
    }

    public function update(Request $request, $id)
    {
        $post = Post::where('user_id', auth()->id())->find($id); // Hanya bisa update postingan sendiri

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan atau Anda tidak memiliki izin.'], 404);
        }

        $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'category_id' => 'required|exists:categories,id',
            'tags' => 'array',
            'tags.*' => 'exists:tags,id',
        ]);

        try {
            return DB::transaction(function () use ($request, $post) {
                $post->update([
                    'title' => $request->title,
                    'content' => $request->content,
                    'category_id' => $request->category_id,
                ]);

                if ($request->has('tags')) {
                    $post->tags()->sync($request->tags); // Sync tags (add/remove sesuai array baru)
                } else {
                    $post->tags()->detach(); // Hapus semua tags jika tidak ada yang dikirim
                }

                return response()->json([
                    'message' => 'Postingan berhasil diperbarui!',
                    'data' => $post->load(['author', 'category', 'tags'])
                ]);
            });
        } catch (\Exception $e) {
            throw ValidationException::withMessages([
                'error' => ['Gagal memperbarui postingan: ' . $e->getMessage()],
            ]);
        }
    }

    public function destroy($id)
    {
        $post = Post::where('user_id', auth()->id())->find($id); // Hanya bisa hapus postingan sendiri

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan atau Anda tidak memiliki izin.'], 404);
        }

        $post->delete();

        return response()->json(['message' => 'Postingan berhasil dihapus!']);
    }
}