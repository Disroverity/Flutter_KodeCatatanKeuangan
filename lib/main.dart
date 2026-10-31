import 'package:flutter/material.dart';
import 'views/auth_page.dart';

void main() {
  runApp(const FinFlowApp());
}

class FinFlowApp extends StatelessWidget {
  const FinFlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow - Catatan Keuangan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthPage(), // Menjadikan halaman Login/Register sebagai layar utama
    );
  }
}