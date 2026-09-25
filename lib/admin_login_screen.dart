import 'package:flutter/material.dart';
import 'admin_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  var userCtrl = TextEditingController();
  var passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ایڈمن لاگ ان"), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Padding(padding: EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.admin_panel_settings, size: 90, color: Color(0xFF0D47A1)),
        SizedBox(height: 20),
        TextField(controller: userCtrl, decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder())),
        SizedBox(height: 10),
        TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder())),
        SizedBox(height: 20),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), minimumSize: Size(double.infinity, 55)), onPressed: (){
          if(userCtrl.text=="fns" && passCtrl.text=="1234"){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c)=> AdminScreen()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User: fns | Pass: 1234")));
          }
        }, child: Text("Login", style: TextStyle(color: Colors.white))),
      ])),
    );
  }
}
