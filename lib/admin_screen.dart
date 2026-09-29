import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final limitCtrl = TextEditingController();

  void addProduct() {
    if (nameCtrl.text.isEmpty) return;
    FirebaseFirestore.instance.collection('products').add({
      'name': nameCtrl.text,
      'price': priceCtrl.text.isEmpty? "0" : priceCtrl.text,
      'category': 'General',
      'createdAt': FieldValue.serverTimestamp(),
    });
    nameCtrl.clear(); priceCtrl.clear();
    Navigator.pop(context);
  }

  void saveLimit() {
     FirebaseFirestore.instance.collection('settings').doc('orderLimit').set({'limit': limitCtrl.text});
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Limit Save Ho Gaya")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FNS ADMIN PANEL"), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(width: double.infinity, color: Color(0xFF0D47A1), padding: EdgeInsets.all(8),
            child: Text("BABA FALAK NAZ & SONS TRADERS | بابا فلک ناز اینڈ سنز ٹریڈرز", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Image.asset('fns_logo.png', height: 90, errorBuilder: (a,b,c)=> Icon(Icons.store, size: 70)),
          Container(width: double.infinity, color: Colors.green[700], padding: EdgeInsets.all(8),
            child: Text("مَا شَاءَ اللهُ لَا قُوَّةَ إِلَّا بِاللَّهِ", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),

          Padding(padding: EdgeInsets.all(10), child: Row(children: [
            Expanded(child: TextField(controller: limitCtrl, decoration: InputDecoration(labelText: "Order Limit Rs.", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            SizedBox(width: 8),
            ElevatedButton(onPressed: saveLimit, child: Text("Save Limit"))
          ])),

          Padding(padding: EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton.icon(icon: Icon(Icons.add), label: Text("Add New Product"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
              onPressed: (){ showDialog(context: context, builder: (c)=> AlertDialog(title: Text("Add Product"), content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Product Name")),
                TextField(controller: priceCtrl, decoration: InputDecoration(labelText: "Price Rs."), keyboardType: TextInputType.number),
              ]), actions: [ElevatedButton(onPressed: addProduct, child: Text("Save"))])); })),

          Divider(),
          Expanded(child: StreamBuilder(stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (c,s){
              if(!s.hasData) return Center(child: CircularProgressIndicator());
              return ListView.builder(itemCount: s.data!.docs.length, itemBuilder: (c,i){
                var d = s.data!.docs[i];
                return ListTile(title: Text(d['name']), subtitle: Text("Rs. ${d['price']}"), trailing: IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: ()=> d.reference.delete()));
              });
            })),
        ],
      ),
    );
  }
}
