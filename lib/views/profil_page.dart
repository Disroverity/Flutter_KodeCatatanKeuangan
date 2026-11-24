import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/profil_controller.dart';
import 'catatan_page.dart'; // Menggunakan AppColors

// Helper tampilan avatar profil (L05-01-01 & L05-02-01)
Widget buildAvatarWidget(String avatarKey, {double radius = 38}) {
  final Map<String, Map<String, dynamic>> avatars = {
    'avatar_1': {'icon': Icons.person_rounded, 'bg': AppColors.babyBluePrimary},
    'avatar_2': {'icon': Icons.face_rounded, 'bg': const Color(0xFF4DB6AC)},
    'avatar_3': {'icon': Icons.sentiment_satisfied_alt_rounded, 'bg': const Color(0xFFFFB74D)},
    'avatar_4': {'icon': Icons.account_circle_rounded, 'bg': const Color(0xFFBA68C8)},
  };

  final selected = avatars[avatarKey] ?? avatars['avatar_1']!;
  return CircleAvatar(
    radius: radius,
    backgroundColor: selected['bg'] as Color,
    child: Icon(
      selected['icon'] as IconData,
      size: radius * 1.15,
      color: Colors.white,
    ),
  );
}

// =========================================================================
// L05-01: HALAMAN PROFILE UTAMA
// =========================================================================
class ProfilPage extends StatefulWidget {
  final String userId;
  final String username;
  final VoidCallback? onLogout;

