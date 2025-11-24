<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // ---------------------------------------------------------
        // 1. TRIGGER UNTUK UNLIKE (Hapus Like -> Hapus Notifikasi)
        // ---------------------------------------------------------

        // Hapus dulu jika ada versi lama agar tidak konflik
        DB::statement("DROP TRIGGER IF EXISTS trigger_remove_notify_like ON public.likes;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_like_delete;");

        // Buat Function
        DB::statement("
            CREATE OR REPLACE FUNCTION public.after_like_delete()
            RETURNS TRIGGER AS $$
            BEGIN
                DELETE FROM notifications
                WHERE source_id = OLD.post_id
                AND source_type = 'App\\Models\\Post'
                AND sender_id = OLD.user_id
                AND type = 'like_post';

                RETURN OLD;
            END;
            $$ LANGUAGE plpgsql;
        ");

        // Pasang Trigger
        DB::statement("
            CREATE TRIGGER trigger_remove_notify_like
            AFTER DELETE ON public.likes
            FOR EACH ROW
            EXECUTE FUNCTION public.after_like_delete();
        ");

        // ---------------------------------------------------------
        // 2. TRIGGER UNTUK HAPUS KOMENTAR (Hapus Comment -> Hapus Notifikasi)
        // ---------------------------------------------------------

        // Hapus dulu jika ada versi lama
        DB::statement("DROP TRIGGER IF EXISTS trigger_remove_notify_comment ON public.comments;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_comment_delete;");

        // Buat Function
        DB::statement("
            CREATE OR REPLACE FUNCTION public.after_comment_delete()
            RETURNS TRIGGER AS $$
            BEGIN
                -- A. Hapus notifikasi 'comment_post' (yang dikirim ke pemilik Post)
                -- Kita tambahkan filter waktu (created_at) agar spesifik menghapus
                -- notifikasi milik komentar INI saja (jika user komen berkali-kali).
                DELETE FROM notifications
                WHERE source_id = OLD.post_id
                AND source_type = 'App\\Models\\Post'
                AND type = 'comment_post'
                AND sender_id = OLD.user_id
                AND created_at >= OLD.created_at - interval '2 seconds'
                AND created_at <= OLD.created_at + interval '2 seconds';

                -- B. Hapus notifikasi 'reply_comment' (jika ini adalah balasan)
                IF OLD.parent_comment_id IS NOT NULL THEN
                    DELETE FROM notifications
                    WHERE source_id = OLD.parent_comment_id
                    AND source_type = 'App\\Models\\Comment'
                    AND type = 'reply_comment'
                    AND sender_id = OLD.user_id;
                END IF;

                RETURN OLD;
            END;
            $$ LANGUAGE plpgsql;
        ");

        // Pasang Trigger
        DB::statement("
            CREATE TRIGGER trigger_remove_notify_comment
            AFTER DELETE ON public.comments
            FOR EACH ROW
            EXECUTE FUNCTION public.after_comment_delete();
        ");
    }

    public function down(): void
    {
        // Hapus semua trigger dan function saat rollback
        DB::statement("DROP TRIGGER IF EXISTS trigger_remove_notify_like ON public.likes;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_like_delete;");

        DB::statement("DROP TRIGGER IF EXISTS trigger_remove_notify_comment ON public.comments;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_comment_delete;");
    }
};