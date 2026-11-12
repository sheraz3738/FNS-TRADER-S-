import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final Map<String, int> fnsCustomerCart = {};

Future<void> placeFNSCustomerOrder(
  BuildContext context, {
  required Map<String, int> cart,
  required int totalItems,
  bool skipConfirmation = false,
  VoidCallback? onOrderPlaced,
}) async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pehle products cart mein add karein.'),
        ),
      );
      return;
    }

    final confirmed = skipConfirmation ? true : await showDialog<bool>(
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

    if (confirmed != true || !context.mounted) return;

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
        final price = ((product['netRate'] ?? product['price']) as num?)?.toInt() ?? 0;
        final discountRate = ((product['discountRate'] ?? product['itemDiscount'] ?? 0) as num).toInt().clamp(0, price);
        final lineTotal = (price - discountRate) * entry.value;
        items.add({'productId': entry.key, 'name': product['name'] ?? 'Product', 'price': price, 'discountRate': discountRate, 'quantity': entry.value, 'amount': lineTotal});
        total += lineTotal;
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

      final orderCounter = FirebaseFirestore.instance.collection('counters').doc('customer_orders');
      final orderNo = await FirebaseFirestore.instance.runTransaction<int>((transaction) async {
        final counterSnapshot = await transaction.get(orderCounter);
        final next = ((counterSnapshot.data()?['nextNumber'] ?? 1) as num).toInt();
        transaction.set(orderCounter, {'nextNumber': next + 1}, SetOptions(merge: true));
        return next;
      });
      await FirebaseFirestore.instance.collection('orders').add({
        'orderNo': orderNo,
        'invoiceNo': orderNo,
        'customerId': user.uid,
        'customerEmail': user.email ?? '',
        'customerName': customerProfile['shopName'] ?? '',
        'customerPhone': customerProfile['contact'] ?? '',
        'customerAddress': customerProfile['address'] ?? '',
        'items': items,
        'total': total,
        'paidAmount': 0,
        'balance': total,
        'paymentStatus': 'Unpaid',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      cart.clear();

      // Short confirmation sound after the order is successfully saved.
      await SystemSound.play(SystemSoundType.alert);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order place ho gaya.'),
        ),
      );

      onOrderPlaced?.call();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order nahi hua: $e'),
        ),
      );
    }
  }



class CustomerScreen extends StatefulWidget {
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenAi;

