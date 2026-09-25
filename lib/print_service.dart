import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PrintService {
  static void printA4Bill(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      logoImage = null;
    }

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (c) {
        return pw.Column(
          children: [
            if (logoImage!= null) pw.Center(child: pw.Image(logoImage, width: 110, height: 110)),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text("BA BA FALAK NAZ & SON'S TRADER'S", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text("Plot L 34, Sector 8/D K.I.A Karachi", style: pw.TextStyle(fontSize: 11))),
            pw.Center(child: pw.Text("Call / Whatsapp: 0334-3738405", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            pw.Divider(thickness: 2),
            pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("Order No: ${data['orderNo']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Date: ${data['date']}"),
              pw.Text("Customer: ${data['customerName']} | Store: ${data['storeName']}"),
              pw.Text("Mobile: ${data['mobile']}"),
              pw.Text("Address: ${data['address']}"),
            ])),
            pw.Spacer(),

            pw.Divider(thickness: 1),
            pw.SizedBox(height: 6),
            pw.Center(child: pw.Text("Please check your goods, quantity and expiry date before leaving the counter.", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text("No responsibility of supplier after goods leave the shop.", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text("Goods once sold will not be taken back or exchanged.", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),

            pw.SizedBox(height: 14),
            // --- YE AAP WALI NAYI LINE ---
            pw.Center(child: pw.Text("We Believe On Truth in Business", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic))),

            pw.SizedBox(height: 12),
            pw.Center(child: pw.Text("Thank You", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text("Visit Again", style: pw.TextStyle(fontSize: 12))),
          ],
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static void printThermalBill(BuildContext context, Map<String, dynamic> data) {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("تھرمل پرنٹر"),
      content: StreamBuilder<List<ScanResult>>(stream: FlutterBluePlus.scanResults, builder: (c, snap){
        var list = snap.data?? [];
        if(list.isEmpty) return Text("Printer search ho raha hai...");
        return SizedBox(height: 200, width: 300, child: ListView.builder(itemCount: list.length, itemBuilder: (c,i){
          var r = list[i];
          return ListTile(title: Text(r.device.name.isEmpty? "Unknown": r.device.name), onTap: (){
            FlutterBluePlus.stopScan();
            Navigator.pop(ctx);
            printA4Bill(data);
          });
        }));
      }),
    ));
  }
}
