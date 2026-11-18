class Preset {
  int? presetId;
  String userId;
  String jenis;
  String namaCatatan;
  double jumlah;
  String kategori;
  String deskripsi;

  Preset({
    this.presetId,
    required this.userId,
    required this.jenis,
    required this.namaCatatan,
    required this.jumlah,
    required this.kategori,
    this.deskripsi = '',
  });

  factory Preset.fromJson(Map json) {
    return Preset(
      presetId: json['preset_id'],
      userId: json['user_id']?.toString() ?? '',
      jenis: json['jenis'] ?? 'Pengeluaran',
      namaCatatan: json['nama_catatan'] ?? '',
      jumlah: double.tryParse(json['jumlah'].toString()) ?? 0.0,
      kategori: json['kategori'] ?? 'Lainnya',
      deskripsi: json['deskripsi'] ?? '',
    );
  }

  Map toJson() {
    return {
      'preset_id': presetId,
      'user_id': userId,
      'jenis': jenis,
      'nama_catatan': namaCatatan,
      'jumlah': jumlah,
      'kategori': kategori,
      'deskripsi': deskripsi,
    };
  }
}