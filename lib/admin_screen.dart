// lib/admin_screen.dart - FINAL (No WhatsApp)
import 'package:flutter/material.dart';
import 'print_service.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> allOrders = [
    {
      "orderNo": "FNS-1234", "date": "2026-05-13", "customerName": "Sheraz Bhai",
      "mobile": "0334-3738405", "storeName": "FNS Traders - Baldia Karachi", "total": 2500,
      "items": [{"name": "Rice 5KG", "qty": 2, "total": 1500}, {"name": "Oil 1L", "qty": 1, "total": 1000}]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Column(
            children: [
              Container(color: Color(0xFF0D47A1), width: double.infinity, padding: EdgeInsets.only(top: 35, bottom: 8), child: Center(child: Text("FNS TRADERS - ADMIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
              Container(color: Colors.green, width: double.infinity, padding: EdgeInsets.all(6), child: Center(child: Text("مَا شَاءَ اللّٰہُ لَا قُوَّۃَ إِلَّا بِاللّٰہِ", style: TextStyle(color: Colors.white, fontSize: 13)))),
              TabBar(labelColor: Colors.black, indicatorColor: Color(0xFF0D47A1), tabs: [Tab(icon: Icon(Icons.inventory), text: "Products"), Tab(icon: Icon(Icons.receipt_long), text: "Orders")]),
            ],
          ),
        ),
        body: TabBarView(children: [
          Center(child: Text("Yahan Products Aayenge")),
          ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: allOrders.length,
            itemBuilder: (c, i) {
              var order = allOrders[i];
              return Card(elevation: 3, child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("${order['orderNo']}", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Rs. ${order['total']}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                ]),
                SizedBox(height: 5),
                Text("${order['customerName']} - ${order['mobile']}", style: TextStyle(fontSize: 12)),
                Divider(),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: ()=> PrintService.printA4Bill(order), icon: Icon(Icons.picture_as_pdf, size: 18), label: Text("A4"))),
                  SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white), onPressed: ()=> PrintService.printThermalBill(context, order), icon: Icon(Icons.print, size: 18), label: Text("Thermal"))),
                ])
              Card(
                child: ListTile(
                  leading: const Icon(Icons.rule, color: Colors.green),
                  title: const Text("Order Limit Set Karo"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLimitScreen())),
                 ),
               ),  //.
            },
          )
        ]),
      ),
    );
  }
}
