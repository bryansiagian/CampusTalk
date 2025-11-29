<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Role; // Import Role model
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'profile_picture' => 'nullable|image|max:2048',
            'password' => 'required|string|min:8|confirmed',
            // Validasi Wajib untuk Mahasiswa
            'nim' => 'required|string|max:20|unique:users',
            'prodi_id' => 'required|exists:prodis,id',
            'angkatan' => 'required|integer|digits:4',
        ]);

        $profilePath = null;
        if ($request->hasFile('profile_picture')) {
            $profilePath = $request->file('profile_picture')->store('profiles', 'public');
        }

        $userRole = \App\Models\Role::where('name', 'user')->first();

        $user = \App\Models\User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => \Illuminate\Support\Facades\Hash::make($request->password),
            'profile_picture' => $profilePath,
            'role_id' => $userRole->id,
            'is_approved' => false,
            // Simpan Data Baru
            'nim' => $request->nim,
            'prodi_id' => $request->prodi_id,
            'angkatan' => $request->angkatan,
        ]);

        return response()->json([
            'message' => 'Registrasi berhasil! Mohon tunggu persetujuan Admin.',
            'user' => $user,
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        // PERUBAHAN: Cek Status Approval
        if (!$user->is_approved) {
             return response()->json([
                 'message' => 'Akun Anda belum disetujui oleh Admin. Silakan hubungi administrator.'
             ], 403); // 403 Forbidden
        }

        // Hapus semua token lama user ini
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil!',
            'user' => $user->load('role'),
            'token' => $token,
        ]);
    }

    public function logout(Request $request)
    {
        // Hapus token yang sedang digunakan saat ini
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logout berhasil!']);
    }

    public function updateProfilePicture(Request $request)
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048', // Max 2MB
        ]);

        $user = auth()->user();

        // Hapus foto lama jika ada
        if ($user->profile_picture && \Illuminate\Support\Facades\Storage::exists('public/' . $user->profile_picture)) {
            \Illuminate\Support\Facades\Storage::delete('public/' . $user->profile_picture);
        }

        // Upload baru
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('profiles', 'public');
            $user->update(['profile_picture' => $path]);
        }

        return response()->json([
            'message' => 'Foto profil diperbarui',
            'user' => $user->load('role') // Return user terbaru
        ]);
    }
}