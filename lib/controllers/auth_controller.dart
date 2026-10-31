import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';

class AuthController {
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['user']),
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
      String nama, String username, String password, String confirmPassword) async {
    if (password != confirmPassword) {
      return {'success': false, 'message': 'Konfirmasi password tidak sesuai!'};
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_lengkap': nama,
          'username': username,
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Registrasi gagal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}