import 'package:flutter/material.dart';

import '../controllers/catatan_controller.dart';
import '../models/catatan_keuangan.dart';
import '../controllers/target_controller.dart';
import 'target_keuangan_page.dart';

class AppColors {
  static const Color creamBackground = Color(0xFFFAF8F5);
  static const Color creamCard = Color(0xFFF3EFEA);
  static const Color babyBluePrimary = Color(0xFF5C9CE6);
  static const Color babyBlueLight = Color(0xFFE3F2FD);
  static const Color babyBlueSoft = Color(0xFFD0E6FA);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMuted = Color(0xFF718096);
  static const Color incomeGreen = Color(0xFF2E7D32);
  static const Color expenseRed = Color(0xFFC62828);
}

class CatatanKeuanganPage extends StatefulWidget {
  final String userId;

  const CatatanKeuanganPage({super.key, this.userId = 'USR-001'});

  @override
  State<CatatanKeuanganPage> createState() => _CatatanKeuanganPageState();
}

class _CatatanKeuanganPageState extends State<CatatanKeuanganPage> {
  final CatatanController _controller = CatatanController();
  late CatatanKeuangan _catatanKeuangan;

  String _selectedFilter = 'Semua';

  // List transaksi awal (menggunakan List agar aman dari pemotongan bracket)
  final List _transactions = [];

  final List _presets = [];

  @override
  bool _isLoading = true; // <-- 1. Variabel _isLoading di luar initState

  @override
  void initState() {
    super.initState();
    _catatanKeuangan = CatatanKeuangan(userId: widget.userId);
    _loadDataDariDatabase(); // <-- 2. Dipanggil di dalam initState()
  }

  // 3. Deklarasi fungsinya ditaruh DI LUAR / DI BAWAH initState()
  Future<void> _loadDataDariDatabase() async {
    final data = await _controller.fetchTransactions(widget.userId);
    double totalMasuk = 0;
    double totalKeluar = 0;

    for (var tx in data) {
      if (tx['jenis'] == 'Pemasukan') {
        totalMasuk += (tx['jumlah'] as double);
      } else {
        totalKeluar += (tx['jumlah'] as double);
      }
    }

    if (mounted) {
      setState(() {
        _transactions.clear();
        _transactions.addAll(data);
        _catatanKeuangan = CatatanKeuangan(
          userId: widget.userId,
          totalPemasukan: totalMasuk,
          totalPengeluaran: totalKeluar,
          saldo: totalMasuk - totalKeluar,
        );
        _isLoading = false;
      });
    }
  }

  List get _filteredTransactions {
    if (_selectedFilter == 'Semua') return _transactions;
    return _transactions.where((tx) => tx['jenis'] == _selectedFilter).toList();
  }

