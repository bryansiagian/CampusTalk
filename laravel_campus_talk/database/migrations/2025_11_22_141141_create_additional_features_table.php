<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Tabel Like Komentar
        Schema::create('comment_likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('comment_id')->constrained()->onDelete('cascade');
            $table->timestamps();
            // User hanya bisa like 1x per komentar
            $table->unique(['user_id', 'comment_id']);
        });

        // 2. Tabel Laporan (Reports) - Polymorphic
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Pelapor
            $table->string('reason'); // Alasan pelaporan
            $table->string('status')->default('pending'); // pending, resolved, dismissed

            // Polymorphic: Bisa Post atau Comment
            $table->unsignedBigInteger('reportable_id');
            $table->string('reportable_type'); // 'App\Models\Post' atau 'App\Models\Comment'

            $table->timestamps();
        });

        // 3. Update View: Tambahkan kolom total_likes ke comment_details_view
        // Kita hitung manual pakai subquery agar view tetap ringan
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
                c.parent_comment_id AS parent_comment_id,
                (SELECT COUNT(*) FROM comment_likes cl WHERE cl.comment_id = c.id) AS total_likes
            FROM
                public.comments AS c
            JOIN
                public.users AS u ON c.user_id = u.id
            JOIN
                public.posts AS p ON c.post_id = p.id;
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('reports');
        Schema::dropIfExists('comment_likes');
    }
};