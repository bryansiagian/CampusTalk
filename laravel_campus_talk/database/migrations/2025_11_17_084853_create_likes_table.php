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
        Schema::create('likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('post_id')->nullable()->constrained('posts')->onDelete('cascade');
            $table->foreignId('comment_id')->nullable()->constrained('comments')->onDelete('cascade');
            $table->timestamps();

            // Unique index parsial, seperti yang kita buat di PostgreSQL
            $table->unique(['user_id', 'post_id']); // Ini perlu diatasi dengan custom index setelah migrate
            $table->unique(['user_id', 'comment_id']); // Ini perlu diatasi dengan custom index setelah migrate
            // CHECK constraint:
            // Karena ini tidak bisa langsung di migration Laravel, biasanya ditambahkan manual ke DB
            // atau dicek di logic controller.
        });

        // Untuk menambahkan partial unique index secara manual di up()
        // Ini akan bekerja setelah tabel dibuat
        DB::statement('CREATE UNIQUE INDEX unique_like_post_idx ON likes (user_id, post_id) WHERE post_id IS NOT NULL;');
        DB::statement('CREATE UNIQUE INDEX unique_like_comment_idx ON likes (user_id, comment_id) WHERE comment_id IS NOT NULL;');
        // Untuk CHECK constraint, biasanya dicek di validasi controller atau tambahkan raw SQL setelah tabel dibuat
        DB::statement('ALTER TABLE likes ADD CONSTRAINT chk_one_like_target CHECK ((post_id IS NOT NULL AND comment_id IS NULL) OR (post_id IS NULL AND comment_id IS NOT NULL));');

    }
// ...
    public function down(): void
    {
        // Pastikan juga menghapus indeks custom saat rollback
        Schema::table('likes', function (Blueprint $table) {
            $table->dropUnique('likes_user_id_post_id_unique'); // Hapus indeks Laravel default
            $table->dropUnique('likes_user_id_comment_id_unique'); // Hapus indeks Laravel default
        });
        DB::statement('DROP INDEX IF EXISTS unique_like_post_idx;');
        DB::statement('DROP INDEX IF EXISTS unique_like_comment_idx;');
        DB::statement('ALTER TABLE likes DROP CONSTRAINT IF EXISTS chk_one_like_target;');
        Schema::dropIfExists('likes');
    }
};
