import 'package:flutter/material.dart';

void main() => runApp(const FNSApp());

class FNSApp extends StatelessWidget {
  const FNSApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FNS TRADERS',
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      ),
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
        title: const Text('FNS TRADERS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_pharmacy, size: 40, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FNS TRADERS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Quality Medicines Distributor\nMultan, Pakistan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Our Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          productCard('Hydryllin Syrup', 'Cough & Cold Relief - 120ml', 'Rs. 185', Icons.medication_liquid),
          productCard('Pulmonol Syrup', 'Chest Congestion - 120ml', 'Rs. 195', Icons.medication_liquid),
          productCard('Gravinate Tablet', 'Nausea & Vomiting - 10 Tabs', 'Rs. 120', Icons.medication),
          productCard('Arinac Forte', 'Pain, Flu & Fever - 10 Tabs', 'Rs. 250', Icons.medication),
          productCard('SurBex Z', 'Multivitamin + Zinc', 'Rs. 450', Icons.health_and_safety),
          productCard('Panadol Extra', 'Extra Strength Pain Relief', 'Rs. 180', Icons.medication),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order feature coming soon!')));
              },
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: const Text('Place Order on WhatsApp', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          const Center(child: Text('© 2026 FNS TRADERS - All Rights Reserved', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  static Widget productCard(String name, String desc, String price, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF0D47A1)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 13)),
        ),
      ),
    );
  }
}
