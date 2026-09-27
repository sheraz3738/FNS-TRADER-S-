import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class PrintService {

  // ===== Option 2 - A4 BILL (aapka purana naam) =====
  static Future<void> printA4Bill(Map<String, dynamic> data, {Uint8List? logoBytes}) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;
    if (logoBytes != null) {
      logoImage = pw.MemoryImage(logoBytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Center(child: pw.Image(logoImage!, width: 100, height: 100)),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text("BA BA FALAK NAZ & SON'S TRADER'S",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text("Plot L 34, Sec 15-B, K.I.A Karachi")),
              pw.Center(child: pw.Text("0334-3738405", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Divider(),
              pw.Text("Order: ${data['orderNo']}"),
              pw.Text("Date: ${data['date']}"),
              pw.Text("Customer: ${data['customerName']}"),
              pw.Text("Mobile: ${data['mobile']}"),
              pw.Text("Store: ${data['storeName']}"),
              pw.Divider(),
              pw.Text("Items:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...List.generate((data['items'] as List).length, (i) {
                var item = data['items'][i];
                return pw.Text("${i+1}. ${item['name']} x ${item['qty']} = Rs ${item['total']}");
              }),
              pw.Divider(),
              pw.Text("Total: Rs ${data['total']}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Thank You!", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // PDF ka wrapper jisko context chahiye (aapke code ke liye)
  static Future<void> printPdfReceipt(BuildContext context, Map<String, dynamic> data, Uint8List? logoBytes) async {
    await printA4Bill(data, logoBytes: logoBytes);
  }

  // ===== Option 2 - THERMAL BILL (aapka purana naam) =====
  static Future<void> printThermalBill(BuildContext context, Map<String, dynamic> data) async {
    await showPrintDialog(context, data, null);
  }

  static Future<void> printBluetoothThermal(Map<String, dynamic> data) async {
    try {
      CapabilityProfile profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text("BA BA FALAK NAZ & SONS",
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.text("Plot L 34, Sec 15-B, K.I.A Karachi", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("0334-3738405", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.hr();
      bytes += generator.text("Order: ${data['orderNo']}");
      bytes += generator.text("Date: ${data['date']}");
      bytes += generator.text("Customer: ${data['customerName']}");
      bytes += generator.text("Mobile: ${data['mobile']}");
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);

      for (var item in (data['items'] as List)) {
        bytes += generator.row([
          PosColumn(text: item['name'].toString(), width: 6),
          PosColumn(text: item['qty'].toString(), width: 2),
          PosColumn(text: "Rs ${item['total']}", width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.hr();
      bytes += generator.text("Grand Total: Rs ${data['total']}",
          styles: const PosStyles(bold: true, align: PosAlign.right));
      bytes += generator.hr(ch: '=', linesAfter: 1);
      bytes += generator.text("Thank You!", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.cut();

      await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint("Print Error: $e");
    }
  }

  static void showPrintDialog(BuildContext context, Map<String, dynamic> data, Uint8List? logoBytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Print Receipt"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("PDF Print"),
              onTap: () {
                Navigator.pop(ctx);
                printA4Bill(data, logoBytes: logoBytes);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bluetooth, color: Colors.blue),
              title: const Text("Bluetooth Printer"),
              onTap: () async {
                Navigator.pop(ctx);
                bool enabled = await PrintBluetoothThermal.bluetoothEnabled;
                if (!enabled) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enable Bluetooth")));
                  return;
                }
                List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
                if (devices.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No paired printer")));
                  return;
                }
                bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: devices.first.macAdress);
                if (connected) {
                  await printBluetoothThermal(data);
                }
              },
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }
}
