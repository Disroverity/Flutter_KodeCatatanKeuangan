import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/api_config.dart';

class LaporanController {
  // Hitung rentang tanggal dari pilihan Ddl_Periode (Hari ini / Minggu ini / Bulan ini)
  Map<String, String> hitungRentangPeriode(String periode) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    if (periode == 'Hari ini') {
      start = DateTime(now.year, now.month, now.day);
    } else if (periode == 'Minggu ini') {
      start = now.subtract(Duration(days: now.weekday - 1));
    } else {
      // Default: 'Bulan ini'
      start = DateTime(now.year, now.month, 1);
    }

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {'startDate': fmt(start), 'endDate': fmt(end)};
  }

  // Langkah 2-4: loadDashboardData("Bulan ini") & filterByPeriodeCepat(periode)
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

  // Langkah 21-23: exportToCSV() -> generateFileDocument()
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
      final judul = (tx['judul'] ?? '').toString().replaceAll(',', ' ');
      final nom = tx['nominal'] ?? 0;
      final desk = (tx['deskripsi'] ?? '').toString().replaceAll(',', ' ');
      buffer.writeln('$id,$tgl,$jenis,$kat,$judul,$nom,$desk');
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
            headers: ['Tanggal', 'Judul', 'Jenis', 'Kategori', 'Nominal'],
            data: transaksi.map((tx) {
              final nom = double.tryParse(tx['nominal'].toString()) ?? 0.0;
              return [
                tx['tanggal'] ?? '',
                tx['judul'] ?? '',
                tx['jenis'] ?? '',
                tx['kategori'] ?? '',
                rp(nom),
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