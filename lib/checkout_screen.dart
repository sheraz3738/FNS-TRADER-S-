import 'package:flutter/material.dart';
import 'print_service.dart';
import 'dart:typed_data';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  final Uint8List? logoBytes;
  const CheckoutScreen({super.key, this.orderData, this.logoBytes});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool isPrinting = false;

  late Map<String, dynamic> data = widget.orderData ?? {
    "orderNo": "FNS-001",
    "date": DateTime.now().toString(),
    "customerName": "Walk-in Customer",
    "mobile": "0334-3738405",
    "storeName": "Main Branch",
    "total": 0,
    "items": [],
  };

  void handlePrint(String type) async {
    setState(() => isPrinting = true);
    try {
      if (type == "A4") {
        await PrintService.printA4Bill(data, logoBytes: widget.logoBytes);
      } else {
        PrintService.printThermalBill(context, data);
      }
    } catch (e) {
      debugPrint("Print Error: $e");
    } finally {
      setState(() => isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout - FNS Traders")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order: ${data['orderNo']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Customer: ${data['customerName']}"),
            Text("Mobile: ${data['mobile']}"),
            Text("Total: Rs ${data['total']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Divider(),
            const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: (data['items'] as List).length,
                itemBuilder: (ctx, i) {
                  var item = data['items'][i];
                  return ListTile(
                    title: Text(item['name'].toString()),
                    subtitle: Text("Qty: ${item['qty']}"),
                    trailing: Text("Rs ${item['total']}"),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDF / A4"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: isPrinting ? null : () => handlePrint("A4"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bluetooth),
                    label: const Text("Thermal"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: isPrinting ? null : () => handlePrint("Thermal"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPrinting ? null : () => PrintService.showPrintDialog(context, data, widget.logoBytes),
                child: const Text("Show Both Options"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
