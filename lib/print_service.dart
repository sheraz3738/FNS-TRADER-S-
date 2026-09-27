import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class PrintService {

  // 1. PDF PRINT - Normal Receipt
  static Future<void> printPdfReceipt(BuildContext context, Map<String, dynamic> data, Uint8List? logoBytes) async {
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
                pw.Center(child: pw.Image(logoImage!, width: 110, height: 110)),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  "BA BA FALAK NAZ & SON'S TRADER'S",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(child: pw.Text("Plot L 34, Sec 15-B, K.I.A Karachi", style: pw.TextStyle(fontSize: 12))),
              pw.Center(child: pw.Text("Contact: 0334-3738405", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
              pw.Divider(),
              pw.Text("Order No: ${data['orderNo']}", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Date: ${data['date']}", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Customer: ${data['customerName']}", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Mobile: ${data['mobile']}", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Store: ${data['storeName']}", style: pw.TextStyle(fontSize: 14)),
              pw.Divider(),
              pw.Text("Items:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              ...List.generate((data['items'] as List).length, (i) {
                var item = data['items'][i];
                return pw.Text("${i + 1}. ${item['name']} x ${item['qty']} = Rs ${item['total']}");
              }),
              pw.Divider(),
              pw.Text("Grand Total: Rs ${data['total']}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Thank You - Visit Again!", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // 2. BLUETOOTH THERMAL PRINT - 58mm / 80mm
  static Future<void> printBluetoothThermal(Map<String, dynamic> data) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text("BA BA FALAK NAZ & SONS",
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1));
      bytes += generator.text("Plot L 34, Sec 15-B, K.I.A", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("Karachi - 0334-3738405", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.hr();
      bytes += generator.text("Order: ${data['orderNo']}");
      bytes += generator.text("Date: ${data['date']}");
      bytes += generator.text("Customer: ${data['customerName']}");
      bytes += generator.text("Mobile: ${data['mobile']}");
      bytes += generator.text("Store: ${data['storeName']}");
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
          styles: const PosStyles(bold: true, height: PosTextSize.size1, align: PosAlign.right));
      bytes += generator.hr(ch: '=', linesAfter: 1);
      bytes += generator.text("Thank You Visit Again!",
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("FNS Traders", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.cut();

      bool result = await PrintBluetoothThermal.writeBytes(bytes);
      print("Print result: $result");
    } catch (e) {
      print("Bluetooth Print Error: $e");
    }
  }

  // 3. DIALOG - Dono Options Dikhao
  static void showPrintDialog(BuildContext context, Map<String, dynamic> data, Uint8List? logoBytes) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Print Receipt"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text("PDF Print / Share"),
                subtitle: const Text("A4 normal print"),
                onTap: () {
                  Navigator.pop(ctx);
                  printPdfReceipt(context, data, logoBytes);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.bluetooth, color: Colors.blue),
                title: const Text("Bluetooth Thermal"),
                subtitle: const Text("58mm / 80mm printer"),
                onTap: () async {
                  Navigator.pop(ctx);
                  bool enabled = await PrintBluetoothThermal.bluetoothEnabled;
                  if (!enabled) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enable Bluetooth")));
                    return;
                  }

                  List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
                  if (devices.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No paired printer found. Pair from settings")));
                    return;
                  }

                  // Simple - pehle wale paired printer se connect
                  bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: devices.first.macAdress);
                  if (connected) {
                    await printBluetoothThermal(data);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Printing...")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not connect to printer")));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))
          ],
        );
      },
    );
  }
}
