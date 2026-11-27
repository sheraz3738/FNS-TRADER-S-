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
  bool saving = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    getLimit();
  }

  @override
  void dispose() {
    limitCtrl.dispose();
    super.dispose();
  }

  Future<void> getLimit() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('order_limit')
          .get();
      final amount = doc.exists ? (doc.data()?['amount'] as num?)?.toInt() ?? 0 : 0;
      if (!mounted) return;
      setState(() {
        currentLimit = amount;
        limitCtrl.text = amount.toString();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = e.toString();
      });
    }
  }

  Future<void> saveLimit() async {
    final newLimit = int.tryParse(limitCtrl.text.trim());
    if (newLimit == null || newLimit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meherbani karke sahi amount likhein')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('order_limit').set({
        'amount': newLimit,
      });
      if (!mounted) return;
      setState(() {
        currentLimit = newLimit;
        saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limit $newLimit Rs Save Ho Gaya')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save nahi hua: $e')),
      );
    }
  }

  Future<void> clearLimit() async {
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('order_limit').set({
        'amount': 0,
      });
      if (!mounted) return;
      setState(() {
        currentLimit = 0;
        limitCtrl.text = '0';
        saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order limit khatam kar di gayi')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limit reset nahi hui: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Limit'),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 42),
                        const SizedBox(height: 12),
                        const Text(
                          'Firebase se Order Limit load nahi hui.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: getLimit,
                          child: const Text('Dobara Koshish Karein'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Current Limit: $currentLimit Rs',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: limitCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Limit likho ex: 5000',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: saving ? null : saveLimit,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: Text(
                            saving ? 'SAVING...' : 'SAVE LIMIT',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: saving ? null : clearLimit,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text(
                            'LIMIT KHATAM KARO',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
