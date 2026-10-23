import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerScreen extends StatefulWidget {
  @override State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  String search = "";
  Map<String, int> cart = {};

  Widget _header() {
    return Column(
      children: [
        Container(width: double.infinity, color: Color(0xFF0D47A1), padding: EdgeInsets.symmetric(vertical: 7), child: Text("BABA FALAK NAZ & SONS TRADERS | WELCOME TO FNS TRADERS | بابا فلک ناز رحمۃ اللّٰہ علیہ اینڈ سنز ٹریڈرز", textAlign: TextAlign.center, maxLines: 1, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
        Container(width: double.infinity, color: Colors.green[700], padding: EdgeInsets.symmetric(vertical: 9), child: Text("مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
        Container(margin: EdgeInsets.all(10), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]), child: Row(children: [Text("FNS", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("بابا فلک ناز اینڈ سنز ٹریڈرز", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text("BABA FALAK NAZ & SONS TRADERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))]))])),
      ],
    );
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(children: [
        _header(),
        Padding(padding: EdgeInsets.all(10), child: TextField(onChanged: (v) => setState(() => search = v), decoration: InputDecoration(hintText: "Search Medicine...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white))),
        Expanded(child: StreamBuilder(stream: FirebaseFirestore.instance.collection('products').snapshots(), builder: (c, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator());
          var docs = snap.data!.docs.where((d) => d['name'].toString().toLowerCase().contains(search.toLowerCase())).toList();
          return ListView.builder(itemCount: docs.length, itemBuilder: (c, i) {
            var p = docs[i].data() as Map; var id = docs[i].id;
            return Card(margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.shopping_bag)), title: Text(p['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text("Rs. ${p['price'] ?? ''}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(Icons.remove_circle_outline), onPressed: () { setState(() { if ((cart[id] ?? 0) > 0) cart[id] = cart[id]! - 1; }); }), Text("${cart[id] ?? 0}"), IconButton(icon: Icon(Icons.add_circle, color: Colors.green), onPressed: () { setState(() { cart[id] = (cart[id] ?? 0) + 1; }); })])));
          });
        })),
        Padding(padding: EdgeInsets.all(12), child: Row(children: [
          Expanded(child: ElevatedButton.icon(icon: Icon(Icons.chat), label: Text("WhatsApp"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () { launchUrl(Uri.parse("https://wa.me/923343738405"), mode: LaunchMode.externalApplication); })),
          SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(icon: Icon(Icons.smart_toy), label: Text("AI Search"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () {})),
        ]))
      ]),
    );
  }
}
