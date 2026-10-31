class CatatanKeuangan {
  // Atribut Private (-)
  final int? _catatanId;
  final int _userId;
  final double _totalPemasukan;
  final double _totalPengeluaran;
  final double _saldo;

  // Constructor
  CatatanKeuangan({
    int? catatanId,
    required int userId,
    double totalPemasukan = 0.0,
    double totalPengeluaran = 0.0,
    double saldo = 0.0,
  })  : _catatanId = catatanId,
        _userId = userId,
        _totalPemasukan = totalPemasukan,
        _totalPengeluaran = totalPengeluaran,
        _saldo = saldo;

  // Public Getters (+)
  int? get catatanId => _catatanId;
  int get userId => _userId;
  double get totalPemasukan => _totalPemasukan;
  double get totalPengeluaran => _totalPengeluaran;
  double get saldo => _saldo;

  // Public Methods (+)
  double hitungSaldo() {
    return _totalPemasukan - _totalPengeluaran;
  }

// Mengambil ringkasan/detail berdasarkan string periode ("Bulan Ini", "Hari Ini", dll)
  Map<String, dynamic> getDetailsByPeriode(String periode) {
    return {};
  }

// Mengambil daftar transaksi berdasarkan custom date range (date picker)
  List<dynamic> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return [];
  }

  double getTotalPemasukan() {
    return _totalPemasukan;
  }

  double getTotalPengeluaran() {
    return _totalPengeluaran;
  }

  double getTotalSaldo() {
    return _saldo;
  }
}