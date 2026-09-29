import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'checkout_screen.dart';

class CustomerScreen extends StatefulWidget {
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<Map<String, dynamic>> cart = [];
  String search = "";

  void addToCart(doc) {
    setState(() {
      cart.add({'id': doc.id, 'name': doc['name'], 'price': int.tryParse(doc['price'].toString()) ?? 0});
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${doc['name']} Cart me add ho gaya")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // BLUE SCROLLING
            Container(width: double.infinity, color: Color(0xFF0D47A1), padding: EdgeInsets.all(8),
              child: Text("WELCOME TO FNS TRADERS | BABA FALAK NAZ & SONS | بابا فلک ناز", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            
            // LOGO - Aapka fns_logo.png
            Container(color: Colors.white, padding: EdgeInsets.all(10), width: double.infinity,
              child: Image.asset('fns_logo.png', height: 110, fit: BoxFit.contain)),

            // GREEN AYAT
            Container(width: double.infinity, color: Colors.green[700], padding: EdgeInsets.all(8),
              child: Text("مَا شَاءَ اللهُ لَا قُوَّةَ إِلَّا بِاللَّهِ", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),

            // SEARCH
            Padding(padding: EdgeInsets.all(10),
              child: TextField(onChanged: (v)=> setState(()=> search = v.toLowerCase()), decoration: InputDecoration(hintText: "Search Products...", prefixIcon: Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),

            Expanded(child: StreamBuilder(stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (c,s){
                if(!s.hasData) return Center(child: CircularProgressIndicator());
                var docs = s.data!.docs.where((d)=> d['name'].toString().toLowerCase().contains(search)).toList();
                if(docs.isEmpty) return Center(child: Text("Koi Product Nahi - Admin se Add Karein"));
                return GridView.builder(padding: EdgeInsets.all(10), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: docs.length, itemBuilder: (c,i){
                    var d = docs[i];
                    return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Column(children: [
                      Expanded(child: Container(decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.vertical(top: Radius.circular(15))), child: Center(child: Icon(Icons.medical_services, size: 50, color: Color(0xFF0D47A1))))),
                      Padding(padding: EdgeInsets.all(8), child: Column(children: [
                        Text(d['name'], maxLines: 1, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Rs. ${d['price']}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: ()=> addToCart(d), child: Text("Add")))
                      ]))
                    ]));
                  });
              })),
          ],
        ),
      ),
      // WHATSAPP BUTTON - SIRF CUSTOMER ME
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: Icon(Icons.chat, color: Colors.white),
        label: Text("WhatsApp", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final Uri url = Uri.parse("https://wa.me/923001234567");
          if(await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart (${cart.length})"),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Fav"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Bill"),
      ], onTap: (i){
        if(i==1 || i==3){
          Navigator.push(context, MaterialPageRoute(builder: (c)=> CheckoutScreen(cart: cart)));
        }
      }),
    );
  }
}
