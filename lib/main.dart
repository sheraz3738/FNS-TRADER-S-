import 'package:flutter/material.dart';
import 'admin_screen.dart';

void main() {
  // Firebase ko abhi hataya hai taake white screen khatam ho
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FNS Admin',
      home: AdminScreen(),
    );
  }
}
