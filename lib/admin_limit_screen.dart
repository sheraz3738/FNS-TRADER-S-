import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLimitScreen extends StatefulWidget {
  const AdminLimitScreen({super.key});
  @override
  State<AdminLimitScreen> createState() => _AdminLimitScreenState();
}

class _AdminLimitScreenState extends State<AdminLimitScreen> {
  final limitCtrl = TextEditingController();
  int currentLimit = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getLimit();
  }

  Future<void> getLimit() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('settings').doc('order_limit').get();
      if (doc.exists) {
        setState(() {
          currentLimit = doc.data()!['amount'] ?? 0;
          limitCtrl.text = currentLimit.toString();
        });
      }
    } catch (e) {}
    setState(() => loading = false);
  }

  Future<void> saveLimit() async {
    int newLimit = int.tryParse(limitCtrl.text.trim()) ?? 0;
    await FirebaseFirestore.instance.collection('settings').doc('order_limit').set({
      'amount': newLimit,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Limit $newLimit Rs Save Ho Gaya")));
    setState(() => currentLimit = newLimit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Limit Setting"), backgroundColor: Colors.green),
      body: loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.green),
                    const SizedBox(width: 10),
                    Text("Current Limit: $currentLimit Rs", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Naya Limit Kitna Lagana Hai? (Ex: 5000)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: saveLimit, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("SAVE LIMIT", style: TextStyle(fontSize: 16, color: Colors.white)))),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () async {
              await FirebaseFirestore.instance.collection('settings').doc('order_limit').set({'amount': 0});
              setState(() { currentLimit = 0; limitCtrl.text = "0"; });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Limit Khatam Kar Diya - Ab Koi Limit Nahi")));
            }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("LIMIT KHATAM KARO", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}
