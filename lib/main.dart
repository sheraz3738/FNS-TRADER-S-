import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin_login_screen.dart'; // <-- YE LINE FIX HAI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FNS Trader Admin',
      theme: ThemeData(primarySwatch: Colors.green),
      home: AdminLoginScreen(), // <-- YE BHI FIX HAI
    );
  }
}
