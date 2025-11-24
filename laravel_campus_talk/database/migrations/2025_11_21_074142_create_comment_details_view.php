<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement("
            CREATE OR REPLACE VIEW public.comment_details_view AS
            SELECT
                c.id AS comment_id,
                c.content AS comment_content,
                c.user_id AS commenter_id,
                u.name AS commenter_name,
                c.post_id AS post_id,
                p.title AS post_title,
                c.created_at AS comment_created_at,
                c.parent_comment_id AS parent_comment_id -- <--- KOLOM WAJIB
            FROM
                public.comments AS c
            JOIN
                public.users AS u ON c.user_id = u.id
            JOIN
                public.posts AS p ON c.post_id = p.id;
        ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement("DROP VIEW IF EXISTS public.comment_details_view;");
    }
};