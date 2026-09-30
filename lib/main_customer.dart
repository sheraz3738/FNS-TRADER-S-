import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'customer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase Error: $e");
  }
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CustomerScreen(),
  ));
}
