import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoginTab = true; 
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  final TextEditingController _loginUsernameController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  final TextEditingController _regNamaController = TextEditingController();
  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regConfPasswordController = TextEditingController();

void _handleLogin() async {
    String username = _loginUsernameController.text.trim();
    String password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Data belum lengkap!');
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authController.login(username, password);
    
    // Cek apakah widget masih aktif di layar
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      _showSnackBar('Login Berhasil! Selamat datang ${res['user'].namaLengkap}');

      // Pindah ke HomePage dan hapus history AuthPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(user: res['user']),
        ),
      );
    } else {
      _showSnackBar(res['message'] ?? 'Login gagal!');
    }
  }

  void _handleRegister() async {
    String nama = _regNamaController.text.trim();
    String username = _regUsernameController.text.trim();
    String password = _regPasswordController.text.trim();
    String confPassword = _regConfPasswordController.text.trim();

    if (nama.isEmpty || username.isEmpty || password.isEmpty || confPassword.isEmpty) {
      _showSnackBar('Data belum lengkap!');
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authController.register(nama, username, password, confPassword);
    setState(() => _isLoading = false);

    _showSnackBar(res['message']);
    if (res['success']) {
      setState(() => _isLoginTab = true);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 1. Judul Utama Aplikasi (Paling Atas) - Selalu "FinFlow"
                Text(
                  'FinFlow',
                  style: const TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Navigasi Tab (Login / Register) di Bawahnya
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isLoginTab = true),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _isLoginTab ? FontWeight.bold : FontWeight.normal,
                          color: _isLoginTab ? Colors.deepPurple : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    GestureDetector(
                      onTap: () => setState(() => _isLoginTab = false),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: !_isLoginTab ? FontWeight.bold : FontWeight.normal,
                          color: !_isLoginTab ? Colors.deepPurple : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _isLoginTab ? _buildLoginForm() : _buildRegisterForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _loginUsernameController,
          decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading ? const CircularProgressIndicator() : const Text('LOGIN'),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _isLoginTab = false),
          child: const Text('Belum Punya akun? Daftar'),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        TextField(
          controller: _regNamaController,
          decoration: const InputDecoration(labelText: 'Nama'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regUsernameController,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regConfPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Konfirmasi Password'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            child: _isLoading ? const CircularProgressIndicator() : const Text('Daftar'),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _isLoginTab = true),
          child: const Text('Sudah memiliki akun? Masuk'),
        ),
      ],
    );
  }
}