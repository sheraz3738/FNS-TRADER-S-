import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text("Firebase Error:\n${snapshot.error}", textAlign: TextAlign.center)),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return AdminLoginScreen();
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
