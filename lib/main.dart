import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'checkout_screen.dart';
import 'admin_login_screen.dart';

// یہ آپ کی پروڈکٹ لسٹ ہے جو ایڈمن کنٹرول کرے گا
List<Map<String, dynamic>> allProducts = [
  {"name": "Dal Chana", "price": 250, "stock": 50, "isAvailable": true, "image": ""},
  {"name": "Cheeni", "price": 150, "stock": 100, "isAvailable": true, "image": ""},
];

void main() {
  runApp(const FnsApp());
}

class FnsApp extends StatelessWidget {
  const FnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FinalMainScreen(),
    );
  }
}

class FinalMainScreen extends StatelessWidget {
  final String scrollingText = " BA BA FALAK NAZ & SON'S TRADER'S | بابا فلک ناز رحمۃ اللّٰہ علیہ اینڈ سنز ٹریڈرز | Welcome to FNS TRADER'S | BA BA FALAK NAZ & SON'S TRADER'S | بابا فلک ناز رحمۃ اللّٰہ علیہ اینڈ سنز ٹریڈرز | Welcome to FNS TRADER'S ";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: Color(0xFF0D47A1), width: 5)),
        child: Column(
          children: [
            Container(
              height: 45,
              color: Color(0xFF0D47A1),
              child: Marquee(
                text: scrollingText,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                scrollAxis: Axis.horizontal,
                blankSpace: 50,
                velocity: 45,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Icon(Icons.storefront, size: 80, color: Color(0xFF0D47A1)),
                  Text("FNS TRADERS", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allProducts.length,
                      itemBuilder: (context, i) {
                        var p = allProducts[i];
                        return ListTile(
                          leading: p['image']!= ""? Image.network(p['image'], width: 50, errorBuilder: (c,e,s)=>Icon(Icons.image)) : Icon(Icons.shopping_bag, color: Color(0xFF0D47A1)),
                          title: Text(p['name']),
                          subtitle: Text("Price: ${p['price']} | Stock: ${p['stock']} | ${p['isAvailable']? "Available":"Out of Stock"}"),
                          trailing: Icon(Icons.check_circle, color: p['isAvailable']? Colors.green: Colors.red),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), minimumSize: Size(double.infinity, 50)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen())),
                          child: Text("نیا آرڈر بنائیں / New Order", style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: Size(double.infinity, 50)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminLoginScreen())),
                          child: Text("ایڈمن پینل کھولیں", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
