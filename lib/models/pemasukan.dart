class Pemasukan {
  // Atribut Private (-)
  final int? _pemasukanId;
  final int _catatanId;
  final double _jumlah;
  final DateTime _date;
  final String? _deskripsi;
  final String _namaCatatan;

  // Constructor
  Pemasukan({
    int? pemasukanId,
    required int catatanId,
    required double jumlah,
    required DateTime date,
    String? deskripsi,
    required String namaCatatan,
  })  : _pemasukanId = pemasukanId,
        _catatanId = catatanId,
        _jumlah = jumlah,
        _date = date,
        _deskripsi = deskripsi,
        _namaCatatan = namaCatatan;

  // Public Getters (+)
  int? get pemasukanId => _pemasukanId;
  int get catatanId => _catatanId;
  double get jumlah => _jumlah;
  DateTime get date => _date;
  String? get deskripsi => _deskripsi;
  String get namaCatatan => _namaCatatan;

  // Public Methods (+) - CRUD Lengkap
  Future<bool> addPemasukan() async {
    return true;
  }

  Future<bool> updatePemasukan() async {
    return true;
  }

  Future<bool> deletePemasukan() async {
    return true;
  }
}