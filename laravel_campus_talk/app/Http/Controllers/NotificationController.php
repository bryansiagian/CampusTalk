<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Notification;
use App\Models\Post;
use App\Models\Comment;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = $request->user()->notifications()
                                ->with(['sender.role', 'source'])
                                ->orderBy('created_at', 'desc')
                                ->paginate(20);

        $transformedNotifications = $notifications->getCollection()->map(function ($notification) {
            $relatedPostData = null;
            $senderData = $notification->sender ? $notification->sender->load('role') : null;

            // --- LOGIKA BARU ---

            // 1. Jika tipe notifikasi Like (Source: Post)
            if ($notification->source_type === Post::class && $notification->source) {
                $relatedPostData = $notification->source->load(['author.role', 'category', 'tags']);
            }

            // 2. Jika tipe notifikasi Komentar/Balasan (Source: Comment)
            // Karena trigger baru menyimpan Comment sebagai source untuk kedua tipe ini.
            elseif ($notification->source_type === Comment::class && $notification->source) {
                // Ambil post induk dari komentar tersebut
                if ($notification->source->post) {
                    $relatedPostData = $notification->source->post->load(['author.role', 'category', 'tags']);
                }
            }

            return [
                'id' => $notification->id,
                'type' => $notification->type,
                'message' => $notification->message,
                'is_read' => (bool) $notification->is_read,
                'created_at' => $notification->created_at,
                'sender' => $senderData,
                'related_post' => $relatedPostData,
            ];
        });

        return response()->json([
            'data' => $transformedNotifications,
            'meta' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'total' => $notifications->total(),
            ]
        ]);
    }

    public function getUnreadNotificationCount(Request $request)
    {
        $count = $request->user()->notifications()->where('is_read', false)->count();
        return response()->json(['count' => $count]);
    }

    public function markAsRead(Request $request, $id)
    {
        $notification = $request->user()->notifications()->where('id', $id)->first();

        if ($notification) {
            $notification->update(['is_read' => true]);
            return response()->json(['message' => 'Notifikasi ditandai sudah dibaca.']);
        }

        return response()->json(['message' => 'Notifikasi tidak ditemukan.'], 404);
    }

    public function markAllAsRead(Request $request)
    {
        $request->user()->notifications()->where('is_read', false)->update(['is_read' => true]);
        return response()->json(['message' => 'Semua notifikasi ditandai sudah dibaca.']);
    }
}