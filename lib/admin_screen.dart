import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminScreen extends StatefulWidget {
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String search = "";

  Widget _header() {
    return Column(
      children: [
        // 1. TOP BLUE PATTI - MARQUEE
        Container(
          width: double.infinity,
          color: Color(0xFF0D47A1),
          padding: EdgeInsets.symmetric(vertical: 7),
          child: Text(
            "BABA FALAK NAZ & SONS TRADERS | WELCOME TO FNS TRADERS | بابا فلک ناز رحمۃ اللّٰہ علیہ اینڈ سنز ٹریڈرز",
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        // 2. GREEN PATTI
        Container(
          width: double.infinity,
          color: Colors.green[700],
          padding: EdgeInsets.symmetric(vertical: 9),
          child: Text(
            "مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        // 3. FNS LOGO CARD - NO NUMBER - ONLY LOGO
        Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Row(
            children: [
              Text("FNS", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("بابا فلک ناز اینڈ سنز ٹریڈرز", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text("BABA FALAK NAZ & SONS TRADERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ])),
              Icon(Icons.verified, color: Colors.green)
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editProduct(String id, Map<String, dynamic> data) async {
    final name = TextEditingController(text: data['name']?.toString() ?? '');
    final price = TextEditingController(text: data['price']?.toString() ?? '');
    final stock = TextEditingController(text: data['stock']?.toString() ?? '');
    final image = TextEditingController(text: data['imageUrl']?.toString() ?? '');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit product'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
        TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock')),
        TextField(controller: image, decoration: const InputDecoration(labelText: 'Image URL')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))],
    ));
    if (ok == true && name.text.trim().isNotEmpty && int.tryParse(price.text) != null && int.tryParse(stock.text) != null) {
      await FirebaseFirestore.instance.collection('products').doc(id).update({
        'name': name.text.trim(), 'price': int.parse(price.text), 'stock': int.parse(stock.text),
        'imageUrl': image.text.trim(), 'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    name.dispose(); price.dispose(); stock.dispose(); image.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          _header(),
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(hintText: "Search Item...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (c, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());
                var docs = snap.data!.docs.where((d) => d['name'].toString().toLowerCase().contains(search.toLowerCase())).toList();
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    var p = docs[i].data() as Map;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(Icons.medication),
                        title: Text(p['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Rs. ${p['price'] ?? ''} | Stock: ${p['stock'] ?? ''}"),
                        trailing: IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _editProduct(docs[i].id, Map<String, dynamic>.from(p))),
                      ),
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
