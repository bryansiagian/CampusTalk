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
            'password' => 'required|string|min:8|confirmed',
            // Validasi Wajib untuk Mahasiswa
            'nim' => 'required|string|max:20|unique:users',
            'prodi' => 'required|string|max:100',
            'angkatan' => 'required|integer|digits:4',
        ]);

        $userRole = \App\Models\Role::where('name', 'user')->first();

        $user = \App\Models\User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => \Illuminate\Support\Facades\Hash::make($request->password),
            'role_id' => $userRole->id,
            'is_approved' => false,
            // Simpan Data Baru
            'nim' => $request->nim,
            'prodi' => $request->prodi,
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
}