<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // =========================================================
        // 1. UPDATE TRIGGER INSERT (Menyimpan ID Komentar sebagai Source)
        // =========================================================

        DB::statement("DROP TRIGGER IF EXISTS trigger_notify_comment ON public.comments;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_comment_insert;");

        DB::statement("
            CREATE OR REPLACE FUNCTION public.after_comment_insert()
            RETURNS TRIGGER AS $$
            DECLARE
                post_owner_id INT;
                parent_comment_owner_id INT;
                post_title_text VARCHAR(255);
                commenter_name VARCHAR(255);
            BEGIN
                SELECT user_id, title INTO post_owner_id, post_title_text FROM posts WHERE id = NEW.post_id;
                SELECT name INTO commenter_name FROM users WHERE id = NEW.user_id;

                -- STRATEGI BARU:
                -- source_id = NEW.id (ID Komentar yang baru dibuat)
                -- source_type = 'App\\Models\\Comment' (Selalu Comment, bukan Post)

                -- 1. Notif untuk Pemilik Post
                IF post_owner_id != NEW.user_id THEN
                    INSERT INTO notifications (
                        user_id, type, message, source_id, source_type, sender_id, is_read, created_at, updated_at
                    ) VALUES (
                        post_owner_id,
                        'comment_post',
                        commenter_name || ' mengomentari postingan Anda: ' || SUBSTRING(post_title_text, 1, 20) || '...',
                        NEW.id, -- <--- PENTING: Gunakan ID Komentar
                        'App\\Models\\Comment', -- <--- PENTING: Tipenya Comment
                        NEW.user_id, FALSE, NOW(), NOW()
                    );
                END IF;

                -- 2. Notif untuk Pemilik Komentar Induk (Balasan)
                IF NEW.parent_comment_id IS NOT NULL THEN
                    SELECT user_id INTO parent_comment_owner_id FROM comments WHERE id = NEW.parent_comment_id;

                    IF parent_comment_owner_id != NEW.user_id THEN
                        INSERT INTO notifications (
                            user_id, type, message, source_id, source_type, sender_id, is_read, created_at, updated_at
                        ) VALUES (
                            parent_comment_owner_id,
                            'reply_comment',
                            commenter_name || ' membalas komentar Anda di: ' || SUBSTRING(post_title_text, 1, 20) || '...',
                            NEW.id, -- <--- Gunakan ID Komentar Balasan (diri sendiri)
                            'App\\Models\\Comment',
                            NEW.user_id, FALSE, NOW(), NOW()
                        );
                    END IF;
                END IF;

                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        ");

        DB::statement("
            CREATE TRIGGER trigger_notify_comment
            AFTER INSERT ON public.comments
            FOR EACH ROW EXECUTE FUNCTION public.after_comment_insert();
        ");

        // =========================================================
        // 2. UPDATE TRIGGER DELETE (Hapus berdasarkan ID Komentar)
        // =========================================================

        DB::statement("DROP TRIGGER IF EXISTS trigger_remove_notify_comment ON public.comments;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_comment_delete;");

        DB::statement("
            CREATE OR REPLACE FUNCTION public.after_comment_delete()
            RETURNS TRIGGER AS $$
            BEGIN
                -- SANGAT SIMPEL & AKURAT:
                -- Hapus notifikasi yang bersumber dari ID Komentar yang dihapus ini.
                -- Karena saat insert kita pakai NEW.id, sekarang kita hapus pakai OLD.id

                DELETE FROM notifications
                WHERE source_id = OLD.id
                AND source_type = 'App\\Models\\Comment';

                RETURN OLD;
            END;
            $$ LANGUAGE plpgsql;
        ");

        DB::statement("
            CREATE TRIGGER trigger_remove_notify_comment
            AFTER DELETE ON public.comments
            FOR EACH ROW EXECUTE FUNCTION public.after_comment_delete();
        ");
    }

    public function down(): void
    {
        DB::statement("DROP TRIGGER IF EXISTS trigger_notify_comment ON public.comments;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_comment_insert;");
        DB::statement("DROP TRIGGER IF EXISTS trigger_remove_notify_comment ON public.comments;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_comment_delete;");
    }
};