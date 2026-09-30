import 'dart:io';
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
  final nameEnCtrl = TextEditingController();
  final nameUrCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final detailCtrl = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool isSaving = false;

  Future<void> addProduct() async {
    if(nameEnCtrl.text.isEmpty || priceCtrl.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("English Name aur Price lazmi hai")));
      return;
    }
    setState(() => isSaving = true);
    String imageUrl = "";
    try{
      if(_imageFile!= null){
        var ref = FirebaseStorage.instance.ref().child("products/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }
    }catch(e){}

    await FirebaseFirestore.instance.collection('products').add({
      'name': nameEnCtrl.text.trim(),
      'name_ur': nameUrCtrl.text.trim(),
      'name_lower': nameEnCtrl.text.toLowerCase(),
      'name_ur_lower': nameUrCtrl.text.toLowerCase(),
      'price': priceCtrl.text.trim(),
      'discount_price': discountCtrl.text.trim(),
      'detail': detailCtrl.text.trim(),
      'image': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() { isSaving = false; _imageFile = null; });
    nameEnCtrl.clear(); nameUrCtrl.clear(); priceCtrl.clear(); discountCtrl.clear(); detailCtrl.clear();
    Navigator.pop(context);
  }

  Future<void> printA4(Map orderData, String invNo) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (c) {
      return pw.Column(children: [
        pw.Center(child: pw.Text("FNS TRADERS", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text("BA BA FALAK NAZ & SON'S TRADERS")),
        pw.Text("Invoice No: $invNo"),
        pw.SizedBox(height: 20),
        pw.Text("Total: Rs. ${orderData['total']?? 0}", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      ]);
    }));
    await Printing.layoutPdf(onLayout: (f) => pdf.save());
  }

  Future<void> printThermal80(Map orderData, String invNo) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm),
      build: (c) {
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text("FNS TRADERS", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
        pw.Divider(),
        pw.Text("Bill No: $invNo", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Text("Total: Rs. ${orderData['total']?? 0}", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Center(child: pw.Text("THANK YOU")),
      ]);
    }));
    await Printing.layoutPdf(onLayout: (f) => pdf.save());
  }

  void showAddProductDialog() {
    _imageFile = null;
    showDialog(context: context, builder: (c)=> StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text("Add Product"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: (){
                      showModalBottomSheet(context: context, builder: (ctx)=> SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(leading: Icon(Icons.camera_alt), title: Text("Camera / Selfie"), onTap: () async { Navigator.pop(ctx); var f = await _picker.pickImage(source: ImageSource.camera); if(f!=null){ setState(()=> _imageFile = File(f.path)); setDialogState(()=> _imageFile = File(f.path));}}),
                        ListTile(leading: Icon(Icons.photo), title: Text("Gallery"), onTap: () async { Navigator.pop(ctx); var f = await _picker.pickImage(source: ImageSource.gallery); if(f!=null){ setState(()=> _imageFile = File(f.path)); setDialogState(()=> _imageFile = File(f.path));}}),
                      ])));
                    },
                    child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)), child: _imageFile == null? Icon(Icons.camera_alt, size: 40) : Image.file(_imageFile!, fit: BoxFit.cover)),
                  ),
                  if(_imageFile!= null)
                    Positioned(top: 0, right: 0, child: InkWell(onTap: (){ setState(()=> _imageFile=null); setDialogState(()=> _imageFile=null); }, child: CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)))),
                ],
              ),
              SizedBox(height: 10),
              TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: "Name English *", border: OutlineInputBorder())),
              SizedBox(height: 8),
              TextField(controller: nameUrCtrl, decoration: InputDecoration(labelText: "نام اردو میں", border: OutlineInputBorder())),
              SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Price *", border: OutlineInputBorder())),
              SizedBox(height: 8),
              TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Discount Price", border: OutlineInputBorder())),
              SizedBox(height: 8),
              TextField(controller: detailCtrl, maxLines: 2, decoration: InputDecoration(labelText: "Detail تفصیل", border: OutlineInputBorder())),
            ]),
          ),
          actions: [ TextButton(onPressed: ()=> Navigator.pop(context), child: Text("Cancel")), isSaving? CircularProgressIndicator() : ElevatedButton(onPressed: addProduct, child: Text("Save")) ]
        );
      }
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FNS ADMIN"), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(width: double.infinity, color: Color(0xFF0D47A1), padding: EdgeInsets.symmetric(vertical: 10), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(" WELCOME TO FNS TRADERS | BA BA FALAK NAZ & SON'S TRADERS | بابا فلک ناز رحمتہ اللہ علیہ اینڈ سنز ٹریڈرز ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          Container(color: Colors.white, width: double.infinity, padding: EdgeInsets.all(10), child: Image.asset('assets/fns_logo.png', height: 90, errorBuilder: (c,e,s)=> Icon(Icons.store, size: 60))),
          Container(width: double.infinity, color: Colors.green[700], padding: EdgeInsets.all(8), child: Text("مَا شَاءَ اللهُ لَا قُوَّةَ إِلَّا بِاللَّهِ", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(8), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: Icon(Icons.add), label: Text("Add Product"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: showAddProductDialog))),
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
                  Expanded(child: ElevatedButton.icon(icon: Icon(Icons.receipt_long), label: Text("Thermal 80mm"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white), onPressed: ()=> printThermal80(data, invNo))),
                ])
              ])));
            });
          }))
        ],
      ),
    );
  }
}
