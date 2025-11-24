<?php
namespace App\Http\Controllers;
use App\Models\Report;
use App\Models\Post;
use App\Models\Comment;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'reason' => 'required|string',
            'type' => 'required|in:post,comment', // Tipe apa yang dilaporin
            'id' => 'required|integer'
        ]);

        $modelType = $request->type === 'post' ? Post::class : Comment::class;

        // Cek validitas ID
        if (!$modelType::where('id', $request->id)->exists()) {
             return response()->json(['message' => 'Konten tidak ditemukan'], 404);
        }

        Report::create([
            'user_id' => auth()->id(),
            'reason' => $request->reason,
            'reportable_id' => $request->id,
            'reportable_type' => $modelType,
        ]);

        return response()->json(['message' => 'Laporan berhasil dikirim. Admin akan meninjau.']);
    }
}