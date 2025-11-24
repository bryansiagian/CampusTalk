<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Buat Function Logika Trigger
        DB::statement("
            CREATE OR REPLACE FUNCTION public.after_like_insert()
            RETURNS TRIGGER AS $$
            DECLARE
                post_owner_id INT;
                post_title_text VARCHAR(255);
                liker_name VARCHAR(255);
            BEGIN
                -- Ambil info Postingan (Pemilik & Judul)
                SELECT user_id, title INTO post_owner_id, post_title_text
                FROM posts WHERE id = NEW.post_id;

                -- Ambil Nama Orang yang Like
                SELECT name INTO liker_name
                FROM users WHERE id = NEW.user_id;

                -- LOGIKA: Hanya buat notif jika yang like BUKAN pemilik postingan
                IF post_owner_id != NEW.user_id THEN
                    INSERT INTO notifications (
                        user_id,       -- Penerima (Pemilik Post)
                        type,          -- Tipe Notif
                        message,       -- Pesan
                        source_id,     -- ID Sumber (Post ID)
                        source_type,   -- Model Sumber
                        sender_id,     -- Pengirim (Yang Like)
                        is_read,
                        created_at,
                        updated_at
                    ) VALUES (
                        post_owner_id,
                        'like_post',   -- Kita namakan tipenya 'like_post'
                        liker_name || ' menyukai postingan Anda: ' || SUBSTRING(post_title_text, 1, 20) || '...',
                        NEW.post_id,
                        'App\\Models\\Post',
                        NEW.user_id,
                        FALSE,
                        NOW(),
                        NOW()
                    );
                END IF;

                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        ");

        // 2. Pasang Trigger ke Tabel Likes
        // Asumsi nama tabel Anda adalah 'likes' (sesuaikan jika namanya 'post_likes')
        DB::statement("
            CREATE TRIGGER trigger_notify_like
            AFTER INSERT ON public.likes
            FOR EACH ROW
            EXECUTE FUNCTION public.after_like_insert();
        ");
    }

    public function down(): void
    {
        DB::statement("DROP TRIGGER IF EXISTS trigger_notify_like ON public.likes;");
        DB::statement("DROP FUNCTION IF EXISTS public.after_like_insert;");
    }
};