  String _formatRupiah(double amount) {
    String str = amount.toInt().toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count == 3 && i > 0) {
        result = '.$result';
        count = 0;
      }
    }
    return 'Rp $result';
  }

  String _formatTanggal(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  IconData _getCategoryIcon(String? kategori, String jenis) {
    if (jenis == 'Pemasukan') return Icons.account_balance_wallet_rounded;
    switch (kategori) {
      case 'Makanan & Minuman':
        return Icons.restaurant_rounded;
      case 'Transportasi':
        return Icons.directions_car_rounded;
      case 'Kebutuhan Harian / Pokok':
        return Icons.shopping_cart_rounded;
      case 'Hiburan / Gaya Hidup':
        return Icons.sports_esports_rounded;
      case 'Kesehatan':
        return Icons.medical_services_rounded;
      case 'Pendidikan':
        return Icons.school_rounded;
      case 'Fashion':
        return Icons.checkroom_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  void _bukaFormTambahTransaksi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormTambahTransaksiPage(
          catatanKeuangan: _catatanKeuangan,
          controller: _controller,
          currentPresetCount: _presets.length,
        ),
      ),
    );

    if (result != null && result is Map && result['data'] != null) {
      setState(() {
        _transactions.insert(0, result['data']);
        if (result['presetAdded'] == true) {
          _presets.add(result['data']);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.babyBluePrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      if (result['data']['jenis'] == 'Pengeluaran' && mounted) {
        final statusLimit =
            await TargetController().cekStatusLimitHarian(widget.userId);
        if (statusLimit['mendekatiLimit'] == true && mounted) {
          await tampilkanNotifikasiLimitPengeluaran(
            context,
            statusLimit: statusLimit,
            onLihatTransaksi: () {
              setState(() {
                _selectedFilter = 'Pengeluaran';
              });
            },
          );
        }
      }
    }
  }

  void _tampilkanModalPreset() async {
    List daftarPreset = await _controller.fetchPresets(widget.userId);
    if (!mounted) return;

    String selectedTabJenis = 'Pengeluaran';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creamBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredPresets = daftarPreset
                .where((p) => p['jenis'] == selectedTabJenis)
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Preset',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textDark,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.creamCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: ['Pemasukan', 'Pengeluaran'].map((jenis) {
                        final isSelected = selectedTabJenis == jenis;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedTabJenis = jenis),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.babyBluePrimary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                jenis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredPresets.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada preset $selectedTabJenis.\nCentang "Jadikan preset?" saat menambah transaksi.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredPresets.length,
                            itemBuilder: (context, index) {
                              final preset = filteredPresets[index];
                              final isPemasukan =
                                  preset['jenis'] == 'Pemasukan';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.creamCard,
                                    width: 1.5,
                                  ),
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
                                        _getCategoryIcon(
                                          preset['kategori'],
                                          preset['jenis'],
                                        ),
                                        color: isPemasukan
                                            ? AppColors.incomeGreen
                                            : AppColors.babyBluePrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            preset['nama_catatan'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatRupiah(preset['jumlah']),
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: AppColors.textMuted,
                                      ),
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          final updated = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditPresetPage(
                                                    preset: preset,
                                                    controller: _controller,
                                                  ),
                                            ),
                                          );
                                          if (updated == true) {
                                            final refreshed = await _controller
                                                .fetchPresets(widget.userId);
                                            setModalState(
                                              () => daftarPreset = refreshed,
                                            );
                                          }
                                        } else if (value == 'delete') {
                                          final ok = await _controller
                                              .deletePreset(
                                                preset['preset_id'],
                                              );
                                          if (ok) {
                                            setModalState(() {
                                              daftarPreset.removeWhere(
                                                (p) =>
                                                    p['preset_id'] ==
                                                    preset['preset_id'],
                                              );
                                            });
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                                color: AppColors.textDark,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline_rounded,
                                                size: 18,
                                                color: AppColors.expenseRed,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: AppColors.expenseRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        Navigator.pop(context);
                                        final res = await _controller
                                            .executeQuickInput(
                                              preset['preset_id'],
                                            );
                                        if (res['success'] == true && mounted) {
                                          await _loadDataDariDatabase();
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(res['message']),
                                              backgroundColor:
                                                  AppColors.babyBluePrimary,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                          if (preset['jenis'] == 'Pengeluaran' && mounted) {
                                            final statusLimit =
                                                await TargetController().cekStatusLimitHarian(widget.userId);
                                            if (statusLimit['mendekatiLimit'] == true && mounted) {
                                              await tampilkanNotifikasiLimitPengeluaran(
                                                this.context,
                                                statusLimit: statusLimit,
                                                onLihatTransaksi: () {
                                                  setState(() {
                                                    _selectedFilter = 'Pengeluaran';
                                                  });
                                                },
                                              );
                                            }
                                          }
                                        }           
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: const BoxDecoration(
                                          color: AppColors.babyBlueLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          color: AppColors.babyBluePrimary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
          'Catatan Keuangan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Kartu Ringkasan Saldo
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6BA8EE), Color(0xFF9AC5F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.babyBluePrimary.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Tercatat',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(_catatanKeuangan.hitungSaldo()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat(
                        'Pemasukan',
                        _formatRupiah(_catatanKeuangan.getTotalPemasukan()),
                        Icons.arrow_downward_rounded,
                      ),
                      Container(width: 1, height: 28, color: Colors.white30),
                      _buildMiniStat(
                        'Pengeluaran',
                        _formatRupiah(_catatanKeuangan.getTotalPengeluaran()),
                        Icons.arrow_upward_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tombol Aksi Utama: Btn_Tambah & Btn_Preset
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _bukaFormTambahTransaksi,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      '+ Catatan Baru',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.babyBluePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _tampilkanModalPreset, // <-- Ganti blok SnackBar tadi dengan baris ini saja
                    icon: const Icon(Icons.bolt_rounded, size: 20),
                    label: const Text(
                      '+ Input Cepat',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.babyBlueLight,
                      foregroundColor: AppColors.babyBluePrimary,
                      side: const BorderSide(color: AppColors.babyBlueSoft),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['Semua', 'Pemasukan', 'Pengeluaran'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: AppColors.babyBluePrimary,
                    backgroundColor: AppColors.creamCard,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.babyBluePrimary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Riwayat Transaksi (List_Tx)
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada catatan transaksi.\nKlik "+ Catatan Baru" untuk mulai mencatat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  )
                : ListView.builder(
                    // <-- Ganti 'child:' menjadi ':'
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      final isPemasukan = tx['jenis'] == 'Pemasukan';

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          debugPrint('Item diklik: ${tx['nama_catatan']} (ID: ${tx['id']})');
                          final hasilAksi = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailTransaksiPage(
                                transaksi: tx,
                                userId: widget.userId,
                                controller: _controller,
                              ),
                            ),
                          );
                          // Jika user melakukan Edit atau Hapus, refresh data & tampilkan SnackBar
                          if (hasilAksi != null &&
                              hasilAksi is Map &&
                              hasilAksi['refresh'] == true) {
                            await _loadDataDariDatabase();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    hasilAksi['message'] ?? 'Data diperbarui',
                                  ),
                                  backgroundColor: AppColors.babyBluePrimary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },

                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.creamCard,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isPemasukan
                                    ? const Color(0xFFE8F5E9)
                                    : AppColors.babyBlueLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(tx['kategori'], tx['jenis']),
                                color: isPemasukan
                                    ? AppColors.incomeGreen
                                    : AppColors.babyBluePrimary,
                              ),
                            ),
                            title: Text(
                              tx['nama_catatan'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              tx['jenis'],
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isPemasukan ? '+' : '-'}${_formatRupiah(tx['jumlah'])}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isPemasukan
                                            ? AppColors.incomeGreen
                                            : AppColors.expenseRed,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTanggal(tx['tanggal']),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FormTambahTransaksiPage extends StatefulWidget {
  final CatatanKeuangan catatanKeuangan;
  final CatatanController controller;
  final int currentPresetCount;

  const FormTambahTransaksiPage({
    super.key,
    required this.catatanKeuangan,
    required this.controller,
    required this.currentPresetCount,
  });

  @override
  State<FormTambahTransaksiPage> createState() =>
      _FormTambahTransaksiPageState();
}

class _FormTambahTransaksiPageState extends State<FormTambahTransaksiPage> {
  String _jenisTransaksi = 'Pemasukan';
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String? _selectedKategori;
  DateTime? _selectedDate = DateTime.now();
  bool _isPreset = false;
  bool _isSaving = false;

  void _tampilkanModalKategori() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creamBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredKategori = widget.controller.kategoriPengeluaran
                .where(
                  (k) => k.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari kategori...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.babyBluePrimary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filteredKategori.length,
                      itemBuilder: (context, index) {
                        final item = filteredKategori[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.label_important_outline_rounded,
                            color: AppColors.babyBluePrimary,
                          ),
                          title: Text(
                            item,
                            style: const TextStyle(color: AppColors.textDark),
                          ),
                          onTap: () {
                            setState(() => _selectedKategori = item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pilihTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.babyBluePrimary,
              onPrimary: Colors.white,
              surface: AppColors.creamBackground,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _prosesSimpan() async {
    final errorMsg = widget.controller.validateForm(
      namaCatatan: _namaController.text,
      nominalText: _nominalController.text,
      jenis: _jenisTransaksi,
      kategori: _selectedKategori,
      tanggal: _selectedDate,
    );

    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final double jumlah = double.parse(
      _nominalController.text.replaceAll('.', '').replaceAll(',', ''),
    );

    final hasil = await widget.controller.simpanClicked(
      catatanKeuangan: widget.catatanKeuangan,
      jenis: _jenisTransaksi,
      namaCatatan: _namaController.text.trim(),
      jumlah: jumlah,
      kategori: _selectedKategori,
      tanggal: _selectedDate!,
      deskripsi: _deskripsiController.text.trim(),
      isPreset: _isPreset,
      currentPresetCount: widget.currentPresetCount,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (hasil['success'] == true) {
        Navigator.pop(context, hasil);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasil['message'] ?? 'Gagal menyimpan transaksi'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPengeluaran = _jenisTransaksi == 'Pengeluaran';

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
          'Tambah Transaksi',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.creamCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: ['Pemasukan', 'Pengeluaran'].map((jenis) {
                  final isSelected = _jenisTransaksi == jenis;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _jenisTransaksi = jenis),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.babyBluePrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          jenis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Nama Catatan'),
            _buildTextField(
              controller: _namaController,
              hint: 'Masukkan nama catatan',
            ),
            const SizedBox(height: 16),
            _buildLabel('Jumlah'),
            _buildTextField(
              controller: _nominalController,
              hint: 'Masukkan nominal (contoh: 50000)',
              keyboardType: TextInputType.number,
              prefixText: 'Rp ',
            ),
            if (isPengeluaran) ...[
              const SizedBox(height: 16),
              _buildLabel('Kategori'),
              InkWell(
                onTap: _tampilkanModalKategori,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.babyBlueSoft),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.babyBluePrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedKategori ?? 'Cari kategori',
                          style: TextStyle(
                            color: _selectedKategori == null
                                ? AppColors.textMuted
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildLabel('Tanggal'),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.babyBlueSoft),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.babyBluePrimary,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Pilih tanggal'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Deskripsi (opsional)'),
            _buildTextField(
              controller: _deskripsiController,
              hint: 'Masukkan keterangan',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.babyBluePrimary,
              title: const Text(
                'Jadikan preset?',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              value: _isPreset,
              onChanged: (val) => setState(() => _isPreset = val ?? false),
            ),
            const SizedBox(height: 20),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _prosesSimpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.babyBluePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixText: prefixText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.babyBlueSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.babyBluePrimary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class EditPresetPage extends StatefulWidget {
  final Map preset;
  final CatatanController controller;

  const EditPresetPage({
    super.key,
    required this.preset,
    required this.controller,
  });

  @override
  State<EditPresetPage> createState() => _EditPresetPageState();
}

class _EditPresetPageState extends State<EditPresetPage> {
  late String _jenisTransaksi;
  late TextEditingController _namaController;
  late TextEditingController _nominalController;
  late TextEditingController _deskripsiController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _jenisTransaksi = widget.preset['jenis'] ?? 'Pengeluaran';
    _namaController = TextEditingController(
      text: widget.preset['nama_catatan'] ?? '',
    );
    _nominalController = TextEditingController(
      text: (widget.preset['jumlah'] as double).toInt().toString(),
    );
    _deskripsiController = TextEditingController(
      text: widget.preset['deskripsi'] ?? '',
    );
  }

  Future<void> _simpanPerubahanPreset() async {
    final nama = _namaController.text.trim();
    final jumlah = double.tryParse(
      _nominalController.text.replaceAll('.', '').replaceAll(',', ''),
    );

    if (nama.isEmpty || jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama catatan dan nominal wajib diisi dengan valid!'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await widget.controller.updatePreset(
      presetId: widget.preset['preset_id'],
      jenis: _jenisTransaksi,
      namaCatatan: nama,
      jumlah: jumlah,
      deskripsi: _deskripsiController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context, true);
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
          'Edit Preset',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.creamCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: ['Pemasukan', 'Pengeluaran'].map((jenis) {
                  final isSelected = _jenisTransaksi == jenis;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _jenisTransaksi = jenis),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.babyBluePrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          jenis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nama Catatan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama catatan',
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.babyBlueSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.babyBluePrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jumlah',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Masukkan nominal',
                prefixText: 'Rp ',
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.babyBlueSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.babyBluePrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deskripsi (opsional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan keterangan',
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.babyBlueSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.babyBluePrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _simpanPerubahanPreset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.babyBluePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIREFRAME TENGAH: HALAMAN DETAIL TRANSAKSI (EDIT & HAPUS)
// =========================================================================
class DetailTransaksiPage extends StatefulWidget {
  final Map transaksi;
  final String userId;
  final CatatanController controller;

  const DetailTransaksiPage({
    super.key,
    required this.transaksi,
    required this.userId,
    required this.controller,
  });

  @override
  State<DetailTransaksiPage> createState() => _DetailTransaksiPageState();
}

class _DetailTransaksiPageState extends State<DetailTransaksiPage> {
  bool _isDeleting = false;

  String _formatRupiah(double jumlah) {
    final intVal = jumlah.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intVal.length - 1; i >= 0; i--) {
      buffer.write(intVal[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return 'Rp. ${buffer.toString().split('').reversed.join()}';
  }

  String _formatTanggal(DateTime date) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  IconData _getCategoryIcon(String? kategori, String jenis) {
    if (jenis == 'Pemasukan') return Icons.account_balance_wallet_rounded;
    switch (kategori) {
      case 'Makanan & Minuman':
        return Icons.restaurant_rounded;
      case 'Transportasi':
        return Icons.directions_car_rounded;
      case 'Kebutuhan Harian / Pokok':
        return Icons.shopping_cart_rounded;
      case 'Hiburan / Gaya Hidup':
        return Icons.sports_esports_rounded;
      case 'Kesehatan':
        return Icons.medical_services_rounded;
      case 'Pendidikan':
        return Icons.school_rounded;
      case 'Fashion':
        return Icons.checkroom_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Future<void> _konfirmasiHapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Transaksi?',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Text(
          'Catatan "${widget.transaksi['nama_catatan']}" akan dihapus permanen dan saldo akan dihitung ulang.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      setState(() => _isDeleting = true);
      final res = await widget.controller.deleteTransaksi(
        transaksiId: widget.transaksi['id'],
        jenis: widget.transaksi['jenis'],
        userId: widget.userId,
      );
      print('Delete res: $res');
      setState(() => _isDeleting = false);

      if (res['success'] == true && mounted) {
        Navigator.pop(context, {'refresh': true, 'message': res['message']});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPemasukan = widget.transaksi['jenis'] == 'Pemasukan';
    final DateTime tanggal = widget.transaksi['tanggal'] is DateTime
        ? widget.transaksi['tanggal']
        : DateTime.tryParse(widget.transaksi['tanggal'].toString()) ?? DateTime.now();
    final String deskripsi = (widget.transaksi['deskripsi'] ?? '').toString().trim();

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
          'Detail Transaksi',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Kartu Detail Transaksi (Sesuai Wireframe Tengah)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.creamCard, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isPemasukan
                              ? const Color(0xFFE8F5E9)
                              : AppColors.babyBlueLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getCategoryIcon(
                            widget.transaksi['kategori'] ?? 'Lainnya',
                            widget.transaksi['jenis'],
                          ),
                          color: isPemasukan
                              ? AppColors.incomeGreen
                              : AppColors.babyBluePrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.transaksi['nama_catatan'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.transaksi['jenis'],
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isPemasukan ? '+' : '-'}${_formatRupiah(widget.transaksi['jumlah'])}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isPemasukan
                                  ? AppColors.incomeGreen
                                  : AppColors.expenseRed,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTanggal(tanggal),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.creamCard, thickness: 1.2),
                  ),
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.transaksi['kategori'] ?? (isPemasukan ? 'Pemasukan' : 'Lainnya'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deskripsi.isEmpty ? '-' : deskripsi,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Edit & Hapus (Sesuai Wireframe Tengah)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final hasilEdit = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTransaksiPage(
                            transaksi: widget.transaksi,
                            userId: widget.userId,
                            controller: widget.controller,
                          ),
                        ),
                      );
                      if (hasilEdit != null && hasilEdit is Map && hasilEdit['refresh'] == true && mounted) {
                        Navigator.pop(context, hasilEdit);
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.babyBluePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _konfirmasiHapus,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: _isDeleting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.expenseRed),
                          )
                        : const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
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
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIREFRAME KANAN: HALAMAN EDIT TRANSAKSI (PRE-FILLED DATA SEBELUMNYA)
// =========================================================================
class EditTransaksiPage extends StatefulWidget {
  final Map transaksi;
  final String userId;
  final CatatanController controller;

  const EditTransaksiPage({
    super.key,
    required this.transaksi,
    required this.userId,
    required this.controller,
  });

  @override
  State<EditTransaksiPage> createState() => _EditTransaksiPageState();
}

class _EditTransaksiPageState extends State<EditTransaksiPage> {
  late String _jenisTransaksi;
  late String _selectedKategori;
  late DateTime _selectedDate;
  late TextEditingController _namaController;
  late TextEditingController _nominalController;
  late TextEditingController _deskripsiController;
  bool _isSaving = false;

  final List<String> _kategoriPengeluaran = [
    'Makanan & Minuman',
    'Transportasi',
    'Kebutuhan Harian / Pokok',
    'Hiburan / Gaya Hidup',
    'Kesehatan',
    'Pendidikan',
    'Fashion',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill seluruh nilai yang telah diinput user sebelumnya (Sesuai Keterangan Wireframe)
    _jenisTransaksi = widget.transaksi['jenis'] ?? 'Pengeluaran';
    final katAwal = widget.transaksi['kategori'] ?? 'Makanan & Minuman';
    _selectedKategori = _kategoriPengeluaran.contains(katAwal) ? katAwal : 'Lainnya';
    _selectedDate = widget.transaksi['tanggal'] is DateTime
        ? widget.transaksi['tanggal']
        : DateTime.tryParse(widget.transaksi['tanggal'].toString()) ?? DateTime.now();
    _namaController = TextEditingController(text: widget.transaksi['nama_catatan'] ?? '');
    final double nominalAwal = double.tryParse(widget.transaksi['jumlah'].toString()) ?? 0.0;
    _nominalController = TextEditingController(
      text: nominalAwal.toInt().toString(),
    );
    _deskripsiController = TextEditingController(text: widget.transaksi['deskripsi'] ?? '');
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.babyBluePrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _prosesSimpanEdit() async {
    final errorMsg = widget.controller.validateForm(
      namaCatatan: _namaController.text,
      nominalText: _nominalController.text,
      jenis: _jenisTransaksi,
      kategori: _selectedKategori,
      tanggal: _selectedDate,
    );

    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.expenseRed),
      );
      return;
    }

    setState(() => _isSaving = true);

    final rawJumlah = _nominalController.text
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    final parsedJumlah = double.tryParse(rawJumlah);
    if (parsedJumlah == null || parsedJumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah harus diisi dengan angka yang valid!'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final res = await widget.controller.simpanEdit(
      transaksiId: int.parse(widget.transaksi['id'].toString()),
      userId: widget.userId,
      jenisLama: widget.transaksi['jenis'],
      jenisBaru: _jenisTransaksi,
      namaCatatan: _namaController.text.trim(),
      jumlah: parsedJumlah,
      kategori: _selectedKategori,
      tanggal: _selectedDate,
      deskripsi: _deskripsiController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (res['success'] == true) {
        Navigator.pop(context, {'refresh': true, 'message': res['message']});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: AppColors.expenseRed),
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
          'Edit Transaksi',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Switch Pemasukan | Pengeluaran
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.creamCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: ['Pemasukan', 'Pengeluaran'].map((jenis) {
                  final isSelected = _jenisTransaksi == jenis;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _jenisTransaksi = jenis),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.babyBluePrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          jenis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Nama Catatan',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama catatan',
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
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Jumlah',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Masukkan nominal',
                prefixText: 'Rp ',
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
              ),
            ),
            const SizedBox(height: 16),

            if (_jenisTransaksi == 'Pengeluaran') ...[
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: InputDecoration(
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
                ),
                items: _kategoriPengeluaran
                    .map((kat) => DropdownMenuItem(value: kat, child: Text(kat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedKategori = val);
                },
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Tanggal',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.babyBlueSoft),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.babyBluePrimary),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(color: AppColors.textDark, fontSize: 15),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Deskripsi (opsional)',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan keterangan',
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
              ),
            ),
            const SizedBox(height: 28),

            // Tombol Batal & Simpan
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
                    onPressed: _isSaving ? null : _prosesSimpanEdit,
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
}
