import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("FNS TRADERS"),
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 100, color: Colors.green),
              SizedBox(height: 20),
              Text("APP OPEN HO GAYI!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Ab Firebase ka masla khatam ho gaya hai"),
              SizedBox(height: 30),
              Text("BA BA FALAK NAZ & SONS", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("0334-3738405"),
            ],
          ),
        ),
      ),
    );
  }
}
