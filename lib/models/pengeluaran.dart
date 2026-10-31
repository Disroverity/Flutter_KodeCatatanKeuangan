class Pengeluaran {
  // Atribut Private (-)
  final int? _pengeluaranId;
  final int _catatanId;
  final double _jumlah;
  final String _kategori;
  final DateTime _date;
  final String? _deskripsi;
  final String _namaCatatan;

  // Constructor
  Pengeluaran({
    int? pengeluaranId,
    required int catatanId,
    required double jumlah,
    required String kategori,
    required DateTime date,
    String? deskripsi,
    required String namaCatatan,
  })  : _pengeluaranId = pengeluaranId,
        _catatanId = catatanId,
        _jumlah = jumlah,
        _kategori = kategori,
        _date = date,
        _deskripsi = deskripsi,
        _namaCatatan = namaCatatan;

  // Public Getters (+)
  int? get pengeluaranId => _pengeluaranId;
  int get catatanId => _catatanId;
  double get jumlah => _jumlah;
  String get kategori => _kategori;
  DateTime get date => _date;
  String? get deskripsi => _deskripsi;
  String get namaCatatan => _namaCatatan;

  // Public Methods (+) - CRUD Lengkap
  Future<bool> addPengeluaran() async {
    return true;
  }

  Future<bool> updatePengeluaran() async {
    return true;
  }

  Future<bool> deletePengeluaran() async {
    return true;
  }
}