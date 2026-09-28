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

  getLimit() async {
    var doc = await FirebaseFirestore.instance.collection('settings').doc('order_limit').get();
    if (doc.exists) {
      setState(() {
        currentLimit = doc.data()!['amount'] ?? 0;
        limitCtrl.text = currentLimit.toString();
      });
    }
    setState(() => loading = false);
  }

  saveLimit() async {
    int newLimit = int.tryParse(limitCtrl.text) ?? 0;
    await FirebaseFirestore.instance.collection('settings').doc('order_limit').set({
      'amount': newLimit,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Limit $newLimit Rs Save Ho Gaya")));
    setState(() => currentLimit = newLimit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Limit"), backgroundColor: Colors.green),
      body: loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text("Current Limit: $currentLimit Rs", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Limit likho ex: 5000", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: saveLimit, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("SAVE LIMIT", style: TextStyle(color: Colors.white)))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('settings').doc('order_limit').set({'amount': 0});
            setState(() { currentLimit = 0; limitCtrl.text = "0"; });
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("LIMIT KHATAM KARO", style: TextStyle(color: Colors.white)))),
        ]),
      ),
    );
  }
}
