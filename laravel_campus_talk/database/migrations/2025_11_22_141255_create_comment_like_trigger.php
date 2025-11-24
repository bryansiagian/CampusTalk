<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement("
            CREATE OR REPLACE FUNCTION public.after_comment_like_insert()
            RETURNS TRIGGER AS $$
            DECLARE
                comment_owner_id INT;
                comment_content_preview VARCHAR(255);
                liker_name VARCHAR(255);
            BEGIN
                -- Ambil Info
                SELECT user_id, content INTO comment_owner_id, comment_content_preview FROM comments WHERE id = NEW.comment_id;
                SELECT name INTO liker_name FROM users WHERE id = NEW.user_id;

                -- Buat Notif jika yang like bukan pemilik komentar
                IF comment_owner_id != NEW.user_id THEN
                    INSERT INTO notifications (
                        user_id, type, message, source_id, source_type, sender_id, is_read, created_at, updated_at
                    ) VALUES (
                        comment_owner_id,
                        'like_comment',
                        liker_name || ' menyukai komentar Anda: ' || SUBSTRING(comment_content_preview, 1, 20) || '...',
                        NEW.comment_id,
                        'App\\Models\\Comment',
                        NEW.user_id, FALSE, NOW(), NOW()
                    );
                END IF;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        ");

        DB::statement("
            CREATE TRIGGER trigger_notify_comment_like
            AFTER INSERT ON public.comment_likes
            FOR EACH ROW EXECUTE FUNCTION public.after_comment_like_insert();
        ");

        // Trigger Hapus Notif jika Unlike (Opsional tapi bagus)
        DB::statement("
            CREATE OR REPLACE FUNCTION public.after_comment_like_delete()
            RETURNS TRIGGER AS $$
            BEGIN
                DELETE FROM notifications
                WHERE source_id = OLD.comment_id
                AND source_type = 'App\\Models\\Comment'
                AND sender_id = OLD.user_id
                AND type = 'like_comment';
                RETURN OLD;
            END;
            $$ LANGUAGE plpgsql;
        ");

        DB::statement("
            CREATE TRIGGER trigger_remove_notify_comment_like
            AFTER DELETE ON public.comment_likes
            FOR EACH ROW EXECUTE FUNCTION public.after_comment_like_delete();
        ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('comment_like_trigger');
    }
};
