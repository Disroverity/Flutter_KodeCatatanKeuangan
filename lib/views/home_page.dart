import 'package:flutter/material.dart';
import '../models/user.dart';

class HomePage extends StatefulWidget {
  final User? user;

  const HomePage({Key? key, this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Indeks 2 = Beranda (Aktif)
  bool _isSaldoHidden = false;

  // List transaksi dummy
  final List<Map<String, dynamic>> _transactions = [
    {
      'judul': 'Makan Siang',
      'jenis': 'Pengeluaran',
      'nominal': 50000,
      'tanggal': '10 Okt 2026',
      'icon': Icons.local_cafe_outlined,
    },
    {
      'judul': 'Cair',
      'jenis': 'Pemasukan',
      'nominal': 1000000,
      'tanggal': '10 Okt 2026',
      'icon': Icons.attach_money,
    },
    {
      'judul': 'Transportasi',
      'jenis': 'Pengeluaran',
      'nominal': 20000,
      'tanggal': '9 Okt 2026',
      'icon': Icons.directions_car_outlined,
    },
  ];

  int get _totalPemasukan {
    return _transactions
        .where((t) => t['jenis'] == 'Pemasukan')
        .fold(0, (sum, t) => sum + (t['nominal'] as int));
  }

  int get _totalPengeluaran {
    return _transactions
        .where((t) => t['jenis'] == 'Pengeluaran')
        .fold(0, (sum, t) => sum + (t['nominal'] as int));
  }

  int get _saldoTersedia => _totalPemasukan - _totalPengeluaran;

  String _formatRupiah(int number) {
    return 'Rp. ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    bool hasTransactions = _transactions.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'FinFlow',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: hasTransactions ? _buildPopulatedState() : _buildEmptyState(),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // L01-01: Empty State
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Kelola keuanganmu\ndengan lebih mudah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Catat transaksi, pantau pengeluaran, dan capai tujuan finansialmu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0E0E0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              child: const Text(
                '+ Tambah Transaksi',
                style: TextStyle(
                  color: Colors.black,
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

  // L01-02: Populated State
  Widget _buildPopulatedState() {
    String userName = widget.user?.namaLengkap ?? 'User';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $userName!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Udah catet pengeluaran kamu belum?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo Tersedia', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(
                      _isSaldoHidden ? 'Rp. ••••••••' : _formatRupiah(_saldoTersedia),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(_isSaldoHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () {
                    setState(() {
                      _isSaldoHidden = !_isSaldoHidden;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 16, color: Colors.black),
                          SizedBox(width: 4),
                          Text('Pemasukan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatRupiah(_totalPemasukan),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 16, color: Colors.black),
                          SizedBox(width: 4),
                          Text('Pengeluaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatRupiah(_totalPengeluaran),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catatan terbaru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final tx = _transactions[index];
              bool isPemasukan = tx['jenis'] == 'Pemasukan';

              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEEEEE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(tx['icon'] as IconData?, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx['judul'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(tx['jenis'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPemasukan ? '+' : '-'}${_formatRupiah(tx['nominal'] as int)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(tx['tanggal'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
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