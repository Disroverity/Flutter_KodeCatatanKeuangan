class Preset {
  // Atribut Private (-)
  final int? _presetId;
  final int _userId;
  final double _jumlah; 
  final String _kategori;
  final DateTime _date; 
  final String? _deskripsi;
  final String _namaCatatan;

  // Constructor
  Preset({
    int? presetId,
    required int userId,
    required double jumlah,
    required String kategori,
    required DateTime date,
    String? deskripsi,
    required String namaCatatan,
  })  : _presetId = presetId,
        _userId = userId,
        _jumlah = jumlah,
        _kategori = kategori,
        _date = date,
        _deskripsi = deskripsi,
        _namaCatatan = namaCatatan;

  // Public Getters (+)
  int? get presetId => _presetId;
  int get userId => _userId;
  double get jumlah => _jumlah;
  String get kategori => _kategori;
  DateTime get date => _date;
  String? get deskripsi => _deskripsi;
  String get namaCatatan => _namaCatatan;

  // Public Methods (+)
  Future<bool> addPreset() async {
    return true;
  }

  Future<bool> editPreset() async {
    return true;
  }

  Future<bool> deletePreset() async {
    return true;
  }

  Future<bool> canAddPreset() async {
    return true;
  }
}