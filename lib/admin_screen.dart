import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminScreen extends StatefulWidget {
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late ScrollController _scrollController;
  Timer? _timer;
  final nameEnCtrl = TextEditingController();
  final nameUrCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool isSaving = false;
  String selectedCategory = "General Item";
  List<String> categories = ["Syrup", "Tablet", "Surgical", "General Item", "BP Operator", "Glucometer", "Other"];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(Duration(milliseconds: 30), (t) {
        if (_scrollController.hasClients) {
          if (_scrollController.offset >= _scrollController.position.maxScrollExtent) {
            _scrollController.jumpTo(0);
          } else {
            _scrollController.jumpTo(_scrollController.offset + 1.2);
          }
        }
      });
    });
  }
  @override
  void dispose() { _timer?.cancel(); _scrollController.dispose(); super.dispose(); }

  Future<void> addProduct() async {
    if (nameEnCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
    setState(() => isSaving = true);
    String imageUrl = "";
    try {
      if (_imageFile!= null) {
        var ref = FirebaseStorage.instance.ref().child("products/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }
    } catch (e) {}
    await FirebaseFirestore.instance.collection('products').add({
      'name': nameEnCtrl.text.trim(),
      'name_ur': nameUrCtrl.text.trim(),
      'price': priceCtrl.text.trim(),
      'discount_price': discountCtrl.text.trim(),
      'category': selectedCategory,
      'image': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() { isSaving = false; _imageFile = null; });
    nameEnCtrl.clear(); nameUrCtrl.clear(); priceCtrl.clear(); discountCtrl.clear();
    Navigator.pop(context);
  }

  Future<void> printBill(Map data, String inv, bool isA4) async {
    final pdf = pw.Document();
    if (isA4) {
      pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (c) => pw.Column(children: [pw.Text("FNS TRADERS - $inv", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 20), pw.Text("Total Rs.${data['total']}")])));
    } else {
      pdf.addPage(pw.Page(pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity), build: (c) => pw.Column(children: [pw.Text("FNS TRADERS"), pw.Text("INV: $inv"), pw.Text("Total Rs.${data['total']}")])));
    }
    await Printing.layoutPdf(onLayout: (f) => pdf.save());
  }

  void showAddDialog() {
    _imageFile = null;
    selectedCategory = categories[3];
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (ctx, setD) {
      return AlertDialog(
        title: Text("Add Product - BP Operator wala"),
        content: SingleChildScrollView(child: Column(children: [
          GestureDetector(onTap: () async { var f = await _picker.pickImage(source: ImageSource.gallery); if (f!= null) { setState(() => _imageFile = File(f.path)); setD(() => _imageFile = File(f.path)); } }, child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(10)), child: _imageFile == null? Icon(Icons.camera_alt, size: 40) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_imageFile!, fit: BoxFit.cover)))),
          SizedBox(height: 10),
          DropdownButtonFormField(value: selectedCategory, items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v){ setState(()=> selectedCategory=v!); setD(()=> selectedCategory=v!); }, decoration: InputDecoration(labelText: "Category *", border: OutlineInputBorder())),
          SizedBox(height: 8),
          TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: "Name English *", border: OutlineInputBorder())),
          SizedBox(height: 8),
          TextField(controller: nameUrCtrl, decoration: InputDecoration(labelText: "نام اردو", border: OutlineInputBorder())),
          SizedBox(height: 8),
          TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Price *", border: OutlineInputBorder())),
          SizedBox(height: 8),
          TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Discount Price", border: OutlineInputBorder())),
        ])),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: Text("Cancel")), isSaving? CircularProgressIndicator(): ElevatedButton(onPressed: addProduct, child: Text("Save"))],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FNS ADMIN - BP Operator"), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Column(children: [
        Container(height: 35, color: Color(0xFF0D47A1), child: ListView(controller: _scrollController, scrollDirection: Axis.horizontal, physics: NeverScrollableScrollPhysics(), children: [Center(child: Text(" WELCOME TO FNS TRADERS | BA BA FALAK NAZ & SON'S TRADERS | بابا فلک ناز رحمتہ اللہ علیہ | 0334-3738405 ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))])),
        Container(color: Colors.white, width: double.infinity, padding: EdgeInsets.all(6), child: Image.asset('fns_logo.png', height: 75, errorBuilder: (c,e,s) => Icon(Icons.store, size: 50))),
        Container(width: double.infinity, color: Colors.green[700], padding: EdgeInsets.all(6), child: Text("مَا شَاءَ اللهُ لَا قُوَّةَ إِلَّا بِاللَّهِ", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: Icon(Icons.add), label: Text("Add Product (BP Operator)"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: showAddDialog))),
        Expanded(child: StreamBuilder(stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(), builder: (c,s){
          if(!s.hasData) return Center(child: CircularProgressIndicator());
          if(s.data!.docs.isEmpty) return Center(child: Text("No Orders"));
          return ListView.builder(itemCount: s.data!.docs.length, itemBuilder: (c,i){ var doc=s.data!.docs[i]; var data=doc.data() as Map; String inv=doc.id.substring(0,6).toUpperCase(); return Card(margin: EdgeInsets.all(6), child: ListTile(title: Text("Invoice: $inv - Rs.${data['total']}"), subtitle: Row(children: [ElevatedButton(onPressed: ()=> printBill(data,inv,true), child: Text("A4 Print")), SizedBox(width:8), ElevatedButton(onPressed: ()=> printBill(data,inv,false), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]), child: Text("80mm Print", style: TextStyle(color: Colors.white)))]))); });
        }))
      ]),
    );
  }
}
