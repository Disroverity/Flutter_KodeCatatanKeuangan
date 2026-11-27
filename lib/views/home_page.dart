import 'package:flutter/material.dart';
import '../models/user.dart';
import 'catatan_page.dart';
import '../controllers/catatan_controller.dart';
import 'informasi_keuangan_page.dart';
import 'target_keuangan_page.dart';
import 'profil_page.dart';

class HomePage extends StatefulWidget {
  final User? user;

  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Indeks 2 = Beranda (Aktif)
  bool _isSaldoHidden = false;

  // List transaksi dikosongkan agar awalnya muncul Empty State
  final List _transactions = [];

  // --- TARUH DI SINI (TEPAT DI BAWAH _transactions) ---
  final CatatanController _catatanController = CatatanController();

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final userId = widget.user?.userId.toString() ?? '1';
    final data = await _catatanController.fetchTransactions(userId);
    if (mounted) {
      setState(() {
        _transactions.clear();
        for (var tx in data) {
          final tgl = tx['tanggal'] as DateTime;
          _transactions.add({
            'nama_catatan': tx['nama_catatan'],
            'jenis': tx['jenis'],
            'jumlah': (tx['jumlah'] as double).toInt(),
            'tanggal': '${tgl.day}/${tgl.month}/${tgl.year}',
            'icon': tx['jenis'] == 'Pemasukan'
                ? Icons.account_balance_wallet_outlined
                : Icons.receipt_long_outlined,
          });
        }
      });
    }
  }

  int get _totalPemasukan {
    return _transactions
        .where((t) => t['jenis'] == 'Pemasukan')
        .fold(0, (sum, t) => sum + (t['jumlah'] as int));
  }

  int get _totalPengeluaran {
    return _transactions
        .where((t) => t['jenis'] == 'Pengeluaran')
        .fold(0, (sum, t) => sum + (t['jumlah'] as int));
  }

  int get _saldoTersedia => _totalPemasukan - _totalPengeluaran;

  String _formatRupiah(int number) {
    return 'Rp. ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Fungsi pindah ke tab Catatan Keuangan (indeks 0)
  void _bukaHalamanCatatan() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      // AppBar utama hanya ditampilkan saat di tab Beranda (index 2)
      // karena CatatanKeuanganPage sudah memiliki AppBar sendiri
      appBar: _currentIndex == 2
          ? AppBar(
              backgroundColor: AppColors.creamBackground,
              elevation: 0,
              title: const Text(
                'FinFlow',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textDark,
                  ),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: _buildBodyContent(),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Mengatur tampilan berdasarkan tab navigasi yang dipilih
Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 0:
        // Tab Catatan (Pojok Kiri Bawah) -> Menampilkan UI Catatan Keuangan
        return CatatanKeuanganPage(
          userId: widget.user?.userId.toString() ?? 'USR-001',
        );
      case 1:
        // Tab Grafik -> Menampilkan UI Informasi Keuangan (Use Case 3)
        return InformasiKeuanganPage(
          userId: widget.user?.userId.toString() ?? 'USR-001',
        );
      case 2:
        // Tab Beranda
        return _transactions.isNotEmpty
            ? _buildPopulatedState()
            : _buildEmptyState();
      case 3:
        return TargetKeuanganPage(userId: widget.user?.userId.toString() ?? 'USR-001',);
      default:
        return ProfilPage(
            userId: widget.user?.userId.toString() ?? 'USR-001',
            username: widget.user?.username ?? 'User', // sesuaikan jika nama field username di HomePage berbeda
          );
    }
  }

  // L01-01: Empty State (Warna Cream & Biru Muda Halus)
  Widget _buildEmptyState() {
    String userName = widget.user?.namaLengkap ?? 'User';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Halo, $userName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              color: AppColors.babyBlueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 75,
              color: AppColors.babyBluePrimary,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Kelola keuanganmu\ndengan lebih mudah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Catat transaksi, pantau pengeluaran, dan capai tujuan finansialmu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.babyBluePrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _bukaHalamanCatatan,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text(
                '+ Tambah Transaksi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // L01-02: Populated State (Warna Cream & Biru Muda Halus)
  Widget _buildPopulatedState() {
    String userName = widget.user?.namaLengkap ?? 'User';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $userName!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Udah catet pengeluaran kamu belum?',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          // Kartu Saldo Utama (Baby Blue Gradient)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6BA8EE), Color(0xFF9AC5F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.babyBluePrimary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo Tersedia',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSaldoHidden
                          ? 'Rp. ••••••••'
                          : _formatRupiah(_saldoTersedia),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _isSaldoHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSaldoHidden = !_isSaldoHidden;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Kartu Pemasukan & Pengeluaran (Cream Card)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.creamCard, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded,
                              size: 16, color: AppColors.incomeGreen),
                          SizedBox(width: 4),
                          Text('Pemasukan',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatRupiah(_totalPemasukan),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.creamCard, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded,
                              size: 16, color: AppColors.expenseRed),
                          SizedBox(width: 4),
                          Text('Pengeluaran',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatRupiah(_totalPengeluaran),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Header Catatan Terbaru + Tombol "Lihat Semua"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catatan terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: _bukaHalamanCatatan, // Mengarahkan ke menu Catatan
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.babyBluePrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length > 3 ? 3 : _transactions.length,
            itemBuilder: (context, index) {
              final tx = _transactions[index];
              bool isPemasukan = tx['jenis'] == 'Pemasukan';

              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.creamCard, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPemasukan
                            ? const Color(0xFFE8F5E9)
                            : AppColors.babyBlueLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        tx['icon'] as IconData?,
                        color: isPemasukan
                            ? AppColors.incomeGreen
                            : AppColors.babyBluePrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx['nama_catatan'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            tx['jenis'] as String,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPemasukan ? '+' : '-'}${_formatRupiah(tx['jumlah'] as int)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isPemasukan
                                ? AppColors.incomeGreen
                                : AppColors.expenseRed,
                          ),
                        ),
                        Text(
                          tx['tanggal'] as String,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.babyBluePrimary,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        if (index == 2) {
          _loadHomeData();
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          activeIcon: Icon(Icons.article),
          label: 'Catatan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Grafik',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.track_changes_outlined),
          activeIcon: Icon(Icons.track_changes),
          label: 'Target',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}