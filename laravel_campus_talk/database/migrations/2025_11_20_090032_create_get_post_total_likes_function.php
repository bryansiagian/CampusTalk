<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement("
            CREATE OR REPLACE FUNCTION public.get_post_total_likes(p_post_id BIGINT)
            RETURNS BIGINT
            LANGUAGE plpgsql
            AS $$
            DECLARE
                total_likes_count BIGINT;
            BEGIN
                SELECT COUNT(id) INTO total_likes_count
                FROM public.likes
                WHERE post_id = p_post_id;

                RETURN total_likes_count;
            END;
            $$;
        ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Perhatikan bahwa untuk DROP FUNCTION, Anda harus menyertakan argumennya
        DB::statement("DROP FUNCTION IF EXISTS public.get_post_total_likes(BIGINT);");
    }
};