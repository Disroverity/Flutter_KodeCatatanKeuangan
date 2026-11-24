import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/laporan_controller.dart';
import 'catatan_page.dart'; // Menggunakan AppColors yang sama

// =========================================================================
// L03-01: PAGE INFORMASI KEUANGAN UTAMA
// =========================================================================
class InformasiKeuanganPage extends StatefulWidget {
  final String userId;

  const InformasiKeuanganPage({super.key, this.userId = 'USR-001'});

  @override
  State<InformasiKeuanganPage> createState() => _InformasiKeuanganPageState();
}

class _InformasiKeuanganPageState extends State<InformasiKeuanganPage> {
  final LaporanController _controller = LaporanController();

  // Ddl_Periode: 'Hari ini' / 'Minggu ini' / 'Bulan ini'
  String _selectedPeriode = 'Bulan ini';
  bool _isLoading = true;

  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  double _saldo = 0;
  Map<String, double> _kategoriPengeluaran = {};
  List _transaksiList = [];

  final List<Color> _chartColors = const [
    Color(0xFF5C9CE6), // Baby Blue Primary
    Color(0xFF81C784), // Soft Green
    Color(0xFFFFB74D), // Soft Amber
    Color(0xFFBA68C8), // Soft Purple
    Color(0xFFE57373), // Soft Coral
    Color(0xFF4DB6AC), // Soft Teal
    Color(0xFF90A4AE), // Cool Grey
  ];

  @override
  void initState() {
    super.initState();
    _muatDataPeriode(_selectedPeriode);
  }

