class TargetKeuangan {
  final int targetId;
  final String userId;
  final String jenis; // 'Tabungan' atau 'Penghasilan'
  final String namaTarget;
  final double nominalTarget;
  final double nominalTerkumpul;
  final DateTime tenggat;
  final String keterangan;
  final bool batasiHarian;

  TargetKeuangan({
    required this.targetId,
    required this.userId,
    required this.jenis,
    required this.namaTarget,
    required this.nominalTarget,
    required this.nominalTerkumpul,
    required this.tenggat,
    this.keterangan = '',
    this.batasiHarian = false,
  });

  factory TargetKeuangan.fromJson(Map<String, dynamic> json) {
    return TargetKeuangan(
      targetId: int.tryParse(json['target_id'].toString()) ?? 0,
      userId: json['user_id']?.toString() ?? '',
      jenis: json['jenis']?.toString() ?? 'Tabungan',
      namaTarget: json['nama_target']?.toString() ?? '',
      nominalTarget: double.tryParse(json['nominal_target'].toString()) ?? 0.0,
      nominalTerkumpul: double.tryParse(json['nominal_terkumpul'].toString()) ?? 0.0,
      tenggat: DateTime.tryParse(json['tenggat'].toString()) ?? DateTime.now(),
      keterangan: json['keterangan']?.toString() ?? '',
      batasiHarian: json['batasi_harian'] == 1 || json['batasi_harian'] == true,
    );
  }

  // Persentase pencapaian (0.0 - 1.0)
  double get rasioPencapaian {
    if (nominalTarget <= 0) return 0.0;
    return (nominalTerkumpul / nominalTarget).clamp(0.0, 1.0);
  }

  int get persenTercapai => (rasioPencapaian * 100).round();

  double get sisaNominal => (nominalTarget - nominalTerkumpul).clamp(0.0, double.infinity);

  int get sisaHari {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(tenggat.year, tenggat.month, tenggat.day);
    final diff = deadline.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get saranAlokasiHarian {
    if (sisaNominal <= 0) return 0.0;
    final hari = sisaHari <= 0 ? 1 : sisaHari;
    return sisaNominal / hari;
  }
}