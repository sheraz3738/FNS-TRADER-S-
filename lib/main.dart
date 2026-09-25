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
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
      ),
      home: const FNSHome(),
    );
  }
}

class FNSHome extends StatelessWidget {
  const FNSHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        centerTitle: true,
        title: const Text('FNS TRADERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER CARD - PURANA WALA DESIGN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.local_hospital, size: 35, color: Color(0xFF0D47A1)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FNS TRADERS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Quality Medicines Distributor\nMultan Road, Multan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerLeft, child: Text('Our Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            
            _productTile('Hydryllin Syrup', 'Cough & Cold - 120ml', 'Rs. 185'),
            _productTile('Pulmonol Syrup', 'Chest Relief - 120ml', 'Rs. 195'),
            _productTile('Gravinate Tablet', 'Nausea Control - 10 Tabs', 'Rs. 120'),
            _productTile('Arinac Forte', 'Flu & Fever - 10 Tabs', 'Rs. 250'),
            _productTile('SurBex Z', 'Multivitamin', 'Rs. 450'),
            _productTile('Panadol Extra', 'Pain Relief', 'Rs. 180'),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: (){},
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text('Order on WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('© 2026 FNS TRADERS', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  static Widget _productTile(String name, String desc, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.medication, color: Color(0xFF0D47A1))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 14)),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
