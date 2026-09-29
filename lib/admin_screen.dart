import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_limit_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FNS Admin Panel"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // LIMIT BUTTON
          Card(
            color: Colors.green.shade50,
            child: ListTile(
              leading: const Icon(Icons.rule, color: Colors.green, size: 30),
              title: const Text("Order Limit Set Karo", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Minimum order amount set karo"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminLimitScreen()),
                );
              },
            ),
          ),
          const Divider(),

          // ORDERS LIST
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var orders = snapshot.data!.docs;
                if (orders.isEmpty) {
                  return const Center(child: Text("Koi order nahi hai"));
                }
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Order: ${order['orderNo']?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Customer: ${order['customerName']?? ''}"),
                            Text("Total: Rs ${order['total']?? ''}"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
