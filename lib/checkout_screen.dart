import 'package:flutter/material.dart';
import 'print_service.dart';
import 'dart:typed_data';

class CheckoutScreen extends StatefulWidget {
  final String? shopName;
  final String? customerName;
  final String? mobile;
  final String? address;
  final Map<String, dynamic>? orderData;
  final Uint8List? logoBytes;

  const CheckoutScreen({
    super.key, 
    this.shopName,
    this.customerName,
    this.mobile,
    this.address,
    this.orderData, 
    this.logoBytes
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool isPrinting = false;

  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();
    // Agar Signup/Login se aaya hai to wahi details use karo, warna purana orderData
    if (widget.orderData != null) {
      data = widget.orderData!;
    } else {
      data = {
        "orderNo": "FNS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
        "date": DateTime.now().toString(),
        "customerName": widget.customerName ?? "Walk-in Customer",
        "shopName": widget.shopName ?? "FNS Customer",
        "mobile": widget.mobile ?? "0334-3738405",
        "address": widget.address ?? "Baldia Town, Karachi",
        "total": 2150,
        "items": [
          {"name": "Surf Excel 1KG", "qty": 2, "total": 1700},
          {"name": "Oil 1L", "qty": 1, "total": 450},
        ],
      };
    }
  }

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
    double total = 0;
    if(data['total'] != null){
      total = double.tryParse(data['total'].toString()) ?? 0;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.shopName ?? data['shopName'] ?? "FNS Traders")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Center(child: Column(children: const [
              Text("FNS TRADERS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text("Baldia Town, Karachi - 0334-3738405", style: TextStyle(fontSize: 12)),
            ])),
            const Divider(thickness: 2),
            
            Text("Order: ${data['orderNo']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // CUSTOMER DETAILS BLOCK - FINAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Customer Details:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Name: ${data['customerName']}"),
                Text("Shop: ${data['shopName']}"),
                Text("Mobile: ${data['mobile']}"),
                Text("Address: ${data['address']}"),
              ]),
            ),
            
            const SizedBox(height: 15),
            const Divider(),
            const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: (data['items'] as List).length,
                itemBuilder: (ctx, i) {
                  var item = data['items'][i];
                  return ListTile(
                    dense: true,
                    title: Text(item['name'].toString()),
                    subtitle: Text("Qty: ${item['qty']}"),
                    trailing: Text("Rs ${item['total']}"),
                  );
                },
              ),
            ),
            
            // TOTAL SAB SE NEECHE - FINAL
            const Divider(thickness: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text("TOTAL: Rs $total", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
            const SizedBox(height: 15),

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
                    label: const Text("Thermal 80mm"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: isPrinting ? null : () => handlePrint("Thermal"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
