class TargetKeuangan {
  // Atribut Private (-)
  final int? _targetId;
  final int _userId;
  final String _nama;
  final double _jumlahTarget;
  final double _progres;
  final DateTime _deadline;

  // Constructor
  TargetKeuangan({
    int? targetId,
    required int userId,
    required String nama,
    required double jumlahTarget,
    double progres = 0.0,
    required DateTime deadline,
  })  : _targetId = targetId,
        _userId = userId,
        _nama = nama,
        _jumlahTarget = jumlahTarget,
        _progres = progres,
        _deadline = deadline;

  // Public Getters (+)
  int? get targetId => _targetId;
  int get userId => _userId;
  String get nama => _nama;
  double get jumlahTarget => _jumlahTarget;
  double get progres => _progres;
  DateTime get deadline => _deadline;

  // Public Methods (+)
  Future<bool> setTarget() async {
    return true;
  }

  Future<bool> updateProgres(double nominal) async {
    return true;
  }

  double getPersentaseProgres() {
    if (_jumlahTarget == 0) return 0.0;
    return (_progres / _jumlahTarget) * 100;
  }

  Future<bool> isTargetReached() async {
    return _progres >= _jumlahTarget;
  }

  Future<bool> gantiStatus() async {
    return true;
  }
}

// 1. Sub-Entity Target Tabungan
class TargetTabungan extends TargetKeuangan {
  final String _apaTabungan;

  TargetTabungan({
    required int userId,
    required String nama,
    required double jumlahTarget,
    required DateTime deadline,
    required String apaTabungan,
  })  : _apaTabungan = apaTabungan,
        super(userId: userId, nama: nama, jumlahTarget: jumlahTarget, deadline: deadline);

  String get apaTabungan => _apaTabungan;
}

// 2. Sub-Entity Target Pemasukan
class TargetPemasukan extends TargetKeuangan {
  final String _apaPemasukan;

  TargetPemasukan({
    required int userId,
    required String nama,
    required double jumlahTarget,
    required DateTime deadline,
    required String apaPemasukan,
  })  : _apaPemasukan = apaPemasukan,
        super(userId: userId, nama: nama, jumlahTarget: jumlahTarget, deadline: deadline);

  String get apaPemasukan => _apaPemasukan;
}

// 3. Sub-Entity Target Pengeluaran (Limit Harian & Notifikasi)
class TargetPengeluaran extends TargetKeuangan {
  final double _limitHarian;
  final int _persentasePeringatan; // Misal: 80% limit tercapai
  final bool _isAlertActive;

  TargetPengeluaran({
    required int userId,
    required String nama,
    required double jumlahTarget,
    required DateTime deadline,
    required double limitHarian,
    int persentasePeringatan = 80,
    bool isAlertActive = true,
  })  : _limitHarian = limitHarian,
        _persentasePeringatan = persentasePeringatan,
        _isAlertActive = isAlertActive,
        super(userId: userId, nama: nama, jumlahTarget: jumlahTarget, deadline: deadline);

  double get limitHarian => _limitHarian;
  int get persentasePeringatan => _persentasePeringatan;
  bool get isAlertActive => _isAlertActive;

  // Method khusus pemicu notifikasi
  bool checkLimitExceeded(double totalPengeluaranHariIni) {
    if (!_isAlertActive) return false;
    double ambangBatas = _limitHarian * (_persentasePeringatan / 100);
    return totalPengeluaranHariIni >= ambangBatas;
  }

  void triggerNotificationAlert() {
    // Memanggil fungsi Push Notification di Flutter/Controller
  }
}