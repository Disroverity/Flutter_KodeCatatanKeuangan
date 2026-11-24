import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

typedef ProfilResult = Map<String, dynamic>;

class ProfilController {
  // Ambil profil user + generate default email username@mail.com
  Future<ProfilResult> getProfil(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/profil/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Gagal memuat profil'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan koneksi: $e'};
    }
  }

  // Validasi Edit Profil (Alt 1 & Alt 3 pada UC 5)
  String? validateProfileData({
    required String namaLengkap,
    required String email,
    required String noTelp,
  }) {
    if (namaLengkap.trim().isEmpty || email.trim().isEmpty) {
      return 'Data profil tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Format email atau password tidak valid';
    }
    if (noTelp.trim().isNotEmpty && !RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(noTelp.trim())) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }

  // Diagram 1 (Langkah 5-10): updateProfile(...)
  Future<ProfilResult> updateProfile({
    required String userId,
    required String namaLengkap,
    required String email,
    required String noTelp,
    required String fotoProfil,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profil/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_lengkap': namaLengkap.trim(),
          'email': email.trim(),
          'no_telp': noTelp.trim(),
          'foto_profil': fotoProfil,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // Validasi Ubah Password (Alt 2 & Alt 3 pada UC 5)
  String? validatePasswordInput({
    required String passLama,
    required String passBaru,
    required String confirmPassBaru,
  }) {
    if (passLama.isEmpty || passBaru.isEmpty || confirmPassBaru.isEmpty) {
      return 'Data password tidak boleh kosong';
    }
    if (passBaru != confirmPassBaru || passBaru.length < 4) {
      return 'Format email atau password tidak valid';
    }
    return null;
  }

  // Diagram 2 (Langkah 5-12): changePassword(...)
  Future<ProfilResult> changePassword({
    required String userId,
    required String passLama,
    required String passBaru,
    required String confirmPassBaru,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profil/$userId/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password_lama': passLama,
          'password_baru': passBaru,
          'konfirmasi_password': confirmPassBaru,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // Simpan Toggle Notifikasi (L05-01-06)
  Future<ProfilResult> updateNotifikasi(String userId, bool aktif) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profil/$userId/notifikasi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'notif_aktif': aktif}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false};
    }
  }

  // Helper statis untuk mencatat log kejadian sinkron dari halaman manapun
  static Future<void> catatAktivitas({
    required String userId,
    required String modul,
    required String aksi,
    String detail = '',
  }) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'modul': modul,
          'aksi': aksi,
          'detail': detail,
        }),
      );
    } catch (_) {}
  }

  // Ambil daftar log aktivitas real-time
  Future<List<Map<String, dynamic>>> getActivityLogs(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/logs/$userId'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(body['logs'] ?? []);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}