  const CustomerScreen({
    super.key,
    this.onOpenOrders,
    this.onOpenCart,
    this.onOpenProfile,
    this.onOpenAi,
  });

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final int initialQuantity;
  final ValueChanged<int> onAddToCart;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.initialQuantity,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final name = (product['name'] ?? 'Product').toString();
    final netRate = ((product['netRate'] ?? product['price']) as num?)?.toInt() ?? 0;
    final retailRate = ((product['retailPrice'] ?? product['price']) as num?)?.toInt() ?? 0;
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final description = (product['description'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.medication, size: 100),
              ),
            )
          else
            const SizedBox(
              height: 180,
              child: Icon(Icons.medication, size: 100, color: Colors.blue),
            ),
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Net Rate: Rs. $netRate',
              style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Retail Rate: Rs. $retailRate',
              style: const TextStyle(fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(description, style: const TextStyle(fontSize: 16)),
          ],
          const SizedBox(height: 24),
          const Text('Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: quantity > 0 ? () => setState(() => quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline, size: 34),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('$quantity', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add_circle_outline, size: 34, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: quantity > 0
                  ? () {
                      widget.onAddToCart(quantity);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: quantity > 0 ? Colors.white : Colors.green.shade700, foregroundColor: quantity > 0 ? Colors.green.shade700 : Colors.white, side: BorderSide(color: Colors.green.shade700)),
              icon: Icon(quantity > 0 ? Icons.check_circle : Icons.add_shopping_cart),
              label: Text(quantity > 0 ? 'Added to Cart ($quantity)' : 'Add to Cart ($quantity)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController welcomeController = ScrollController();

  String search = '';
  String selectedCategory = 'All Categories';
  static const List<String> categories = ['All Categories','Medicines','Syrups','Tablets/Capsules','Syringes','Surgical Items','BP & Sugar','General Items','Medical Equipment','Other Items'];
  final Map<String, int> cart = fnsCustomerCart;
  final Set<String> favorites = {};

  Timer? welcomeTimer;
  Offset? whatsappOffset;

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

  Future<void> openProductDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: document.data(),
          initialQuantity: cart[document.id] ?? 0,
          onAddToCart: (quantity) {
            if (!mounted) return;
            setState(() {
              if (quantity == 0) {
                cart.remove(document.id);
              } else {
                cart[document.id] = quantity;
              }
            });
          },
        ),
      ),
    );
  }

  Widget buildProductCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final name = (data['name'] ?? 'Product').toString();
    final price = ((data['netRate'] ?? data['price']) as num?)?.toInt() ?? 0;
    final retailPrice = ((data['retailPrice'] ?? data['price']) as num?)?.toInt() ?? 0;
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openProductDetails(document),
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
                    'Net Rate: Rs. $price',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Retail Rate: Rs. $retailPrice',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          cart[document.id] = (cart[document.id] ?? 0) + 1;
                        });
                        SystemSound.play(SystemSoundType.click);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$name cart mein add ho gaya.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: quantity > 0 ? Colors.white : Colors.green.shade700,
                        foregroundColor: quantity > 0 ? Colors.green.shade700 : Colors.white,
                        side: BorderSide(color: Colors.green.shade700),
                      ),
                      icon: Icon(quantity > 0 ? Icons.check_circle : Icons.add_shopping_cart),
                      label: Text(quantity > 0 ? 'Add More • Cart: $quantity' : 'Add to Cart'),
                    ),
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
      ),
    );
  }

  Future<void> placeOrder({bool skipConfirmation = false}) async {
    await placeFNSCustomerOrder(
      context,
      cart: cart,
      totalItems: totalItems,
      skipConfirmation: skipConfirmation,
      onOrderPlaced: widget.onOpenOrders,
    );
    if (mounted) setState(() {});
  }

  Widget _buildMovableWhatsAppButton() {
    final screen = MediaQuery.of(context).size;
    final maxX = (screen.width - 62).clamp(0.0, double.infinity).toDouble();
    final maxY = (screen.height - 250).clamp(0.0, double.infinity).toDouble();
    final position = whatsappOffset ?? Offset(maxX, maxY);
    final safePosition = Offset(
      position.dx.clamp(0.0, maxX).toDouble(),
      position.dy.clamp(0.0, maxY).toDouble(),
    );
    return Positioned(
      left: safePosition.dx,
      top: safePosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            whatsappOffset = Offset(
              (safePosition.dx + details.delta.dx).clamp(0.0, maxX).toDouble(),
              (safePosition.dy + details.delta.dy).clamp(0.0, maxY).toDouble(),
            );
          });
        },
        child: FloatingActionButton(
          heroTag: 'customer_whatsapp_fab',
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          tooltip: 'WhatsApp - drag to move',
          onPressed: openWhatsApp,
          child: const FaIcon(FontAwesomeIcons.whatsapp, size: 30),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
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
          ],
        ),
          ),
          _buildMovableWhatsAppButton(),
        ],
      ),
    );
  }
}

class SlideToOrderButton extends StatefulWidget {
  final int itemCount;
  final VoidCallback onComplete;
  const SlideToOrderButton({super.key, required this.itemCount, required this.onComplete});
  @override State<SlideToOrderButton> createState() => _SlideToOrderButtonState();
}
class _SlideToOrderButtonState extends State<SlideToOrderButton> {
  double value = 0;
  @override Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(18)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Slide to Place Order (${widget.itemCount} items)',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 5),
      SliderTheme(data: SliderTheme.of(context).copyWith(
        trackHeight: 10,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white54,
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
        overlayColor: Colors.white24,
      ),
        child: Slider(value: value, min: 0, max: 1, onChanged: widget.itemCount == 0 ? null : (v) {
          setState(() => value = v);
          if (v >= 0.98) { setState(() => value = 0); widget.onComplete(); }
        })),
    ]),
  );
}
