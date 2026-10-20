
import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Membuka database Batagogo
  await DatabaseHelper.instance.database;

  runApp(const BatagogoApp());
}

class BatagogoApp extends StatelessWidget {
  const BatagogoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Batagogo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
