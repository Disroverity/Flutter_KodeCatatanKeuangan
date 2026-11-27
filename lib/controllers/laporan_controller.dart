import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/api_config.dart';

class LaporanController {
  // Hitung rentang tanggal dari pilihan periode ('Hari ini' / 'Minggu ini' / 'Bulan ini')
  Map<String, DateTime> hitungRentangPeriodeDate(String periode) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime startOfRange;

    if (periode == 'Hari ini') {
      startOfRange = DateTime(now.year, now.month, now.day, 0, 0, 0);
    } else if (periode == 'Minggu ini') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      startOfRange = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
    } else {
      // Default: 'Bulan ini'
      startOfRange = DateTime(now.year, now.month, 1, 0, 0, 0);
    }

    return {
      'startDate': startOfRange,
      'endDate': endOfToday,
    };
  }

  // Versi String (YYYY-MM-DD)
  Map<String, String> hitungRentangPeriode(String periode) {
    final range = hitungRentangPeriodeDate(periode);
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      'startDate': fmt(range['startDate']!),
      'endDate': fmt(range['endDate']!),
    };
  }

  //loadDashboardData("Bulan ini") & filterByPeriodeCepat(periode)
  Future<Map<String, dynamic>> loadDashboardData(
      String userId, String periode) async {
    final range = hitungRentangPeriode(periode);
    return await filterByCustomDateRange(
      userId,
      DateTime.parse(range['startDate']!),
      DateTime.parse(range['endDate']!),
    );
  }

  // Langkah 15-17: filterByCustomDateRange(startDate, endDate)
  Future<Map<String, dynamic>> filterByCustomDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final startStr = fmt(startDate);
    final endStr = fmt(endDate);

    try {
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/laporan/$userId?startDate=$startStr&endDate=$endStr');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final ringkasan = body['ringkasan'];
          final Map<String, dynamic> rawKat =
              Map<String, dynamic>.from(body['kategori_pengeluaran'] ?? {});
          final Map<String, double> kategoriMap = {};
          rawKat.forEach((key, val) {
            kategoriMap[key] = double.tryParse(val.toString()) ?? 0.0;
          });

          return {
            'success': true,
            'total_pemasukan':
                double.tryParse(ringkasan['total_pemasukan'].toString()) ?? 0.0,
            'total_pengeluaran':
                double.tryParse(ringkasan['total_pengeluaran'].toString()) ??
                    0.0,
            'saldo': double.tryParse(ringkasan['saldo'].toString()) ?? 0.0,
            'kategori_pengeluaran': kategoriMap,
            'transaksi': body['transaksi'] ?? [],
          };
        }
      }
      return {
        'success': false,
        'total_pemasukan': 0.0,
        'total_pengeluaran': 0.0,
        'saldo': 0.0,
        'kategori_pengeluaran': <String, double>{},
        'transaksi': [],
      };
    } catch (e) {
      return {
        'success': false,
        'total_pemasukan': 0.0,
        'total_pengeluaran': 0.0,
        'saldo': 0.0,
        'kategori_pengeluaran': <String, double>{},
        'transaksi': [],
      };
    }
  }

  //exportToCSV() -> generateFileDocument()
  Future<String> exportToCSV({
    required List transaksi,
    required String periodeLabel,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Tanggal,Jenis,Kategori,Nama Catatan,Nominal,Deskripsi');

    for (var tx in transaksi) {
      final id = tx['id'] ?? '';
      final tgl = tx['tanggal'] ?? '';
      final jenis = tx['jenis'] ?? '';
      final kat = (tx['kategori'] ?? '').toString().replaceAll(',', ' ');
      final namaCatatan = (tx['nama_catatan'] ?? '').toString().replaceAll(',', ' ');
      final nom = tx['jumlah'] ?? 0;
      final desk = (tx['deskripsi'] ?? '').toString().replaceAll(',', ' ');
      buffer.writeln('$id,$tgl,$jenis,$kat,$namaCatatan,$nom,$desk');
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final fileName =
        'Laporan_Keuangan_${periodeLabel.replaceAll(' ', '_')}.csv';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
    return fileName;
  }

  // Langkah 21-23: exportToPDF() -> generateFileDocument()
  Future<String> exportToPDF({
    required double totalPemasukan,
    required double totalPengeluaran,
    required double saldo,
    required Map<String, double> kategoriPengeluaran,
    required List transaksi,
    required List<Map<String, dynamic>> auditLogs,
    required String periodeLabel,
  }) async {
    final pdf = pw.Document();

    String rp(double val) {
      final str = val.toInt().toString();
      String res = '';
      int c = 0;
      for (int i = str.length - 1; i >= 0; i--) {
        res = str[i] + res;
        c++;
        if (c == 3 && i > 0) {
          res = '.$res';
          c = 0;
        }
      }
      return 'Rp $res';
    }

    String bersihkanTeksPdf(dynamic input) {
      final raw = (input ?? '-').toString();
      // Ganti bullet / karakter non-ASCII aneh dengan '-' atau spasi agar tidak jadi kotak silang [X]
      final normalized = raw
          .replaceAll('•', '-')
          .replaceAll('·', '-')
          .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');
      return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Ringkasan Laporan Keuangan',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Periode: $periodeLabel'),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Text('Total Pemasukan'),
                  pw.Text(rp(totalPemasukan),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]),
                pw.Column(children: [
                  pw.Text('Total Pengeluaran'),
                  pw.Text(rp(totalPengeluaran),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]),
                pw.Column(children: [
                  pw.Text('Saldo'),
                  pw.Text(rp(saldo),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Pengeluaran Berdasarkan Kategori',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (kategoriPengeluaran.isEmpty)
            pw.Text('Tidak ada data pengeluaran pada periode ini.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Kategori', 'Nominal', 'Persentase'],
              data: kategoriPengeluaran.entries.map((e) {
                final persen = totalPengeluaran > 0
                    ? ((e.value / totalPengeluaran) * 100).toStringAsFixed(1)
                    : '0.0';
                return [e.key, rp(e.value), '$persen%'];
              }).toList(),
            ),
          pw.SizedBox(height: 18),
          pw.Text('Rincian Transaksi',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'Nama Catatan', 'Jenis', 'Kategori', 'Nominal'],
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            columnWidths: {
              0: const pw.FixedColumnWidth(72), // Tanggal: muat '2026-11-25' 1 baris
              1: const pw.FlexColumnWidth(2.1),  // Judul / Nama Catatan
              2: const pw.FixedColumnWidth(74), // Jenis: muat 'Pengeluaran' 1 baris
              3: const pw.FlexColumnWidth(1.5),  // Kategori
              4: const pw.FixedColumnWidth(72), // Jumlah
            },
            data: transaksi.map((tx) {
              final nom = double.tryParse(tx['jumlah'].toString()) ?? 0.0;
              return [
                tx['tanggal'] ?? '',
                tx['nama_catatan'] ?? '',
                tx['jenis'] ?? '',
                tx['kategori'] ?? '',
                rp(nom),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Timeline Audit Aktivitas & Perubahan Data (Anti-Manipulasi)',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Catatan otomatis seluruh penambahan, pengeditan (nominal lama -> baru), dan penghapusan transaksi secara real-time:',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          auditLogs.isEmpty
              ? pw.Text(
                  'Tidak ada riwayat perubahan atau penghapusan data yang tercatat.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                )
              : pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF37474F),
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8.5),
                  cellAlignment: pw.Alignment.centerLeft,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.2),
                    1: const pw.FlexColumnWidth(2.0),
                    2: const pw.FlexColumnWidth(4.5),
                  },
                  headers: ['Waktu Kejadian', 'Aktivitas', 'Detail Perubahan (Sebelum -> Sesudah)'],
                  data: auditLogs.map((log) {
                    return [
                      bersihkanTeksPdf(log['waktu_format']),
                      bersihkanTeksPdf(log['aksi']),
                      bersihkanTeksPdf(log['detail']),
                    ];
                  }).toList(),
                ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'Ringkasan_Keuangan_${periodeLabel.replaceAll(' ', '_')}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
    return fileName;
  }
}