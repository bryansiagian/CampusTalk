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
                    ->withCount('likes', 'comments');

        // 1. Filter Kategori (Existing)
        if ($request->has('category_id') && $request->category_id != null) {
            $query->where('category_id', $request->category_id);
        }

        // 2. Search Judul/Konten (Existing)
        if ($request->has('search') && $request->search != null) {
            $searchTerm = '%' . $request->search . '%';
            $query->where(function($q) use ($searchTerm) {
                $q->where('title', 'ILIKE', $searchTerm)
                  ->orWhere('content', 'ILIKE', $searchTerm);
            });
        }

        // 3. FITUR BARU: Search by TAG
        if ($request->has('tag') && $request->tag != null) {
            // Cari postingan yang punya tag dengan nama mirip inputan
            $tagSearch = '%' . $request->tag . '%';
            $query->whereHas('tags', function($q) use ($tagSearch) {
                $q->where('name', 'ILIKE', $tagSearch);
            });
        }

        // Sorting (Existing)
        if ($request->has('sort_by')) {
            switch ($request->sort_by) {
                case 'latest': $query->orderBy('created_at', 'desc'); break;
                case 'oldest': $query->orderBy('created_at', 'asc'); break;
                case 'popular': $query->orderBy('likes_count', 'desc'); break;
                default: $query->orderBy('created_at', 'desc'); break;
            }
        } else {
            $query->orderBy('created_at', 'desc');
        }

        $posts = $query->paginate(10);
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

        // --- Panggil Fungsi (Stored Procedure) dari PostgreSQL ---
        // Kita menggunakan DB::selectOne() untuk mengeksekusi fungsi dan mendapatkan satu baris hasil.
        // Tanda '?' akan diganti dengan nilai dari array kedua.
        $result = DB::selectOne("SELECT public.get_post_total_likes(?) AS total_likes_from_function", [$post->id]);
        $totalLikesFromFunction = $result->total_likes_from_function ?? 0; // Ambil hasilnya, default 0 jika null
        // ------------------------------------------------------------------

        $post->is_liked_by_current_user = $post->likes()->where('user_id', auth()->id())->exists();
        $post->total_likes_via_function = (int) $totalLikesFromFunction; // Tambahkan ke objek Post untuk respons

        // Konversi model Post ke array terlebih dahulu
        // (Ini sudah tidak diperlukan jika langsung memodifikasi objek $post seperti di atas)
        $postData = $post->toArray();

        return response()->json(['data' => $postData]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'category_id' => 'required|exists:categories,id',
            // Ubah validasi tags: Boleh array, isinya string (nama tag)
            'tags' => 'nullable|string', // Format: "flutter, laravel, code"
        ]);

        try {
            return DB::transaction(function () use ($request) {
                $post = Post::create([
                    'user_id' => auth()->id(),
                    'category_id' => $request->category_id,
                    'title' => $request->title,
                    'content' => $request->content,
                ]);

                // LOGIKA BARU: Handle Tags Dinamis
                if ($request->has('tags') && $request->tags != null) {
                    // 1. Pecah string berdasarkan koma (misal: "php, laravel" -> ["php", "laravel"])
                    $tagNames = explode(',', $request->tags);
                    $tagIds = [];

                    foreach ($tagNames as $name) {
                        $name = trim($name); // Hapus spasi di awal/akhir
                        if (!empty($name)) {
                            // 2. Cari Tag, kalau tidak ada BUAT BARU (firstOrCreate)
                            $tag = Tag::firstOrCreate(['name' => $name]);
                            $tagIds[] = $tag->id;
                        }
                    }

                    // 3. Hubungkan Tag ke Post
                    $post->tags()->sync($tagIds);
                }

                return response()->json([
                    'message' => 'Postingan berhasil dibuat!',
                    'data' => $post->load(['author', 'category', 'tags'])
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
        // 1. Cari Postingan
        $post = Post::find($id);

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan.'], 404);
        }

        // 2. Cek Kepemilikan (Hanya pemilik yang boleh edit)
        if ($post->user_id != auth()->id()) {
            return response()->json(['message' => 'Anda tidak memiliki izin.'], 403);
        }

        // 3. Validasi
        $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'category_id' => 'required|exists:categories,id',
            'tags' => 'nullable|string', // Format string koma
        ]);

        try {
            return DB::transaction(function () use ($request, $post) {
                // 4. Update Data Utama
                $post->update([
                    'title' => $request->title,
                    'content' => $request->content,
                    'category_id' => $request->category_id,
                ]);

                // 5. Update Tags (Sinkronisasi)
                if ($request->has('tags')) {
                    $tagNames = explode(',', $request->tags);
                    $tagIds = [];

                    foreach ($tagNames as $name) {
                        $name = trim($name);
                        if (!empty($name)) {
                            // Cari atau Buat Tag baru
                            $tag = \App\Models\Tag::firstOrCreate(['name' => $name]);
                            $tagIds[] = $tag->id;
                        }
                    }
                    // Sync: Hapus tag lama, masukkan tag baru
                    $post->tags()->sync($tagIds);
                } else {
                    // Jika tags dikosongkan
                    $post->tags()->detach();
                }

                return response()->json([
                    'message' => 'Postingan berhasil diperbarui!',
                    'data' => $post->load(['author', 'category', 'tags'])
                ]);
            });
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal update: ' . $e->getMessage()], 500);
        }
    }

    public function destroy($id)
    {
        // 1. Cari Postingan tanpa membatasi pemiliknya dulu
        $post = Post::find($id);

        if (!$post) {
            return response()->json(['message' => 'Postingan tidak ditemukan'], 404);
        }

        // 2. Cek Hak Akses: Boleh hapus jika (Milik Sendiri) ATAU (User adalah Admin)
        // Pastikan Anda sudah menambahkan fungsi isAdmin() di model User Laravel
        if ($post->user_id != auth()->id() && !auth()->user()->isAdmin()) {
            return response()->json(['message' => 'Anda tidak memiliki izin menghapus postingan ini.'], 403);
        }

        $post->delete();

        return response()->json(['message' => 'Postingan berhasil dihapus!']);
    }
}