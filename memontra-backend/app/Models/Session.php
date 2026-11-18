<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Session extends Model
{
    use HasUuids;

    // Tambahkan baris ini bro:
    protected $table = 'photo_sessions';

    protected $guarded = [];

    public function event() {
        return $this->belongsTo(Event::class);
    }

    public function photos() {
        return $this->hasMany(Photo::class);
    }
}