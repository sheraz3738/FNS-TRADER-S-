import 'package:flutter/material.dart';

void main() => runApp(const FNSApp());

class FNSApp extends StatelessWidget {
  const FNSApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FNS TRADERS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FNS TRADERS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: Icon(Icons.local_pharmacy, size: 80, color: Color(0xFF0D47A1))),
          const SizedBox(height: 10),
          const Center(child: Text('FNS TRADERS', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
          const Center(child: Text('Quality Medicines Distributor', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 20),
          _productCard('Hydryllin Syrup', 'Cough & Cold - 120ml', 'Rs. 185'),
          _productCard('Pulmonol Syrup', 'Chest Congestion - 120ml', 'Rs. 195'),
          _productCard('Gravinate Tablet', 'Nausea & Vomiting', 'Rs. 120'),
          _productCard('Arinac Forte', 'Pain & Flu', 'Rs. 250'),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), padding: const EdgeInsets.all(16)),
            onPressed: () {},
            child: const Text('Place Order', style: TextStyle(color: Colors.white, fontSize: 18)),
          )
        ],
      ),
    );
  }

  static Widget _productCard(String name, String desc, String price) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Color(0xFF0D47A1)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
      ),
    );
  }
}