  // Langkah 2-5 & 8-11 Sequence Diagram
  Future<void> _muatDataPeriode(String periode) async {
    setState(() => _isLoading = true);
    final res = await _controller.loadDashboardData(widget.userId, periode);

    if (mounted) {
      setState(() {
        _totalPemasukan = res['total_pemasukan'];
        _totalPengeluaran = res['total_pengeluaran'];
        _saldo = res['saldo'];
        _kategoriPengeluaran =
            Map<String, double>.from(res['kategori_pengeluaran']);
        _transaksiList = res['transaksi'];
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(double amount) {
    final isNeg = amount < 0;
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
    return '${isNeg ? '-' : ''}Rp. $result';
  }

  @override
  Widget build(BuildContext context) {
    final entries = _kategoriPengeluaran.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Informasi Keuangan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _muatDataPeriode(_selectedPeriode),
        color: AppColors.babyBluePrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label & Dropdown Ddl_Periode
              const Text(
                'Periode',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.babyBlueSoft, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriode,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.babyBluePrimary),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    items: ['Hari ini', 'Minggu ini', 'Bulan ini']
                        .map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null && val != _selectedPeriode) {
                        setState(() => _selectedPeriode = val);
                        _muatDataPeriode(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3 Kartu Mini: Pemasukan, Pengeluaran, Saldo (Sesuai Wireframe Kiri)
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Pemasukan',
                      value: _formatRupiah(_totalPemasukan),
                      icon: Icons.arrow_upward_rounded,
                      iconColor: AppColors.incomeGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Pengeluaran',
                      value: _formatRupiah(_totalPengeluaran),
                      icon: Icons.arrow_downward_rounded,
                      iconColor: AppColors.expenseRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryBox(
                      label: 'Saldo',
                      value: _formatRupiah(_saldo),
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: AppColors.babyBluePrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kartu Donut/Pie Chart: Pengeluaran berdasarkan Kategori + Btn_Detail ("Lihat detail")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pengeluaran berdasarkan Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        // Btn_Detail: Lihat detail -> L03-02
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailGrafikPage(
                                  userId: widget.userId,
                                  initialPeriode: _selectedPeriode,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Lihat detail',
                            style: TextStyle(
                              color: AppColors.babyBluePrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    if (_isLoading)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.babyBluePrimary),
                        ),
                      )
                    else ...[
                      // Donut / Pie Chart dengan Total di Tengah
                      Center(
                        child: SizedBox(
                          width: 190,
                          height: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(190, 190),
                                painter: DonutChartPainter(
                                  values: entries.map((e) => e.value).toList(),
                                  colors: _chartColors,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatRupiah(_totalPengeluaran),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Legenda Kategori + Persentase
                      if (entries.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Belum ada data pengeluaran pada periode ini.',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: List.generate(entries.length, (i) {
                            final item = entries[i];
                            final color =
                                _chartColors[i % _chartColors.length];
                            final persen = _totalPengeluaran > 0
                                ? ((item.value / _totalPengeluaran) * 100)
                                    .round()
                                : 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.key,
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$persen%',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.creamCard, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// L03-02: PAGE DETAIL GRAFIK & EKSPOR
// =========================================================================
class DetailGrafikPage extends StatefulWidget {
  final String userId;
  final String initialPeriode;

  const DetailGrafikPage({
    super.key,
    required this.userId,
    this.initialPeriode = 'Bulan ini',
  });

  @override
  State<DetailGrafikPage> createState() => _DetailGrafikPageState();
}

class _DetailGrafikPageState extends State<DetailGrafikPage> {
  final LaporanController _controller = LaporanController();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = true;
  bool _isExporting = false;

  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  double _saldo = 0;
  Map<String, double> _kategoriPengeluaran = {};
  List _transaksiList = [];

  final List<Color> _chartColors = const [
    Color(0xFF5C9CE6),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFFE57373),
    Color(0xFF4DB6AC),
    Color(0xFF90A4AE),
  ];

  @override
  void initState() {
    super.initState();
    final range = _controller.hitungRentangPeriode(widget.initialPeriode);
    _startDate = DateTime.parse(range['startDate']!);
    _endDate = DateTime.parse(range['endDate']!);
    _muatDataRange();
  }

  Future<void> _muatDataRange() async {
    setState(() => _isLoading = true);
    final res = await _controller.filterByCustomDateRange(
        widget.userId, _startDate, _endDate);

    if (mounted) {
      setState(() {
        _totalPemasukan = res['total_pemasukan'];
        _totalPengeluaran = res['total_pengeluaran'];
        _saldo = res['saldo'];
        _kategoriPengeluaran =
            Map<String, double>.from(res['kategori_pengeluaran']);
        _transaksiList = res['transaksi'];
        _isLoading = false;
      });
    }
  }

  // Picker_Date: DateRangePicker (Langkah 14-19 Sequence Diagram)
  Future<void> _pilihRentangTanggal() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _muatDataRange();
    }
  }

  String _formatRupiah(double amount) {
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
    return 'Rp. $result';
  }

  String _formatShortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  // Btn_CSV: Unduh Laporan (CSV)
  Future<void> _handleUnduhCSV() async {
    setState(() => _isExporting = true);
    final label =
        '${_formatShortDate(_startDate)} - ${_formatShortDate(_endDate)}';
    final fileName = await _controller.exportToCSV(
      transaksi: _transaksiList,
      periodeLabel: label,
    );
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan CSV "$fileName" berhasil dibuat!'),
          backgroundColor: AppColors.babyBluePrimary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Btn_PDF: Ekspor Ringkasan (PDF)
  Future<void> _handleEksporPDF() async {
    setState(() => _isExporting = true);
    final label =
        '${_formatShortDate(_startDate)} - ${_formatShortDate(_endDate)}';
    final fileName = await _controller.exportToPDF(
      totalPemasukan: _totalPemasukan,
      totalPengeluaran: _totalPengeluaran,
      saldo: _saldo,
      kategoriPengeluaran: _kategoriPengeluaran,
      transaksi: _transaksiList,
      periodeLabel: label,
    );
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ringkasan PDF "$fileName" berhasil diekspor!'),
          backgroundColor: AppColors.babyBluePrimary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _kategoriPengeluaran.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

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
          'Detail Grafik',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          children: [
            // Picker_Date: Range Kalender (Sesuai Wireframe Kanan Atas)
            InkWell(
              onTap: _pilihRentangTanggal,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.babyBlueSoft, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.babyBluePrimary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_formatShortDate(_startDate)}  -  ${_formatShortDate(_endDate)}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: CircularProgressIndicator(
                    color: AppColors.babyBluePrimary),
              )
            else ...[
              // Kartu 1: Donut Chart + Legenda di Samping Kanan (Sesuai Wireframe Kanan Atas)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.creamCard, width: 1.5),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 135,
                      height: 135,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(135, 135),
                            painter: DonutChartPainter(
                              values: entries.map((e) => e.value).toList(),
                              colors: _chartColors,
                              strokeWidth: 24,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _formatRupiah(_totalPengeluaran),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: entries.isEmpty
                          ? const Text(
                              'Belum ada pengeluaran.',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(entries.length, (i) {
                                final item = entries[i];
                                final color =
                                    _chartColors[i % _chartColors.length];
                                final persen = _totalPengeluaran > 0
                                    ? ((item.value / _totalPengeluaran) * 100)
                                        .round()
                                    : 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.key,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$persen%',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kartu 2: Bar Chart Pengeluaran per Kategori (Sesuai Wireframe Kanan Bawah)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.creamCard, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perbandingan Pengeluaran Kategori',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (entries.isEmpty)
                      const SizedBox(
                        height: 150,
                        child: Center(
                          child: Text(
                            'Belum ada data grafik batang.',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 195,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(entries.length, (i) {
                            final item = entries[i];
                            final color =
                                _chartColors[i % _chartColors.length];
                            final ratio = maxVal > 0 ? (item.value / maxVal) : 0.0;
                            final barHeight = (ratio * 130).clamp(12.0, 130.0);
                            final labelK = item.value >= 1000
                                ? '${(item.value / 1000).round()}k'
                                : '${item.value.toInt()}';

                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      labelK,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 350),
                                      width: 28,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(14),
                                          bottom: Radius.circular(6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 28,
                                      child: Text(
                                        item.key,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Btn_CSV & Btn_PDF (Sesuai Wireframe Kanan Bawah)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : _handleUnduhCSV,
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
                      label: const Text(
                        'Unduh Laporan\n(CSV)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.babyBlueLight,
                        foregroundColor: AppColors.babyBluePrimary,
                        side: const BorderSide(color: AppColors.babyBlueSoft),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _handleEksporPDF,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text(
                        'Ekspor Ringkasan\n(PDF)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.babyBluePrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// CustomPainter untuk Donut/Pie Chart dengan Pemisah Putih Antar Bagian
class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  DonutChartPainter({
    required this.values,
    required this.colors,
    this.strokeWidth = 34,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = values.fold<double>(0, (sum, v) => sum + v);

    if (total <= 0 || values.isEmpty) {
      final emptyPaint = Paint()
        ..color = AppColors.creamCard
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }

    double startAngle = -math.pi / 2;
    final gapAngle = values.length > 1 ? 0.03 : 0.0;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect,
        startAngle + (gapAngle / 2),
        math.max(0.01, sweepAngle - gapAngle),
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}