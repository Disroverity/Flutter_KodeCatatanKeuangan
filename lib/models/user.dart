class User {

  final String? _userId;
  final String _namaLengkap;
  final String _username;
  final String _email;
  final String? _nomorTelepon;
  final String? _fotoProfil;

  // Constructor
  User({
    String? userId,
    required String namaLengkap,
    required String username,
    required String email,
    String? nomorTelepon,
    String? fotoProfil,
  })  : _userId = userId,
        _namaLengkap = namaLengkap,
        _username = username,
        _email = email,
        _nomorTelepon = nomorTelepon,
        _fotoProfil = fotoProfil;

  // Public Getters (+)
  String? get userId => _userId;
  String get namaLengkap => _namaLengkap;
  String get username => _username;
  String get email => _email;
  String? get nomorTelepon => _nomorTelepon;
  String? get fotoProfil => _fotoProfil;

  // Factory Constructor dari Response JSON API Login
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id']?.toString(),
      namaLengkap: json['nama_lengkap'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nomorTelepon: json['nomor_telepon'],
      fotoProfil: json['foto_profil'],
    );
  }
}