import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerScreen extends StatefulWidget {
  final VoidCallback? onOpenOrders;

  const CustomerScreen({
    super.key,
    this.onOpenOrders,
  });

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController welcomeController = ScrollController();

  String search = '';
  String selectedCategory = 'All Categories';
  static const List<String> categories = ['All Categories','Medicines','Syrups','Tablets/Capsules','Syringes','Surgical Items','BP & Sugar','General Items','Medical Equipment','Other Items'];
  final Map<String, int> cart = {};
  final Set<String> favorites = {};

  Timer? welcomeTimer;

  @override
  void initState() {
    super.initState();

    welcomeTimer = Timer.periodic(
      const Duration(milliseconds: 35),
      (_) {
        if (!welcomeController.hasClients) return;

        final max = welcomeController.position.maxScrollExtent;

        if (max <= 0) return;

        if (welcomeController.offset >= max) {
          welcomeController.jumpTo(0);
        } else {
          welcomeController.jumpTo(
            welcomeController.offset + 1,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    welcomeTimer?.cancel();
    welcomeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  int get totalItems =>
      cart.values.fold(0, (sum, quantity) => sum + quantity);

  int get totalPrice => 0;

  Future<void> openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/923343738405',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Widget buildHeader() {
    return Column(
      children: [
        Container(
          height: 44,
          width: double.infinity,
          color: Colors.blue.shade800,
          child: ListView(
            controller: welcomeController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'BABA FALAK NAZ & SONS TRADERS  |  WELCOME TO FNS TRADERS  |  بابا فلک ناز رحمۃ اللّٰہ علیہ اینڈ سنز ٹریڈرز',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.green.shade700,
          child: const Center(
            child: Text(
              'مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Full logo card
        Card(
          margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.infinity,
            height: 125,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'fns_logo.png',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'FNS TRADERS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildProductCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final name = (data['name'] ?? 'Product').toString();
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final quantity = cart[document.id] ?? 0;
    final isFavorite = favorites.contains(document.id);

    if (search.isNotEmpty &&
        !name.toLowerCase().contains(search.toLowerCase())) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.medication, size: 50),
                ),
              )
            else
              const Icon(
                Icons.medication,
                size: 50,
                color: Colors.blue,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Rs. $price',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: quantity > 0
                            ? () {
                                setState(() {
                                  if (quantity == 1) {
                                    cart.remove(document.id);
                                  } else {
                                    cart[document.id] = quantity - 1;
                                  }
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$quantity'),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            cart[document.id] = quantity + 1;
                          });
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  if (isFavorite) {
                    favorites.remove(document.id);
                  } else {
                    favorites.add(document.id);
                  }
                });
              },
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> placeOrder() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pehle products cart mein add karein.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Order Confirm'),
        content: Text(
          'Kya aap $totalItems items ka order place karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final items = <Map<String, dynamic>>[];
      int total = 0;

      for (final entry in cart.entries) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(entry.key)
            .get();

        if (!productDoc.exists) continue;

        final product = productDoc.data()!;
        final price = (product['price'] as num?)?.toInt() ?? 0;

        items.add({
          'productId': entry.key,
          'name': product['name'] ?? 'Product',
          'price': price,
          'quantity': entry.value,
        });

        total += price * entry.value;
      }

      if (items.isEmpty) {
        throw Exception('Products nahi mile.');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Order place karne ke liye login karein.');
      }

      Map<String, dynamic> customerProfile = {};
      try {
        final profileDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();
        customerProfile = profileDoc.data() ?? {};
      } catch (_) {}

      await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid,
        'customerEmail': user.email ?? '',
        'customerName': customerProfile['shopName'] ?? '',
        'customerPhone': customerProfile['contact'] ?? '',
        'customerAddress': customerProfile['address'] ?? '',
        'items': items,
        'total': total,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        cart.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order place ho gaya.'),
        ),
      );

      widget.onOpenOrders?.call();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order nahi hua: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    search = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Medicine search karein...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Product category',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) => DropdownMenuItem(
                  value: category, child: Text(category),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedCategory = value);
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Products load nahi ho sake.'),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final documents = snapshot.data?.docs ?? [];

                  if (documents.isEmpty) {
                    return const Center(
                      child: Text('Abhi products available nahi hain.'),
                    );
                  }

                  final filtered = documents.where((doc) {
                    final data = doc.data();
                    final name = (data['name'] ?? '').toString();
                    final category = (data['category'] ?? 'Other Items').toString();
                    final matchesName = name.toLowerCase().contains(search.toLowerCase());
                    final matchesCategory = selectedCategory == 'All Categories'
                        || category == selectedCategory;
                    return matchesName && matchesCategory;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Koi medicine nahi mili.'),
                    );
                  }

                  // Show products under separate category headings.
                  final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
                  for (final doc in filtered) {
                    final rawCategory = (doc.data()['category'] ?? 'Other Items').toString();
                    final category = categories.contains(rawCategory) && rawCategory != 'All Categories'
                        ? rawCategory
                        : 'Other Items';
                    grouped.putIfAbsent(category, () => []).add(doc);
                  }
                  final orderedCategories = categories
                      .where((c) => c != 'All Categories' && grouped.containsKey(c))
                      .toList();
                  for (final c in grouped.keys) {
                    if (!orderedCategories.contains(c)) orderedCategories.add(c);
                  }
                  final rows = <Widget>[];
                  for (final category in orderedCategories) {
                    rows.add(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                            Text('${grouped[category]!.length} items',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                    rows.addAll(grouped[category]!.map(buildProductCard));
                  }
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: rows,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: placeOrder,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: Text('Order Now ($totalItems items)'),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: openWhatsApp,
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'AI Search abhi connect nahi hai.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.smart_toy),
                          label: const Text('AI Search'),
                        ),
                      ),
                    ],
                  ),
                  if (widget.onOpenOrders != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: widget.onOpenOrders,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('My Orders'),
                      ),
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
