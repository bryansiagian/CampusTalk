<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Post;
use App\Models\Comment;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    public function __construct()
    {
        // Middleware untuk memastikan hanya admin yang bisa mengakses ini
        $this->middleware('auth:sanctum');
        $this->middleware(function ($request, $next) {
            if (!auth()->user()->isAdmin()) {
                return response()->json(['message' => 'Akses ditolak. Hanya Admin yang bisa mengakses.'], 403);
            }
            return $next($request);
        });
    }

    public function dashboardStats()
    {
        // Menggunakan Aggregate Function
        $totalUsers = User::count();
        $totalPosts = Post::count();
        $totalComments = Comment::count();

        // Postingan Paling Populer (menggunakan view atau join dan aggregate)
        // Jika Anda sudah membuat view di PostgreSQL, bisa query langsung seperti ini:
        // $popularPosts = DB::table('popular_posts_view')->limit(5)->get();
        // Jika tidak, kita bisa buat query di Laravel:
        $popularPosts = Post::with(['author:id,name', 'category:id,name'])
                            ->withCount('likes', 'comments')
                            ->orderBy('likes_count', 'desc')
                            ->orderBy('comments_count', 'desc')
                            ->limit(5)
                            ->get();

        // Kategori dengan Postingan Terbanyak (menggunakan join dan aggregate)
        $topCategories = Category::withCount('posts')
                                ->orderBy('posts_count', 'desc')
                                ->limit(5)
                                ->get();

        return response()->json([
            'data' => [
                'total_users' => $totalUsers,
                'total_posts' => $totalPosts,
                'total_comments' => $totalComments,
                'popular_posts' => $popularPosts,
                'top_categories' => $topCategories,
            ]
        ]);
    }

    // Anda bisa menambahkan fungsi-fungsi admin lain di sini, misal:
    // public function manageUsers() { ... }
    // public function manageReports() { ... }
}