<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Buat Function (Logika Trigger)
        DB::statement("
            CREATE OR REPLACE FUNCTION public.after_comment_insert()
            RETURNS TRIGGER AS $$
            DECLARE
                post_owner_id INT;
                parent_comment_owner_id INT;
                post_title_text VARCHAR(255);
                commenter_name VARCHAR(255);
            BEGIN
                -- Ambil Judul Postingan dan ID Pemilik Postingan
                SELECT user_id, title INTO post_owner_id, post_title_text
                FROM posts WHERE id = NEW.post_id;

                -- Ambil Nama Pengomentar
                SELECT name INTO commenter_name
                FROM users WHERE id = NEW.user_id;

                -- SKENARIO 1: Notifikasi Komentar Postingan
                -- Syarat: Yang komen BUKAN pemilik postingan itu sendiri
                IF post_owner_id != NEW.user_id THEN
                    INSERT INTO notifications (
                        user_id, type, message, source_id, source_type, sender_id, is_read, created_at, updated_at
                    ) VALUES (
                        post_owner_id,
                        'comment_post',
                        commenter_name || ' mengomentari postingan Anda: ' || SUBSTRING(post_title_text, 1, 20) || '...',
                        NEW.post_id,
                        'App\\Models\\Post',
                        NEW.user_id,
                        FALSE,
                        NOW(),
                        NOW()
                    );
                END IF;

                -- SKENARIO 2: Notifikasi Balasan Komentar
                -- Syarat: Ada parent_comment_id (artinya ini balasan)
                IF NEW.parent_comment_id IS NOT NULL THEN
                    SELECT user_id INTO parent_comment_owner_id
                    FROM comments WHERE id = NEW.parent_comment_id;

                    -- Syarat: Yang membalas BUKAN pemilik komentar asli
                    IF parent_comment_owner_id != NEW.user_id THEN
                        INSERT INTO notifications (
                            user_id, type, message, source_id, source_type, sender_id, is_read, created_at, updated_at
                        ) VALUES (
                            parent_comment_owner_id,
                            'reply_comment',
                            commenter_name || ' membalas komentar Anda di: ' || SUBSTRING(post_title_text, 1, 20) || '...',
                            NEW.parent_comment_id,
                            'App\\Models\\Comment',
                            NEW.user_id,
                            FALSE,
                            NOW(),
                            NOW()
                        );
                    END IF;
                END IF;

                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        ");

        // 2. Pasang Trigger ke Tabel Comments
        DB::statement("
            CREATE TRIGGER trigger_notify_comment
            AFTER INSERT ON public.comments
            FOR EACH ROW
            EXECUTE FUNCTION public.after_comment_insert();
        ");
    }

    public function down(): void
    {
        // Hapus Trigger dan Function jika rollback
        DB::statement("DROP TRIGGER IF EXISTS trigger_notify_comment ON public.comments;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_comment_insert;");
    }
};