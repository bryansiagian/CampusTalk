<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Report extends Model {
    protected $fillable = ['user_id', 'reason', 'status', 'reportable_id', 'reportable_type'];

    // Relasi Polymorphic (Bisa Post atau Comment)
    public function reportable() {
        return $this->morphTo();
    }

    public function reporter() {
        return $this->belongsTo(User::class, 'user_id');
    }
}