import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/target_keuangan.dart';

typedef ApiResult = Map<String, dynamic>;

class TargetController {
  // Diagram 1 (Langkah 2-6): ambilDaftarTarget(user_id)
  Future<ApiResult> ambilDaftarTarget(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/target/$userId'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List rawTargets = body['targets'] ?? [];
          final targets = rawTargets.map((e) => TargetKeuangan.fromJson(e)).toList();

          final limitRaw = body['limit_harian'] ?? {};
          return {
            'success': true,
            'targets': targets,
            'is_aktif': limitRaw['is_aktif'] == 1 || limitRaw['is_aktif'] == true,
            'jumlah_limit': double.tryParse(limitRaw['jumlah_limit'].toString()) ?? 100000.0,
            'ambang_persen': int.tryParse(limitRaw['ambang_persen'].toString()) ?? 80,
            'notif_push': limitRaw['notif_push'] == 1 || limitRaw['notif_push'] == true,
            'pengeluaran_hari_ini': double.tryParse(body['pengeluaran_hari_ini'].toString()) ?? 0.0,
          };
        }
      }
      return {'success': false, 'targets': <TargetKeuangan>[]};
    } catch (e) {
      return {'success': false, 'targets': <TargetKeuangan>[], 'message': e.toString()};
    }
  }

  // Defensive Programming (L04-02 lblPesanError & Diagram 1 Langkah 13)
  String? validasiDataTarget({
    required String namaTarget,
    required String nominalText,
    required DateTime? tenggat,
    String? terkumpulText,
  }) {
    if (namaTarget.trim().isEmpty) {
      return 'Data belum lengkap, mohon isi nama target';
    }
    final cleanNom = nominalText.replaceAll('.', '').replaceAll(',', '').trim();
    final nominal = double.tryParse(cleanNom);
    if (nominal == null || nominal <= 0) {
      return 'Data belum lengkap, mohon isi jumlah target dengan valid';
    }
    if (tenggat == null) {
      return 'Data belum lengkap, mohon isi tenggat';
    }
    if (terkumpulText != null && terkumpulText.trim().isNotEmpty) {
      final cleanTerkumpul = terkumpulText.replaceAll('.', '').replaceAll(',', '').trim();
      final terkumpul = double.tryParse(cleanTerkumpul);
      if (terkumpul == null || terkumpul < 0) {
        return 'Nominal terkumpul tidak boleh bernilai negatif';
      }
    }
    return null;
  }

  // Diagram 1 (Langkah 12-24): simpanTarget(...)
  Future<ApiResult> simpanTarget({
    required String userId,
    required String jenis,
    required String namaTarget,
    required double nominalTarget,
    double nominalTerkumpul = 0,
    required DateTime tenggat,
    String keterangan = '',
    bool batasiHarian = false,
  }) async {
    final tenggatStr =
        '${tenggat.year}-${tenggat.month.toString().padLeft(2, '0')}-${tenggat.day.toString().padLeft(2, '0')}';

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/target'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'jenis': jenis,
          'nama_target': namaTarget,
          'nominal_target': nominalTarget,
          'nominal_terkumpul': nominalTerkumpul,
          'tenggat': tenggatStr,
          'keterangan': keterangan,
          'batasi_harian': batasiHarian,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // Edit Target (L04-03 btnEdit)
  Future<ApiResult> updateTarget({
    required int targetId,
    required String jenis,
    required String namaTarget,
    required double nominalTarget,
    required double nominalTerkumpul,
    required DateTime tenggat,
    String keterangan = '',
  }) async {
    final tenggatStr =
        '${tenggat.year}-${tenggat.month.toString().padLeft(2, '0')}-${tenggat.day.toString().padLeft(2, '0')}';

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/target/$targetId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jenis': jenis,
          'nama_target': namaTarget,
          'nominal_target': nominalTarget,
          'nominal_terkumpul': nominalTerkumpul,
          'tenggat': tenggatStr,
          'keterangan': keterangan,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui target: $e'};
    }
  }

  // Hapus Target (L04-03 btnHapus)
  Future<ApiResult> deleteTarget(int targetId) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/target/$targetId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus target: $e'};
    }
  }

  // Simpan Pengaturan Limit Harian (L04-04)
  Future<ApiResult> saveLimitHarian({
    required String userId,
    required bool isAktif,
    required double jumlahLimit,
    required int ambangPersen,
    required bool notifPush,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/limit-harian'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'is_aktif': isAktif,
          'jumlah_limit': jumlahLimit,
          'ambang_persen': ambangPersen,
          'notif_push': notifPush,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal menyimpan limit harian: $e'};
    }
  }

  // Diagram 2 (Langkah 6-13): Cek apakah pengeluaran hari ini >= ambang limit
  Future<ApiResult> cekStatusLimitHarian(String userId) async {
    final data = await ambilDaftarTarget(userId);
    if (data['success'] != true) return {'mendekatiLimit': false};

    final bool isAktif = data['is_aktif'] ?? false;
    final bool notifPush = data['notif_push'] ?? true;
    final double limit = data['jumlah_limit'] ?? 100000.0;
    final int ambang = data['ambang_persen'] ?? 80;
    final double totalHariIni = data['pengeluaran_hari_ini'] ?? 0.0;

    if (!isAktif || limit <= 0) {
      return {'mendekatiLimit': false};
    }

    final double persen = (totalHariIni / limit) * 100;
    if (persen >= ambang) {
      return {
        'mendekatiLimit': true,
        'notifPush': notifPush,
        'persen': persen.round(),
        'totalHariIni': totalHariIni,
        'limit': limit,
        'sisaLimit': (limit - totalHariIni).clamp(0.0, double.infinity),
      };
    }
    return {'mendekatiLimit': false};
  }
// Tambah Progres Nominal Terkumpul dari Detail Target (L04-03)
  Future<ApiResult> tambahProgresTarget({
    required int targetId,
    required double tambahanNominal,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/target/$targetId/progres'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tambahan_nominal': tambahanNominal}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal menambahkan progres: $e'};
    }
  }
}