  const ProfilPage({
    super.key,
    this.userId = 'USR-001',
    this.username = 'User',
    this.onLogout,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final ProfilController _controller = ProfilController();

  bool _isLoading = true;
  late String _namaLengkap;
  late String _email;
  String _noTelp = '';
  String _fotoProfil = 'avatar_1';
  bool _notifAktif = true;

  @override
  void initState() {
    super.initState();
    final cleanUser = widget.username.toLowerCase().replaceAll(' ', '');
    _namaLengkap = widget.username;
    _email = '${cleanUser.isEmpty ? 'user' : cleanUser}@mail.com';
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    setState(() => _isLoading = true);
    final res = await _controller.getProfil(widget.userId);
    if (mounted) {
      if (res['success'] == true && res['profil'] != null) {
        final p = res['profil'];
        setState(() {
          _namaLengkap = p['nama_lengkap'] ?? widget.username;
          _email = p['email'] ?? _email;
          _noTelp = p['no_telp'] ?? '';
          _fotoProfil = p['foto_profil'] ?? 'avatar_1';
          _notifAktif = p['notif_aktif'] == 1 || p['notif_aktif'] == true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  // L05-01-06: Dialog Pengaturan Notifikasi
  void _tampilkanDialogNotifikasi() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.creamBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Pengaturan Notifikasi',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          content: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifikasi Aplikasi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Aktifkan pengingat limit pengeluaran & target',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            activeColor: AppColors.babyBluePrimary,
            value: _notifAktif,
            onChanged: (val) async {
              setDialogState(() => _notifAktif = val);
              setState(() => _notifAktif = val);
              await _controller.updateNotifikasi(widget.userId, val);
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.babyBluePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  // L05-01-07: Dialog Tentang Aplikasi
  void _tampilkanTentangAplikasi() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppColors.babyBluePrimary),
            SizedBox(width: 10),
            Text('FinFlow v1.0',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        content: const Text(
          'FinFlow adalah aplikasi pencatatan keuangan pribadi yang membantu mengelola pemasukan, pengeluaran, grafik analisis, target keuangan, dan batas pengeluaran harian secara terintegrasi.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.babyBluePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _konfirmasiLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun?',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: const Text('Anda akan kembali ke halaman login aplikasi.',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ProfilController.catatAktivitas(
                userId: widget.userId,
                modul: 'Autentikasi',
                aksi: 'Logout dari Aplikasi',
                detail: 'Pengguna keluar dari sesi',
              );
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _muatProfil,
        color: AppColors.babyBluePrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              // Header Profil (L05-01-01 Foto, L05-01-02 Nama, L05-01-03 Email)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.creamCard, width: 1.5),
                ),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: AppColors.babyBluePrimary),
                        ),
                      )
                    : Row(
                        children: [
                          buildAvatarWidget(_fotoProfil, radius: 34),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _namaLengkap,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (_noTelp.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _noTelp,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.babyBluePrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),

              // L05-01-04: Edit Profil -> L05-02
              _buildMenuTile(
                icon: Icons.edit_note_rounded,
                title: 'Edit Profil',
                subtitle: 'Ubah foto, nama lengkap, email, dan telepon',
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilPage(
                        userId: widget.userId,
                        controller: _controller,
                        initialNama: _namaLengkap,
                        initialEmail: _email,
                        initialNoTelp: _noTelp,
                        initialFoto: _fotoProfil,
                      ),
                    ),
                  );
                  if (updated == true) _muatProfil();
                },
              ),
              const SizedBox(height: 12),

              // L05-01-05: Ubah Password -> L05-03
              _buildMenuTile(
                icon: Icons.lock_outline_rounded,
                title: 'Ubah Password',
                subtitle: 'Perbarui kata sandi keamanan akun',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UbahPasswordPage(
                        userId: widget.userId,
                        controller: _controller,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Menu Tambahan: Log Aktivitas Sinkron & Aktual per Detik
              _buildMenuTile(
                icon: Icons.history_rounded,
                title: 'Log Aktivitas',
                subtitle: 'Riwayat seluruh aktivitas real-time hingga detik kejadian',
                badgeText: 'LIVE',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityLogPage(
                        userId: widget.userId,
                        controller: _controller,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // L05-01-06: Notifikasi
              _buildMenuTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                subtitle: _notifAktif ? 'Status: Aktif' : 'Status: Nonaktif',
                onTap: _tampilkanDialogNotifikasi,
              ),
              const SizedBox(height: 12),

              // L05-01-07: Tentang Aplikasi
              _buildMenuTile(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                subtitle: 'Informasi versi dan pengembang FinFlow',
                onTap: _tampilkanTentangAplikasi,
              ),
              const SizedBox(height: 24),

              // Tombol Keluar (Logout)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _konfirmasiLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    foregroundColor: AppColors.expenseRed,
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.creamCard, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.babyBlueLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.babyBluePrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.incomeGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: AppColors.incomeGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// L05-02: HALAMAN EDIT PROFILE
// =========================================================================
class EditProfilPage extends StatefulWidget {
  final String userId;
  final ProfilController controller;
  final String initialNama;
  final String initialEmail;
  final String initialNoTelp;
  final String initialFoto;

  const EditProfilPage({
    super.key,
    required this.userId,
    required this.controller,
    required this.initialNama,
    required this.initialEmail,
    required this.initialNoTelp,
    required this.initialFoto,
  });

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _telpController;
  late String _selectedAvatar;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.initialNama);
    _emailController = TextEditingController(text: widget.initialEmail);
    _telpController = TextEditingController(text: widget.initialNoTelp);
    _selectedAvatar = widget.initialFoto;
  }

  // L05-02-02: Ubah Foto (Memilih Avatar Profil)
  void _pilihAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.creamBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Foto Profil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['avatar_1', 'avatar_2', 'avatar_3', 'avatar_4'].map((key) {
                final isSelected = _selectedAvatar == key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatar = key);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.babyBluePrimary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: buildAvatarWidget(key, radius: 30),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanProfil() async {
    final err = widget.controller.validateProfileData(
      namaLengkap: _namaController.text,
      email: _emailController.text,
      noTelp: _telpController.text,
    );

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.expenseRed),
      );
      return;
    }

    setState(() => _isSaving = true);
    final res = await widget.controller.updateProfile(
      userId: widget.userId,
      namaLengkap: _namaController.text,
      email: _emailController.text,
      noTelp: _telpController.text,
      fotoProfil: _selectedAvatar,
    );
    setState(() => _isSaving = false);

    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Profil berhasil diperbarui!'),
            backgroundColor: AppColors.babyBluePrimary,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memperbarui profil'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // L05-02-01 & L05-02-02: Foto Profil & Tombol Ubah Foto
            Center(
              child: Column(
                children: [
                  buildAvatarWidget(_selectedAvatar, radius: 44),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _pilihAvatar,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.babyBlueSoft),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ubah Foto', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // L05-02-03: Nama Lengkap
            _buildInputLabel('Nama Lengkap'),
            TextField(
              controller: _namaController,
              decoration: _inputDecoration('Masukkan nama lengkap'),
            ),
            const SizedBox(height: 16),

            // L05-02-04: Email
            _buildInputLabel('Email'),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Masukkan email'),
            ),
            const SizedBox(height: 16),

            // L05-02-05: Nomor Telepon
            _buildInputLabel('Nomor Telepon'),
            TextField(
              controller: _telpController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Masukkan nomor telepon'),
            ),
            const SizedBox(height: 28),

            // L05-02-06 (Batal) & L05-02-07 (Simpan)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.creamCard,
                      foregroundColor: AppColors.textDark,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _simpanProfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.babyBluePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.babyBlueSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.babyBluePrimary, width: 1.5),
      ),
    );
  }
}

// =========================================================================
// L05-03: HALAMAN UBAH PASSWORD
// =========================================================================
class UbahPasswordPage extends StatefulWidget {
  final String userId;
  final ProfilController controller;

  const UbahPasswordPage({
    super.key,
    required this.userId,
    required this.controller,
  });

  @override
  State<UbahPasswordPage> createState() => _UbahPasswordPageState();
}

class _UbahPasswordPageState extends State<UbahPasswordPage> {
  final TextEditingController _lamaCtrl = TextEditingController();
  final TextEditingController _baruCtrl = TextEditingController();
  final TextEditingController _konfirmasiCtrl = TextEditingController();

  bool _obscureLama = true;
  bool _obscureBaru = true;
  bool _obscureKonfirmasi = true;
  bool _isSaving = false;

  Future<void> _simpanPassword() async {
    final err = widget.controller.validatePasswordInput(
      passLama: _lamaCtrl.text,
      passBaru: _baruCtrl.text,
      confirmPassBaru: _konfirmasiCtrl.text,
    );

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.expenseRed),
      );
      return;
    }

    setState(() => _isSaving = true);
    final res = await widget.controller.changePassword(
      userId: widget.userId,
      passLama: _lamaCtrl.text,
      passBaru: _baruCtrl.text,
      confirmPassBaru: _konfirmasiCtrl.text,
    );
    setState(() => _isSaving = false);

    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Password berhasil diubah!'),
            backgroundColor: AppColors.babyBluePrimary,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Password lama salah'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ubah Password',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // L05-03-01: Password Lama
            const Text('Password Lama',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _lamaCtrl,
              obscureText: _obscureLama,
              decoration: _passDecoration(
                hint: 'Masukkan password lama',
                obscure: _obscureLama,
                onToggle: () => setState(() => _obscureLama = !_obscureLama),
              ),
            ),
            const SizedBox(height: 16),

            // L05-03-02: Password Baru
            const Text('Password Baru',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _baruCtrl,
              obscureText: _obscureBaru,
              decoration: _passDecoration(
                hint: 'Masukkan password baru',
                obscure: _obscureBaru,
                onToggle: () => setState(() => _obscureBaru = !_obscureBaru),
              ),
            ),
            const SizedBox(height: 16),

            // L05-03-03: Konfirmasi Password Baru
            const Text('Konfirmasi Password Baru',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _konfirmasiCtrl,
              obscureText: _obscureKonfirmasi,
              decoration: _passDecoration(
                hint: 'Konfirmasi password baru',
                obscure: _obscureKonfirmasi,
                onToggle: () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
              ),
            ),
            const SizedBox(height: 28),

            // L05-03-05 (Batal) & L05-03-06 (Simpan)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.creamCard,
                      foregroundColor: AppColors.textDark,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _simpanPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.babyBluePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _passDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      // L05-03-04: Ikon mata
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textMuted,
        ),
        onPressed: onToggle,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.babyBlueSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.babyBluePrimary, width: 1.5),
      ),
    );
  }
}

