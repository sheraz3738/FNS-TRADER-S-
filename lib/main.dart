import 'package:flutter/material.dart';
void main() => runApp(const FNSApp());
class FNSApp extends StatelessWidget {
  const FNSApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FNS TRADERS'), backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.local_pharmacy, size: 40, color: Colors.white), SizedBox(width: 10), Text('FNS TRADERS\nQuality Medicines', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))])),
          const SizedBox(height: 20),
          Card(child: ListTile(leading: const Icon(Icons.medication), title: const Text('Hydryllin Syrup'), subtitle: const Text('Rs. 185'), trailing: const Icon(Icons.arrow_forward_ios, size: 14))),
          Card(child: ListTile(leading: const Icon(Icons.medication), title: const Text('Pulmonol Syrup'), subtitle: const Text('Rs. 195'), trailing: const Icon(Icons.arrow_forward_ios, size: 14))),
          Card(child: ListTile(leading: const Icon(Icons.medication), title: const Text('Gravinate Tablet'), subtitle: const Text('Rs. 120'), trailing: const Icon(Icons.arrow_forward_ios, size: 14))),
          Card(child: ListTile(leading: const Icon(Icons.medication), title: const Text('Arinac Forte'), subtitle: const Text('Rs. 250'), trailing: const Icon(Icons.arrow_forward_ios, size: 14))),
        ],
      ),
    );
  }
}
