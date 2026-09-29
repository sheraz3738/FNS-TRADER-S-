import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminScreen extends StatefulWidget {
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  void addProduct(){
    FirebaseFirestore.instance.collection('products').add({
      'name': nameCtrl.text,
      'price': priceCtrl.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    nameCtrl.clear(); priceCtrl.clear();
    Navigator.pop(context);
  }

  Future<void> printA4(Map order) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (c){
      return pw.Column(children: [
        pw.Image(pw.MemoryImage((null as dynamic)), height: 80), // logo
        pw.Text("FNS TRADERS", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text("Invoice No: ${order['id']?? '001'}"),
        pw.Text("Date: ${DateTime.now()}"),
        pw.Divider(),
        pw.Text("TOTAL: Rs. ${order['total']?? ''}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text("Note: ${order['note']?? ''}"),
        pw.SizedBox(height: 20),
        pw.Text("THANK YOU FOR VISITING FNS TRADERS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ]);
    }));
    await Printing.layoutPdf(onLayout: (f)=> pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FNS ADMIN"), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(color: Color(0xFF0D47A1), width: double.infinity, padding: EdgeInsets.all(8), child: Text("WELCOME TO FNS TRADERS | BABA FALAK NAZ", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)),
          Image.asset('fns_logo.png', height: 80),
          Container(color: Colors.green[700], width: double.infinity, padding: EdgeInsets.all(8), child: Text("مَا شَاءَ اللهُ لَا قُوَّةَ إِلَّا بِاللَّهِ", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)),

          Padding(padding: EdgeInsets.all(8), child: ElevatedButton.icon(icon: Icon(Icons.add), label: Text("Add Product"), onPressed: (){
            showDialog(context: context, builder: (c)=> AlertDialog(title: Text("Add Product"), content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: priceCtrl, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            ]), actions: [ElevatedButton(onPressed: addProduct, child: Text("Save"))]));
          })),

          Expanded(child: StreamBuilder(stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
            builder: (c,s){
              if(!s.hasData) return Center(child: CircularProgressIndicator());
              if(s.data!.docs.isEmpty) return Center(child: Text("Koi Order Nahi Hai"));
              return ListView.builder(itemCount: s.data!.docs.length, itemBuilder: (c,i){
                var doc = s.data!.docs[i].data() as Map;
                return Card(margin: EdgeInsets.all(8), child: Padding(padding: EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Invoice No: ${s.data!.docs[i].id.substring(0,6)}", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("TOTAL: Rs. ${doc['total']?? 0}"),
                  SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(icon: Icon(Icons.print), label: Text("A4 Print"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: ()=> printA4(doc))),
                    SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(icon: Icon(Icons.receipt), label: Text("Thermal 80mm"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), onPressed: ()=> printA4(doc))),
                  ])
                ])));
              });
            }))
        ],
      ),
    );
  }
}
