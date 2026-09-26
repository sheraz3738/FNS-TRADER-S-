// FINAL FNS APP - Same Design + 4 Side Border + Customer Detail
import 'package:flutter/material.dart';

void main() => runApp(const FNSApp());

class FNSApp extends StatelessWidget {
  const FNSApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // ... (Aapka purana code same rahega)
  // Cart Checkout ke liye ye function add kiya hai

  List<Map<String, dynamic>> orders = []; // Admin me orders ayenge

  void checkoutWithCustomerDetail() {
    TextEditingController nameC = TextEditingController();
    TextEditingController phoneC = TextEditingController();
    TextEditingController storeC = TextEditingController();
    TextEditingController addressC = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("کسٹمر کی تفصیل", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameC, decoration: InputDecoration(labelText: "کسٹمر کا نام")),
              TextField(controller: phoneC, decoration: InputDecoration(labelText: "موبائل نمبر"), keyboardType: TextInputType.phone),
              TextField(controller: storeC, decoration: InputDecoration(labelText: "سٹور / میڈیکل کا نام")),
              TextField(controller: addressC, decoration: InputDecoration(labelText: "مکمل ایڈریس")),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Order ko Admin me save karen
              setState(() {
                orders.add({
                  "name": nameC.text,
                  "phone": phoneC.text,
                  "store": storeC.text,
                  "address": addressC.text,
                  "items": List.from(cart),
                  "date": DateTime.now().toString()
                });
                cart.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("آرڈر کامیاب ہو گیا!")));
            },
            child: Text("آرڈر کنفرم کریں"),
          )
        ],
      ),
    );
  }

  // Side Border Widget
  Widget sideBorder() {
    return Container(
      width: 28,
      color: Color(0xFF1E4DB7),
      child: RotatedBox(
        quarterTurns: 3,
        child: Center(
          child: Text(
            "  BABA FALAK NAZ & SONS TRADERS | 0334-3738405 | WELCOME TO FNS TRADERS  ",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  // ... (baqi aapka purana UI same)
  List<Map<String, dynamic>> cart = [];
  
  @override
  Widget build(BuildContext context) {
    // Main UI with 4 side borders
    return Scaffold(
      body: Column(
        children: [
          // Top Border
          Container(
            height: 30, color: Color(0xFF1E4DB7),
            child: Center(child: Text("BABA FALAK NAZ & SONS TRADERS | WELCOME TO FNS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: Row(
              children: [
                sideBorder(), // Left Border
                Expanded(child: Center(child: Text("آپ کا پرانا والا سارا ڈیزائن یہاں آئے گا\n\nCart me 'checkoutWithCustomerDetail()' call karen"))),
                sideBorder(), // Right Border
              ],
            ),
          ),
          // Bottom Border
          Container(
            height: 30, color: Color(0xFF1E4DB7),
            child: Center(child: Text("CALL: 0334-3738405 | BABA FALAK NAZ & SONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}