// =========================================================================
// MENU TAMBAHAN: HALAMAN LOG AKTIVITAS SINKRON & REAL-TIME (PER DETIK)
// =========================================================================
class ActivityLogPage extends StatefulWidget {
  final String userId;
  final ProfilController controller;

  const ActivityLogPage({
    super.key,
    required this.userId,
    required this.controller,
  });

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    // Auto-sync tiap 2 detik agar log aktual secara sinkron
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchLogs(silent: true));
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLogs({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    final data = await widget.controller.getActivityLogs(widget.userId);
    if (mounted) {
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    }
  }

  IconData _getModulIcon(String modul) {
    switch (modul) {
      case 'Autentikasi':
        return Icons.login_rounded;
      case 'Catatan Keuangan':
        return Icons.receipt_long_rounded;
      case 'Informasi Keuangan':
        return Icons.bar_chart_rounded;
      case 'Target Keuangan':
        return Icons.track_changes_rounded;
      case 'Profil':
        return Icons.person_outline_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Log Aktivitas (Real-Time)',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.babyBluePrimary),
            onPressed: () => _fetchLogs(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.babyBluePrimary))
          : _logs.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada riwayat aktivitas tercatat.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.creamCard, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.babyBlueLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getModulIcon(log['modul'] ?? ''),
                              color: AppColors.babyBluePrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.creamCard,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        log['modul'] ?? 'Sistem',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      log['waktu_format'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.babyBluePrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  log['aksi'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if ((log['detail'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    log['detail'],
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}