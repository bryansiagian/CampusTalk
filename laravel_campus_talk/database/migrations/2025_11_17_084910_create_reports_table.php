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
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reporter_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('reported_post_id')->nullable()->constrained('posts')->onDelete('cascade');
            $table->foreignId('reported_comment_id')->nullable()->constrained('comments')->onDelete('cascade');
            $table->text('reason');
            $table->string('status', 50)->default('pending');
            $table->timestamps();
            $table->timestamp('resolved_at')->nullable();
            $table->foreignId('resolved_by')->nullable()->constrained('users')->onDelete('set null');

            // CHECK constraint:
        });
    }
    // ...
    public function down(): void
    {
        Schema::dropIfExists('reports');
    }
};
