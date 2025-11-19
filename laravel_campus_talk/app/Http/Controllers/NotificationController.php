<?php

namespace App\Http\Controllers;

use App\Models\Notification; // Pastikan nama modelnya Notification, bukan AppNotification
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index()
    {
        $userId = auth()->id();
        $notifications = Notification::where('user_id', $userId)
                                    ->orderBy('created_at', 'desc')
                                    ->paginate(10); // Paginate untuk performa

        return response()->json(['data' => $notifications]);
    }

    public function markAsRead($id)
    {
        $notification = Notification::where('user_id', auth()->id())->find($id);

        if (!$notification) {
            return response()->json(['message' => 'Notifikasi tidak ditemukan'], 404);
        }

        $notification->update(['is_read' => true]);

        return response()->json(['message' => 'Notifikasi ditandai sudah dibaca!']);
    }

    // Anda bisa membuat endpoint untuk menandai semua notifikasi sudah dibaca
    public function markAllAsRead()
    {
        Notification::where('user_id', auth()->id())->update(['is_read' => true]);
        return response()->json(['message' => 'Semua notifikasi ditandai sudah dibaca!']);
    }
}