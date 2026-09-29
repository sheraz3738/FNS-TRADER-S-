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

  void addProduct() {
    FirebaseFirestore.instance.collection('products').add({
      'name': nameCtrl.text,
      'price': priceCtrl.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    nameCtrl.clear(); priceCtrl.clear();
    Navigator.pop(context);
  }

  Future<void> printA4(Map orderData, String invNo) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (c) {
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text("FNS TRADERS", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text("BA BA FALAK NAZ & SON'S TRADERS")),
        pw.Center(child: pw.Text("بابا فلک ناز رحمتہ اللہ علیہ اینڈ سنز ٹریڈرز")),
        pw.Divider(),
        pw.Text("Invoice No: $invNo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text("Date: ${DateTime.now().toString().substring(0,19)}"),
        pw.SizedBox(height: 20),
        pw.Text("Total: Rs. ${orderData['total']?? 0}", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 30),
        pw.Center(child: pw.Text("THANK YOU - FNS TRADERS")),
      ]);
    }));
    await Printing.layoutPdf(onLayout: (f) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FNS ADMIN"), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Column(
        children: [
          // FINAL SCROLLING - ENGLISH + URDU AS PER YOUR DEMAND
          Container(width: double.infinity, color: Color(0xFF0D47A1), padding: EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text("   WELCOME TO FNS TRADERS | BA BA FALAK NAZ & SON'S TRADERS | بابا فلک ناز رحمتہ اللہ علیہ اینڈ سنز ٹریڈرز   ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),

          Container(color: Colors.white, width: double.infinity, padding: EdgeInsets.all(10), child: Image.asset('fns_logo.png', height: 90)),

          Container(width: double.infinity, color: Colors.green[700], padding: EdgeInsets.all(8), child: Text("مَا شَاءَ اللهُ لَا قُوَّةَ إِلَّا بِاللَّهِ", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),

          Padding(padding: EdgeInsets.all(8), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: Icon(Icons.add), label: Text("Add Product"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: (){
            showDialog(context: context, builder: (c)=> AlertDialog(title: Text("Add Product"), content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: priceCtrl, decoration: InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            ]), actions: [ElevatedButton(onPressed: addProduct, child: Text("Save"))]));
          }))),

          Expanded(child: StreamBuilder(stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(), builder: (c,s){
            if(!s.hasData) return Center(child: CircularProgressIndicator());
            return ListView.builder(itemCount: s.data!.docs.length, itemBuilder: (c,i){
              var doc = s.data!.docs[i]; var data = doc.data() as Map; String invNo = doc.id.substring(0,6).toUpperCase();
              return Card(margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Padding(padding: EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Invoice No: $invNo", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("TOTAL: Rs. ${data['total']??0}", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(icon: Icon(Icons.print), label: Text("A4 Print"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: ()=> printA4(data, invNo))),
                  SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(icon: Icon(Icons.receipt_long), label: Text("Thermal 80mm"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), onPressed: ()=> printA4(data, invNo))),
                ])
              ])));
            });
          }))
        ],
      ),
    );
  }
}
