class CatatanKeuangan {
  // Atribut Private (-)
  final int? _catatanId;
  final String _userId; // Disesuaikan ke String untuk mendukung ID unik (USR-XXX)
  double _totalPemasukan;
  double _totalPengeluaran;
  double _saldo;

  // Constructor
  CatatanKeuangan({
    int? catatanId,
    required String userId,
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
  String get userId => _userId;
  double get totalPemasukan => _totalPemasukan;
  double get totalPengeluaran => _totalPengeluaran;
  double get saldo => _saldo;

  // Public Methods (+) sesuai Sequence Diagram
  double hitungSaldo() {
    _saldo = _totalPemasukan - _totalPengeluaran;
    return _saldo;
  }

  void updateSaldoSetelahTransaksi(String jenis, double nominal) {
    if (jenis == 'Pemasukan') {
      _totalPemasukan += nominal;
    } else {
      _totalPengeluaran += nominal;
    }
    hitungSaldo();
  }

  Map<String, dynamic> getDetailsByPeriode(String periode) {
    return {
      'periode': periode,
      'pemasukan': _totalPemasukan,
      'pengeluaran': _totalPengeluaran,
      'saldo': hitungSaldo(),
    };
  }

  List<dynamic> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return [];
  }

  double getTotalPemasukan() => _totalPemasukan;
  double getTotalPengeluaran() => _totalPengeluaran;
  double getTotalSaldo() => _saldo;
}