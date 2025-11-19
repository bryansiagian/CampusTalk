<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\CommentController;
use App\Http\Controllers\LikeController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\TagController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\AdminController;
use App\Models\User; // Tambahkan ini

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Rute Publik (tidak perlu login)
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login'])->name('login');

// Kategori & Tag
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/tags', [TagController::class, 'index']);

// Rute yang Dilindungi (membutuhkan token Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    // --- Rute Baru untuk Profil Pengguna ---
    // Route untuk mendapatkan informasi user yang sedang login
    Route::get('/user', function (Request $request) {
        // Memastikan data role di-load bersama user
        // Asumsi relasi 'role' (singular) ada di model User
        // Jika relasi Anda bernama 'roles' (plural), ganti 'role' menjadi 'roles'
        return $request->user()->load('role');
    });

    // Route untuk mendapatkan postingan yang dibuat oleh user tertentu
    // {user} akan otomatis di-resolve ke instance App\Models\User berdasarkan ID
    Route::get('/users/{user}/posts', function (User $user) {
        // Memuat relasi author, category, dan tags untuk setiap postingan
        return response()->json(['data' => $user->posts()->with(['author', 'category', 'tags'])->get()]);
    });
    // --- Akhir Rute Baru ---


    // Postingan
    Route::get('/posts', [PostController::class, 'index']);
    Route::get('/posts/{id}', [PostController::class, 'show']);
    Route::post('/posts', [PostController::class, 'store']);
    Route::put('/posts/{id}', [PostController::class, 'update']);
    Route::delete('/posts/{id}', [PostController::class, 'destroy']);

    // Komentar
    Route::get('/posts/{postId}/comments', [CommentController::class, 'index']);
    Route::post('/posts/{postId}/comments', [CommentController::class, 'store']);

    // Like
    Route::post('/posts/{postId}/likes', [LikeController::class, 'togglePostLike']);
    Route::delete('/posts/{postId}/likes', [LikeController::class, 'togglePostLike']);

    // Notifikasi
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

    // Admin (menggunakan AdminController dengan middleware isAdmin)
    Route::get('/admin/dashboard-stats', [AdminController::class, 'dashboardStats']);
});