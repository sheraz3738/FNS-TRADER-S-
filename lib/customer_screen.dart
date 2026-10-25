
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerScreen extends StatefulWidget {
  final VoidCallback? onOpenOrders;
  const CustomerScreen({super.key, this.onOpenOrders});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  String search = '';
  final Map<String, int> cart = {};
  final Set<String> favorites = {};
  bool ordering = false;

  int get cartCount => cart.values.fold(0, (a, b) => a + b);

  Widget _header() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF0D47A1),
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: SizedBox(
            height: 22,
            child: _ScrollingWelcome(),
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.green.shade700,
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: const Text(
            'مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white,
                fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5)
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 75,
                height: 65,
                child: Image.asset(
                  'fns_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('FNS', style: TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بابا فلک ناز اینڈ سنز ٹریڈرز',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    Text('BABA FALAK NAZ & SONS TRADERS',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> placeOrder(List<Map<String, dynamic>> items, int total) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Pehle customer account mein login karein.');
      return;
    }
    if (items.isEmpty) {
      _message('Cart mein koi product nahi hai.');
      return;
    }

    setState(() => ordering = true);
    try {
      final customer = await FirebaseFirestore.instance
          .collection('customers').doc(user.uid).get();

      await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid,
        'customerName': customer.data()?['shopName'] ?? '',
        'contact': customer.data()?['contact'] ?? '',
        'items': items,
        'total': total,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => cart.clear());
      _message('Order place ho gaya. Status: Pending');
      widget.onOpenOrders?.call();
    } catch (e) {
      _message('Order place nahi hua. Firebase rules check karein.');
    } finally {
      if (mounted) setState(() => ordering = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: InputDecoration(
                  hintText: 'Search Medicine...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Products load nahi ho sake.'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((d) {
                    final name = (d.data()['name'] ?? '').toString();
                    return name.toLowerCase().contains(search.toLowerCase());
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('Koi product nahi mila.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final p = doc.data();
                      final id = doc.id;
                      final name = (p['name'] ?? '').toString();
                      final price = p['price'] ?? 0;
                      final imageUrl = (p['imageUrl'] ?? '').toString();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: SizedBox(
                            width: 55,
                            height: 55,
                            child: imageUrl.startsWith('http')
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.shopping_bag),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F0F0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.shopping_bag),
                                  ),
                          ),
                          title: Text(name, style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('Rs. $price'),
                          trailing: SizedBox(
                            width: 142,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => setState(() {
                                    if ((cart[id] ?? 0) > 1) {
                                      cart[id] = cart[id]! - 1;
                                    } else {
                                      cart.remove(id);
                                    }
                                  }),
                                ),
                                Text('${cart[id] ?? 0}'),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.green),
                                  onPressed: () => setState(() {
                                    cart[id] = (cart[id] ?? 0) + 1;
                                  }),
                                ),
                              ],
                            ),
                          ),
                          onLongPress: () => setState(() {
                            if (favorites.contains(id)) {
                              favorites.remove(id);
                            } else {
                              favorites.add(id);
                            }
                          }),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: Text('Order ($cartCount)'),
                          onPressed: ordering ? null : () async {
                            final selected = <Map<String, dynamic>>[];
                            int total = 0;

                            for (final entry in cart.entries) {
                              final product = await FirebaseFirestore.instance
                                  .collection('products').doc(entry.key).get();
                              if (!product.exists) continue;

                              final data = product.data()!;
                              final price = data['price'];
                              final numericPrice = price is num
                                  ? price.toInt()
                                  : int.tryParse('$price') ?? 0;

                              selected.add({
                                'productId': entry.key,
                                'name': data['name'] ?? '',
                                'price': numericPrice,
                                'quantity': entry.value,
                              });
                              total += numericPrice * entry.value;
                            }

                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Confirm Order'),
                                content: Text(
                                  'Items: ${selected.length}\nTotal: Rs. $total\n\nOrder place karein?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      placeOrder(selected, total);
                                    },
                                    child: const Text('Place Order'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('My Orders'),
                          onPressed: widget.onOpenOrders,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            launchUrl(
                              Uri.parse('https://wa.me/923343738405'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('AI Search'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _message(
                            'AI Search abhi connect nahi hai.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (favorites.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Favorite items: ${favorites.length}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollingWelcome extends StatefulWidget {
  @override
  State<_ScrollingWelcome> createState() => _ScrollingWelcomeState();
}

class _ScrollingWelcomeState extends State<_ScrollingWelcome> {
  final ScrollController controller = ScrollController();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      timer = Timer.periodic(const Duration(milliseconds: 35), (_) {
        if (!controller.hasClients) return;
        final max = controller.position.maxScrollExtent;
        if (max <= 0) return;
        final next = controller.offset + 1;
        controller.jumpTo(next >= max ? 0 : next);
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      children: const [
        Text(
          '  بابا فلک ناز رحمۃ اللّٰہ علیہ اینڈ سنز ٹریڈرز  |  '
          'BABA FALAK NAZ & SONS TRADERS  |  WELCOME TO FNS TRADERS  |  ',
          style: TextStyle(color: Colors.white,
              fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
