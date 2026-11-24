import 'package:flutter/material.dart';
import '../controllers/target_controller.dart';
import '../models/target_keuangan.dart';
import 'catatan_page.dart'; // Menggunakan AppColors

String formatRupiahTarget(double amount) {
  final str = amount.abs().toInt().toString();
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

// =========================================================================
// L04-01: DAFTAR TARGET KEUANGAN
// =========================================================================
class TargetKeuanganPage extends StatefulWidget {
  final String userId;

  const TargetKeuanganPage({super.key, this.userId = 'USR-001'});

  @override
  State<TargetKeuanganPage> createState() => _TargetKeuanganPageState();
}

class _TargetKeuanganPageState extends State<TargetKeuanganPage> {
  final TargetController _controller = TargetController();

  String _selectedFilter = 'Semua'; // btnFilter: Semua / Tabungan / Penghasilan
  bool _isLoading = true;

  List<TargetKeuangan> _targets = [];
  bool _isLimitAktif = false;
  double _jumlahLimit = 100000;
  int _ambangPersen = 80;
  bool _notifPush = true;
  double _pengeluaranHariIni = 0;

  @override
  void initState() {
    super.initState();
    _muatDataTarget();
  }

  Future<void> _muatDataTarget() async {
    setState(() => _isLoading = true);
    final res = await _controller.ambilDaftarTarget(widget.userId);
    if (mounted) {
      setState(() {
        _targets = List<TargetKeuangan>.from(res['targets'] ?? []);
        _isLimitAktif = res['is_aktif'] ?? false;
        _jumlahLimit = res['jumlah_limit'] ?? 100000.0;
        _ambangPersen = res['ambang_persen'] ?? 80;
        _notifPush = res['notif_push'] ?? true;
        _pengeluaranHariIni = res['pengeluaran_hari_ini'] ?? 0.0;
        _isLoading = false;
      });
    }
  }

  List<TargetKeuangan> get _filteredTargets {
    if (_selectedFilter == 'Semua') return _targets;
    return _targets.where((t) => t.jenis == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final limitRatio = _jumlahLimit > 0
        ? (_pengeluaranHariIni / _jumlahLimit).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Target Keuangan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _muatDataTarget,
        color: AppColors.babyBluePrimary,
        child: Column(
          children: [
            // 1. KARTU BIRU: Panel Limit Pengeluaran Hari Ini (Di posisi paling atas seperti Saldo Tercatat)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Limit Pengeluaran Hari Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!_isLimitAktif) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Nonaktif',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      InkWell(
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LimitPengeluaranHarianPage(
                                userId: widget.userId,
                                controller: _controller,
                                initialAktif: _isLimitAktif,
                                initialLimit: _jumlahLimit,
                                initialAmbang: _ambangPersen,
                                initialNotifPush: _notifPush,
                                pengeluaranHariIni: _pengeluaranHariIni,
                              ),
                            ),
                          );
                          if (updated == true) _muatDataTarget();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Atur',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatRupiahTarget(_pengeluaranHariIni),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' / ${formatRupiahTarget(_jumlahLimit)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: limitRatio,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        limitRatio >= (_ambangPersen / 100) ? const Color(0xFFFFD54F) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. TOMBOL AKSI UTAMA: + Tambah Target (Full Width seperti + Catatan Baru)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final added = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TambahTargetPage(
                          userId: widget.userId,
                          controller: _controller,
                        ),
                      ),
                    );
                    if (added == true) _muatDataTarget();
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: const Text(
                    '+ Tambah Target',
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
            ),

            const SizedBox(height: 18),

            // 3. FILTER CHIPS: Semua / Tabungan / Penghasilan (Persis seperti Filter di Catatan Keuangan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['Semua', 'Tabungan', 'Penghasilan'].map((jenis) {
                  final isSelected = _selectedFilter == jenis;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(jenis),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = jenis),
                      selectedColor: AppColors.babyBluePrimary,
                      backgroundColor: AppColors.creamCard,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.babyBluePrimary : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Daftar Kartu Target (itmTarget)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.babyBluePrimary))
                  : _filteredTargets.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada target keuangan.\nTekan "+ Tambah" untuk membuat target baru.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _filteredTargets.length,
                          itemBuilder: (context, index) {
                            final item = _filteredTargets[index];
                            final isTabungan = item.jenis == 'Tabungan';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () async {
                                    // Membuka Detail Target (L04-03)
                                    final refresh = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailTargetPage(
                                          target: item,
                                          controller: _controller,
                                          isLimitAktif: _isLimitAktif,
                                          jumlahLimit: _jumlahLimit,
                                          ambangPersen: _ambangPersen,
                                          notifPush: _notifPush,
                                          pengeluaranHariIni: _pengeluaranHariIni,
                                        ),
                                      ),
                                    );
                                    if (refresh == true) _muatDataTarget();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: AppColors.creamCard, width: 1.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: isTabungan
                                                    ? AppColors.babyBlueLight
                                                    : const Color(0xFFE8F5E9),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                isTabungan
                                                    ? Icons.savings_outlined
                                                    : Icons.trending_up_rounded,
                                                color: isTabungan
                                                    ? AppColors.babyBluePrimary
                                                    : AppColors.incomeGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.namaTarget,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.jenis,
                                                    style: const TextStyle(
                                                      color: AppColors.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${item.persenTercapai}%',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.babyBluePrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.chevron_right_rounded,
                                                color: AppColors.textMuted, size: 20),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // pbTarget: Progress bar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: item.rasioPencapaian,
                                            minHeight: 7,
                                            backgroundColor: AppColors.creamCard,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              isTabungan
                                                  ? AppColors.babyBluePrimary
                                                  : AppColors.incomeGreen,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${formatRupiahTarget(item.nominalTerkumpul)} dari ${formatRupiahTarget(item.nominalTarget)}',
                                              style: const TextStyle(
                                                  fontSize: 12, color: AppColors.textMuted),
                                            ),
                                            Text(
                                              '${item.sisaHari} hari lagi',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// L04-02: TAMBAH TARGET (DAN MODE EDIT TARGET)
// =========================================================================
class TambahTargetPage extends StatefulWidget {
  final String userId;
  final TargetController controller;
  final TargetKeuangan? existingTarget; // Jika diisi, berfungsi sebagai Form Edit

  const TambahTargetPage({
    super.key,
    required this.userId,
    required this.controller,
    this.existingTarget,
  });

  @override
  State<TambahTargetPage> createState() => _TambahTargetPageState();
}

class _TambahTargetPageState extends State<TambahTargetPage> {
  late String _jenisTarget;
  late TextEditingController _namaController;
  late TextEditingController _nominalController;
  late TextEditingController _terkumpulController;
  late TextEditingController _keteranganController;
  DateTime? _tenggat;
  bool _batasiHarian = false;
  String? _pesanError; // lblPesanError (L04-02)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTarget;
    _jenisTarget = t?.jenis ?? 'Tabungan';
    _namaController = TextEditingController(text: t?.namaTarget ?? '');
    _nominalController = TextEditingController(
        text: t != null ? t.nominalTarget.toInt().toString() : '');
    _terkumpulController = TextEditingController(
        text: t != null ? t.nominalTerkumpul.toInt().toString() : '0');
    _keteranganController = TextEditingController(text: t?.keterangan ?? '');
    _tenggat = t?.tenggat;
    _batasiHarian = t?.batasiHarian ?? false;
  }

  Future<void> _pilihTenggat() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tenggat ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
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
      setState(() {
        _tenggat = picked;
        _pesanError = null;
      });
    }
  }

  Future<void> _prosesSimpan() async {
    final err = widget.controller.validasiDataTarget(
      namaTarget: _namaController.text,
      nominalText: _nominalController.text,
      tenggat: _tenggat,
      terkumpulText: _terkumpulController.text,
    );

    if (err != null) {
      setState(() => _pesanError = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.expenseRed),
      );
      return;
    }

    setState(() {
      _pesanError = null;
      _isSaving = true;
    });

    final nominal = double.parse(
        _nominalController.text.replaceAll('.', '').replaceAll(',', '').trim());
    final terkumpul = double.tryParse(
            _terkumpulController.text.replaceAll('.', '').replaceAll(',', '').trim()) ??
        0.0;

    final Map<String, dynamic> res;
    if (widget.existingTarget == null) {
      res = await widget.controller.simpanTarget(
        userId: widget.userId,
        jenis: _jenisTarget,
        namaTarget: _namaController.text.trim(),
        nominalTarget: nominal,
        nominalTerkumpul: terkumpul,
        tenggat: _tenggat!,
        keterangan: _keteranganController.text.trim(),
        batasiHarian: _batasiHarian,
      );
    } else {
      res = await widget.controller.updateTarget(
        targetId: widget.existingTarget!.targetId,
        jenis: _jenisTarget,
        namaTarget: _namaController.text.trim(),
        nominalTarget: nominal,
        nominalTerkumpul: terkumpul,
        tenggat: _tenggat!,
        keterangan: _keteranganController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Target berhasil disimpan!'),
            backgroundColor: AppColors.babyBluePrimary,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _pesanError = res['message']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTarget != null;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Target' : 'Tambah Target',
          style: const TextStyle(
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
            // tabJenisTarget: Tabungan / Penghasilan
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.creamCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: ['Tabungan', 'Penghasilan'].map((jenis) {
                  final isSelected = _jenisTarget == jenis;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _jenisTarget = jenis),
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
            const SizedBox(height: 18),

            // txtNamaTarget
            const Text('Nama Target',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: 'Contoh: Laptop Baru',
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

            // txtJumlahTarget
            const Text('Jumlah Target',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '5000000',
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

            // Nominal Terkumpul (Progres saat ini)
            const Text('Nominal Terkumpul Saat Ini',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _terkumpulController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
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

            // dtTenggat: Jangka Waktu (Tenggat)
            const Text('Jangka Waktu (Tenggat)',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pilihTenggat,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _pesanError != null && _tenggat == null
                        ? AppColors.expenseRed
                        : AppColors.babyBlueSoft,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.babyBluePrimary),
                    const SizedBox(width: 10),
                    Text(
                      _tenggat == null
                          ? 'DD/MM/YYYY'
                          : '${_tenggat!.day.toString().padLeft(2, '0')}/${_tenggat!.month.toString().padLeft(2, '0')}/${_tenggat!.year}',
                      style: TextStyle(
                        color: _tenggat == null ? AppColors.textMuted : AppColors.textDark,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // lblPesanError (L04-02)
            if (_pesanError != null) ...[
              const SizedBox(height: 6),
              Text(
                _pesanError!,
                style: const TextStyle(
                  color: AppColors.expenseRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // txtKeterangan
            const Text('Keterangan (Opsional)',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _keteranganController,
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
            const SizedBox(height: 16),

            // swBatasiHarian: Batasi pengeluaran harian (Hanya saat Tambah Target)
            if (!isEdit)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.babyBlueLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.babyBlueSoft),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batasi pengeluaran harian',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Aktifkan limit dan notifikasi peringatan',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _batasiHarian,
                      activeColor: AppColors.babyBluePrimary,
                      onChanged: (val) => setState(() => _batasiHarian = val),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 26),

            // btnBatal & btnSimpan
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
                    onPressed: _isSaving ? null : _prosesSimpan,
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

// =========================================================================
// L04-03: DETAIL TARGET (STATEFUL AGAR PROGRES LANGSUNG TER-UPDATE)
// =========================================================================
class DetailTargetPage extends StatefulWidget {
  final TargetKeuangan target;
  final TargetController controller;
  final bool isLimitAktif;
  final double jumlahLimit;
  final int ambangPersen;
  final bool notifPush;
  final double pengeluaranHariIni;

  const DetailTargetPage({
    super.key,
    required this.target,
    required this.controller,
    required this.isLimitAktif,
    required this.jumlahLimit,
    required this.ambangPersen,
    required this.notifPush,
    required this.pengeluaranHariIni,
  });

  @override
  State<DetailTargetPage> createState() => _DetailTargetPageState();
}

class _DetailTargetPageState extends State<DetailTargetPage> {
  late TargetKeuangan _target;
  bool _adaPerubahan = false;

  @override
  void initState() {
    super.initState();
    _target = widget.target;
  }

  String _formatTenggat(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _konfirmasiHapus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Target?',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text('Target "${_target.namaTarget}" akan dihapus secara permanen.',
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await widget.controller.deleteTarget(_target.targetId);
      if (res['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: AppColors.babyBluePrimary),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _tampilkanDialogTambahProgres() async {
    final TextEditingController nominalInputCtrl = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    final isTabungan = _target.jenis == 'Tabungan';
    final judulDialog = isTabungan ? 'Tambah Tabungan' : 'Tambah Pencapaian';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.creamBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Text(
                judulDialog,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target: ${_target.namaTarget}\nSisa target: ${formatRupiahTarget(_target.sisaNominal)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nominalInputCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nominal Tambahan',
                      hintText: 'Contoh: 100000',
                      prefixText: 'Rp ',
                      errorText: errorText,
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [50000, 100000, 500000].map((val) {
                      final label = val >= 1000 ? '+${val ~/ 1000}rb' : '+$val';
                      return ActionChip(
                        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.babyBlueLight,
                        labelStyle: const TextStyle(color: AppColors.babyBluePrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.babyBlueSoft),
                        ),
                        onPressed: () {
                          final current = double.tryParse(
                                  nominalInputCtrl.text.replaceAll('.', '').replaceAll(',', '')) ??
                              0;
                          nominalInputCtrl.text = (current + val).toInt().toString();
                          setDialogState(() => errorText = null);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final clean = nominalInputCtrl.text
                              .replaceAll('.', '')
                              .replaceAll(',', '')
                              .trim();
                          final val = double.tryParse(clean);

                          if (val == null || val <= 0) {
                            setDialogState(() {
                              errorText = 'Masukkan nominal valid lebih dari 0';
                            });
                            return;
                          }

                          setDialogState(() {
                            errorText = null;
                            isSubmitting = true;
                          });

                          final res = await widget.controller.tambahProgresTarget(
                            targetId: _target.targetId,
                            tambahanNominal: val,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);

                          if (mounted) {
                            if (res['success'] == true) {
                              // Update langsung progress bar & angka di halaman Detail Target
                              setState(() {
                                _adaPerubahan = true;
                                _target = TargetKeuangan(
                                  targetId: _target.targetId,
                                  userId: _target.userId,
                                  jenis: _target.jenis,
                                  namaTarget: _target.namaTarget,
                                  nominalTarget: _target.nominalTarget,
                                  nominalTerkumpul: _target.nominalTerkumpul + val,
                                  tenggat: _target.tenggat,
                                  keterangan: _target.keterangan,
                                  batasiHarian: _target.batasiHarian,
                                );
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Progres berhasil ditambahkan!'),
                                  backgroundColor: AppColors.babyBluePrimary,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Gagal menambahkan progres! Pastikan server sudah di-restart.'),
                                  backgroundColor: AppColors.expenseRed,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.babyBluePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTabungan = _target.jenis == 'Tabungan';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, _adaPerubahan);
      },
      child: Scaffold(
        backgroundColor: AppColors.creamBackground,
        appBar: AppBar(
          backgroundColor: AppColors.creamBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context, _adaPerubahan),
          ),
          title: const Text(
            'Detail Target',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 19),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Kartu Utama Detail Target
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.creamCard, width: 1.5),
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
                            color: isTabungan ? AppColors.babyBlueLight : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isTabungan ? Icons.savings_outlined : Icons.trending_up_rounded,
                            color: isTabungan ? AppColors.babyBluePrimary : AppColors.incomeGreen,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _target.namaTarget,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                _target.jenis,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiahTarget(_target.nominalTarget),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.babyBluePrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_target.persenTercapai}% tercapai',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        Text(
                          formatRupiahTarget(_target.nominalTerkumpul),
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _target.rasioPencapaian,
                        minHeight: 10,
                        backgroundColor: AppColors.creamCard,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isTabungan ? AppColors.babyBluePrimary : AppColors.incomeGreen,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppColors.creamCard, thickness: 1.2),
                    ),
                    _buildDetailRow('Tenggat', _formatTenggat(_target.tenggat)),
                    const SizedBox(height: 10),
                    _buildDetailRow('Sisa Waktu', '${_target.sisaHari} hari lagi'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Sisa Nominal', formatRupiahTarget(_target.sisaNominal)),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Saran Alokasi Harian', '${formatRupiahTarget(_target.saranAlokasiHarian)} / hari'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: AppColors.creamCard, thickness: 1.2),
                    ),
                    const Text('Keterangan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(
                      _target.keterangan.trim().isEmpty ? '-' : _target.keterangan,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Aksi Cepat: Tambah Progres / Nabung
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _tampilkanDialogTambahProgres,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: Text(
                    isTabungan ? 'Tambah Tabungan / Progres' : 'Tambah Pencapaian Penghasilan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTabungan ? AppColors.babyBluePrimary : AppColors.incomeGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // btnLimitHarian -> L04-04
              InkWell(
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LimitPengeluaranHarianPage(
                        userId: _target.userId,
                        controller: widget.controller,
                        initialAktif: widget.isLimitAktif,
                        initialLimit: widget.jumlahLimit,
                        initialAmbang: widget.ambangPersen,
                        initialNotifPush: widget.notifPush,
                        pengeluaranHariIni: widget.pengeluaranHariIni,
                      ),
                    ),
                  );
                  if (updated == true && mounted) Navigator.pop(context, true);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.babyBlueLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.babyBlueSoft),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          color: AppColors.babyBluePrimary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Limit Pengeluaran Harian',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                            Text(
                              widget.isLimitAktif
                                  ? 'Aktif (${formatRupiahTarget(widget.jumlahLimit)} / hari)'
                                  : 'Belum diaktifkan',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.babyBluePrimary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // btnEdit & btnHapus
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final edited = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TambahTargetPage(
                              userId: _target.userId,
                              controller: widget.controller,
                              existingTarget: _target,
                            ),
                          ),
                        );
                        if (edited == true && mounted) Navigator.pop(context, true);
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
                      onPressed: _konfirmasiHapus,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }
}

// =========================================================================
// L04-04: LIMIT PENGELUARAN HARIAN
// =========================================================================
class LimitPengeluaranHarianPage extends StatefulWidget {
  final String userId;
  final TargetController controller;
  final bool initialAktif;
  final double initialLimit;
  final int initialAmbang;
  final bool initialNotifPush;
  final double pengeluaranHariIni;

  const LimitPengeluaranHarianPage({
    super.key,
    required this.userId,
    required this.controller,
    required this.initialAktif,
    required this.initialLimit,
    required this.initialAmbang,
    required this.initialNotifPush,
    required this.pengeluaranHariIni,
  });

  @override
  State<LimitPengeluaranHarianPage> createState() => _LimitPengeluaranHarianPageState();
}

class _LimitPengeluaranHarianPageState extends State<LimitPengeluaranHarianPage> {
  late bool _aktifLimit;
  late TextEditingController _limitController;
  late int _ambangPersen;
  late bool _notifPush;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _aktifLimit = widget.initialAktif;
    _limitController = TextEditingController(text: widget.initialLimit.toInt().toString());
    _ambangPersen = widget.initialAmbang;
    _notifPush = widget.initialNotifPush;
  }

  double get _currentLimitVal =>
      double.tryParse(_limitController.text.replaceAll('.', '').replaceAll(',', '')) ?? 100000.0;

  Future<void> _simpanPengaturan() async {
    final limitVal = _currentLimitVal;
    if (_aktifLimit && limitVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah limit per hari harus lebih dari 0!'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final res = await widget.controller.saveLimitHarian(
      userId: widget.userId,
      isAktif: _aktifLimit,
      jumlahLimit: limitVal,
      ambangPersen: _ambangPersen,
      notifPush: _notifPush,
    );
    setState(() => _isSaving = false);

    if (res['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: AppColors.babyBluePrimary),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final limitVal = _currentLimitVal;
    final pemicuNominal = limitVal * (_ambangPersen / 100);
    final progressRatio = limitVal > 0 ? (widget.pengeluaranHariIni / limitVal).clamp(0.0, 1.0) : 0.0;

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
          'Limit Pengeluaran Harian',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // swAktifkanLimit
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.babyBluePrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aktifkan limit harian',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Batasi total pengeluaran per hari',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _aktifLimit,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white38,
                    onChanged: (val) => setState(() => _aktifLimit = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // txtJumlahLimit
            const Text('Jumlah Limit per Hari',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
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
            const SizedBox(height: 18),

            // rbAmbang: 70% / 80% / 90% / 100%
            const Text('Ingatkan saya saat pengeluaran mencapai',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [70, 80, 90, 100].map((persen) {
                final isSelected = _ambangPersen == persen;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text('$persen%', textAlign: TextAlign.center),
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _ambangPersen = persen),
                      selectedColor: AppColors.babyBluePrimary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppColors.babyBluePrimary : AppColors.babyBlueSoft,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // swNotifPush
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.creamCard, width: 1.5),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifikasi push',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                        Text('Pengingat saat mendekati atau melebihi limit',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notifPush,
                    activeColor: AppColors.babyBluePrimary,
                    onChanged: (val) => setState(() => _notifPush = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // pnlPengeluaranHariIni
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.creamCard, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengeluaran Hari Ini',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatRupiahTarget(widget.pengeluaranHariIni),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        ' / ${formatRupiahTarget(limitVal)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 8,
                      backgroundColor: AppColors.creamCard,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.babyBluePrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi dikirim saat mencapai ${formatRupiahTarget(pemicuNominal)} ($_ambangPersen%)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // btnBatal & btnSimpan
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
                    onPressed: _isSaving ? null : _simpanPengaturan,
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

// =========================================================================
// L04-05: POP-UP & BANNER NOTIFIKASI LIMIT PENGELUARAN (DIAGRAM 2)
// =========================================================================
Future<void> tampilkanNotifikasiLimitPengeluaran(
  BuildContext context, {
  required Map<String, dynamic> statusLimit,
  VoidCallback? onLihatTransaksi,
}) async {
  final double totalHariIni = statusLimit['totalHariIni'] ?? 0.0;
  final double limit = statusLimit['limit'] ?? 100000.0;
  final double sisaLimit = statusLimit['sisaLimit'] ?? 0.0;
  final int persen = statusLimit['persen'] ?? 80;
  final bool notifPush = statusLimit['notifPush'] ?? true;
  final ratio = limit > 0 ? (totalHariIni / limit).clamp(0.0, 1.0) : 0.0;

  // Banner Push Notifikasi di atas (notifPush)
  if (notifPush) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        backgroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Color(0xFFFFD54F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Limit harian hampir tercapai: ${formatRupiahTarget(totalHariIni)} dari ${formatRupiahTarget(limit)}.',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pop-up Dialog Peringatan (dlgLimit)
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.expenseRed, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pengeluaran Mendekati Limit',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Pengeluaran hari ini sudah mencapai $persen% dari limit harian. Sisa limit ${formatRupiahTarget(sisaLimit)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.creamCard,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.expenseRed),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatRupiahTarget(totalHariIni)} | ${formatRupiahTarget(limit)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (onLihatTransaksi != null) onLihatTransaksi();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.babyBlueSoft),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lihat Transaksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.babyBluePrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mengerti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}