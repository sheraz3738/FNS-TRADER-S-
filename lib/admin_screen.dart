import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FNS ADMIN - BP Operator"), 
        backgroundColor: Color(0xFF0D47A1), 
        foregroundColor: Colors.white
      ),
      body: Column(children: [
        Container(
          height: 35, 
          color: Color(0xFF0D47A1), 
          child: Center(child: Text(
            " WELCOME TO FNS TRADERS | 0334-3738405 ", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ))
        ),
        SizedBox(height: 20),
        Icon(Icons.store, size: 80, color: Color(0xFF0D47A1)),
        SizedBox(height: 20),
        Text("FNS ADMIN - App Open Ho Gayi!", 
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text("Firebase abhi offline hai, isliye crash nahi hogi.",
          style: TextStyle(color: Colors.green)),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: (){},
          child: Text("Add Product (Test Button)"),
        )
      ]),
    );
  }
}
