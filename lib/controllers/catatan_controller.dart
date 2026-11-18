import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/catatan_keuangan.dart';

class CatatanController {
  final List<String> kategoriPengeluaran = [
    'Makanan & Minuman',
    'Transportasi',
    'Kebutuhan Harian / Pokok',
    'Hiburan / Gaya Hidup',
    'Kesehatan',
    'Pendidikan',
    'Fashion',
    'Lainnya',
  ];

  // 1. Ambil daftar transaksi user dari MySQL
  Future<List> fetchTransactions(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transaksi/$userId'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List rawData = body['data'];
          return rawData.map((item) {
            return {
              'id': item['id'],
              'judul': item['judul'] ?? '',
              'jenis': item['jenis'] ?? 'Pengeluaran',
              'kategori': item['kategori'] ?? 'Lainnya',
              'nominal': double.tryParse(item['nominal'].toString()) ?? 0.0,
              'tanggal': DateTime.tryParse(item['tanggal'].toString()) ?? DateTime.now(),
              'deskripsi': item['deskripsi'] ?? '',
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Validasi form input
  String? validateForm({
    required String namaCatatan,
    required String nominalText,
    required String jenis,
    String? kategori,
    required DateTime? tanggal,
  }) {
    if (namaCatatan.trim().isEmpty) {
      return 'Nama catatan wajib diisi!';
    }
    final double? nominal = double.tryParse(
      nominalText.replaceAll('.', '').replaceAll(',', ''),
    );
    if (nominal == null || nominal <= 0) {
      return 'Masukkan nominal jumlah yang valid!';
    }
    if (jenis == 'Pengeluaran' && (kategori == null || kategori.isEmpty)) {
      return 'Pilih kategori pengeluaran terlebih dahulu!';
    }
    if (tanggal == null) {
      return 'Tanggal transaksi wajib dipilih!';
    }
    return null;
  }

  // 3. Simpan transaksi baru (& simpan ke preset jika dicentang)
  Future simpanClicked({
    required CatatanKeuangan catatanKeuangan,
    required String jenis,
    required String namaCatatan,
    required double nominal,
    String? kategori,
    required DateTime tanggal,
    String? deskripsi,
    required bool isPreset,
    required int currentPresetCount,
  }) async {
    try {
      final String formattedDate =
          '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transaksi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': catatanKeuangan.userId,
          'jenis': jenis,
          'nama_catatan': namaCatatan,
          'nominal': nominal,
          'kategori': jenis == 'Pemasukan' ? 'Pemasukan' : kategori,
          'tanggal': formattedDate,
          'deskripsi': deskripsi ?? '',
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        catatanKeuangan.updateSaldoSetelahTransaksi(jenis, nominal);
        
        bool presetDisimpan = false;
        if (isPreset && canAddPreset(currentPresetCount)) {
          await saveNewPreset(
            userId: catatanKeuangan.userId,
            namaCatatan: namaCatatan,
            jenis: jenis,
            jumlah: nominal,
            kategori: kategori,
            deskripsi: deskripsi,
          );
          presetDisimpan = true;
        }

        final Map transaksiBaru = {
          'id': body['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'judul': namaCatatan,
          'jenis': jenis,
          'nominal': nominal,
          'kategori': jenis == 'Pemasukan' ? 'Pemasukan' : kategori,
          'tanggal': tanggal,
          'deskripsi': deskripsi ?? '',
        };

        return {
          'success': true,
          'message': presetDisimpan
              ? 'Transaksi "$namaCatatan" disimpan & ditambahkan ke Preset!'
              : 'Transaksi "$namaCatatan" berhasil disimpan!',
          'data': transaksiBaru,
          'presetAdded': presetDisimpan,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal menyimpan ke database.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  } 

//=========================================================================
//SEQUENCE DIAGRAM: simpanEdit() & deleteTransaksi()
//=========================================================================

  Future<Map<String, dynamic>> simpanEdit({
    required int transaksiId,
    required String userId,
    required String jenisLama,
    required String jenisBaru,
    required String namaCatatan,
    required double nominal,
    required String kategori,
    required DateTime tanggal,
    String? deskripsi,
  }) async {
    try {
      final tanggalStr =
          '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/transaksi/$transaksiId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'jenis_lama': jenisLama,
          'jenis_baru': jenisBaru,
          'nama_catatan': namaCatatan,
          'nominal': nominal,
          'kategori': jenisBaru == 'Pemasukan' ? 'Pemasukan' : kategori,
          'tanggal': tanggalStr,
          'deskripsi': deskripsi ?? '',
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'message': body['message'] ?? 'Gagal memperbarui transaksi'};
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteTransaksi({
    required int transaksiId,
    required String jenis,
    required String userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/transaksi/$jenis/$transaksiId?user_id=$userId'),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'message': body['message'] ?? 'Gagal menghapus transaksi'};
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  // ==============================================================
  // METHOD PRESET
  // ==============================================================

  bool canAddPreset(int currentPresetCount) => currentPresetCount < 10;
  void addPreset(Map transaksi) {}

  // 4. Ambil semua preset milik user dari MySQL
  Future<List> fetchPresets(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/preset/$userId'),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List rawData = body['data'];
          return rawData.map((item) {
            return {
              'preset_id': item['preset_id'],
              'user_id': item['user_id'],
              'jenis': item['jenis'] ?? 'Pengeluaran',
              'nama_catatan': item['nama_catatan'] ?? '',
              'jumlah': double.tryParse(item['jumlah'].toString()) ?? 0.0,
              'kategori': item['kategori'] ?? 'Lainnya',
              'deskripsi': item['deskripsi'] ?? '',
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 5. Simpan preset baru ke MySQL
  Future<void> saveNewPreset({
    required String userId,
    required String namaCatatan,
    required String jenis,
    required double jumlah,
    String? kategori,
    String? deskripsi,
  }) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/preset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'jenis': jenis,
          'nama_catatan': namaCatatan,
          'jumlah': jumlah,
          'kategori': jenis == 'Pemasukan' ? 'Pemasukan' : (kategori ?? 'Lainnya'),
          'deskripsi': deskripsi ?? '',
        }),
      );
    } catch (_) {}
  }

  // 6. Eksekusi Input Cepat dari Preset (Sequence Diagram Langkah 4-12)
  Future executeQuickInput(int presetId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/preset/quick-input'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'preset_id': presetId}),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final item = body['data'];
        return {
          'success': true,
          'message': body['message'],
          'data': {
            'id': item['id'],
            'judul': item['judul'],
            'jenis': item['jenis'],
            'kategori': item['kategori'],
            'nominal': double.tryParse(item['nominal'].toString()) ?? 0.0,
            'tanggal': DateTime.tryParse(item['tanggal'].toString()) ?? DateTime.now(),
            'deskripsi': item['deskripsi'] ?? '',
          },
        };
      }
      return {'success': false, 'message': body['message'] ?? 'Gagal input cepat'};
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  // 7. Edit Preset
  Future<bool> updatePreset({
    required int presetId,
    required String jenis,
    required String namaCatatan,
    required double jumlah,
    String? deskripsi,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/preset/$presetId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jenis': jenis,
          'nama_catatan': namaCatatan,
          'jumlah': jumlah,
          'deskripsi': deskripsi ?? '',
        }),
      );
      final body = jsonDecode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // 8. Delete Preset
  Future<bool> deletePreset(int presetId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/preset/$presetId'),
      );
      final body = jsonDecode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }
  
}