import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PrintService {
  static void printA4Bill(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (c){
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text("BA BA FALAK NAZ & SON'S TRADER'S", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text("بابا فلک ناز رحمۃ اللّٰہ علیہ اینڈ سنز ٹریڈرز", style: pw.TextStyle(fontSize: 16))),
        pw.Divider(thickness: 2),
        pw.Text("Order No: ${data['orderNo']}"),
        pw.Text("Date: ${data['date']}"),
        pw.Text("Customer: ${data['customerName']}"),
        pw.Text("Store: ${data['storeName']}"),
        pw.Text("Mobile: ${data['mobile']}"),
        pw.Text("Address: ${data['address']}"),
        pw.Divider(),
        pw.Text("Thank you for shopping with us!"),
      ]);
    }));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static void printThermalBill(BuildContext context, Map<String, dynamic> data){
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      title: Text("تھرمل پرنٹر منتخب کریں"),
      content: StreamBuilder<List<ScanResult>>(stream: FlutterBluePlus.scanResults, builder: (c, snap){
        var list = snap.data?? [];
        if(list.isEmpty) return Text("بلوٹوتھ پرنٹر تلاش ہو رہا ہے...");
        return SizedBox(height: 200, width: 300, child: ListView.builder(itemCount: list.length, itemBuilder: (c,i){
          var r = list[i];
          return ListTile(title: Text(r.device.name.isEmpty? "Unknown": r.device.name), onTap: (){
            FlutterBluePlus.stopScan();
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${r.device.name} سے پرنٹ ہو رہا ہے...")));
          });
        }));
      }),
    ));
  }
}
