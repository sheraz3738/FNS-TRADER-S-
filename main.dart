import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const FnsApp());
}

class Product {
  String name;
  int price;
  bool inStock;
  String imageBase64;
  String category;

  Product({
    required this.name,
    required this.price,
    this.inStock = true,
    this.imageBase64 = '',
    this.category = 'Other',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'inStock': inStock,
      'imageBase64': imageBase64,
      'category': category,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name']?.toString() ?? '',
      price: int.tryParse(json['price'].toString()) ?? 0,
      inStock: json['inStock'] ?? true,
      imageBase64: json['imageBase64']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
    );
  }
}

class OrderData {
  final String customer;
  final String phone;
  final String address;
  final String items;
  final int total;
  final String payment;

  OrderData({
    required this.customer,
    required this.phone,
    required this.address,
    required this.items,
    required this.total,
    required this.payment,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer': customer,
      'phone': phone,
      'address': address,
      'items': items,
      'total': total,
      'payment': payment,
    };
  }

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      customer: json['customer']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      items: json['items']?.toString() ?? '',
      total: int.tryParse(json['total'].toString()) ?? 0,
      payment: json['payment']?.toString() ?? '',
    );
  }
}

class FnsApp extends StatefulWidget {
  const FnsApp({super.key});

  @override
  State<FnsApp> createState() => _FnsAppState();
}

class _FnsAppState extends State<FnsApp> {
  static const String whatsappNumber = '923343738405';
  int minOrderLimit = 0;

  List<Product> products = [
    Product(
      name: 'Hydryllin Syrup 120ml',
      price: 200,
      category: 'General',
    ),
    Product(
      name: 'Pulmonol Syrup 120ml',
      price: 200,
      category: 'General',
    ),
    Product(
      name: 'Lederplex Syrup 150ml',
      price: 234,
      category: 'General',
    ),
    Product(
      name: 'Extor 5/80 Tablet',
      price: 490,
      category: 'General',
    ),
    Product(
      name: 'Risek 40mg Capsule',
      price: 861,
      category: 'General',
    ),
  ];

  final Map<Product, int> cart = {};
  final Set<String> favorites = {};
  final List<OrderData> orders = [];

  String searchText = '';
  int bottomIndex = 0;
  bool loading = true;
  String selectedCategory = 'All';
  late final ScrollController _headlineController;

  static const List<String> categories = [
    'General',
    'Glucometer',
    'B.P Operator',
    'Stethoscope',
    'Surgical',
    'Syrup',
    'Tablet',
    'Other',
  ];

  Future<void> _openWhatsApp({String? message}) async {
    final encodedMessage = message == null ? '' : '&text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse('https://wa.me/$whatsappNumber?${encodedMessage.isEmpty ? '' : encodedMessage.substring(1)}');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {}

    final fallback = Uri.parse(
      'whatsapp://send?phone=$whatsappNumber${message == null ? '' : '&text=${Uri.encodeComponent(message)}'}',
    );
    try {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _headlineController = ScrollController();
    loadSavedData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startHeadlineScroll());
  }

  void _startHeadlineScroll() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    while (mounted) {
      if (!_headlineController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        continue;
      }
      final max = _headlineController.position.maxScrollExtent;
      if (max <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        continue;
      }
      await _headlineController.animateTo(
        max,
        duration: const Duration(seconds: 12),
        curve: Curves.linear,
      );
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _headlineController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _headlineController.dispose();
    super.dispose();
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedProducts = prefs.getString('products');
    final savedFavorites = prefs.getStringList('favorites');
    final savedOrders = prefs.getString('orders');
    minOrderLimit = prefs.getInt('minOrderLimit') ?? 0;

    if (savedProducts != null && savedProducts.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedProducts) as List;
        products = decoded
            .map(
              (item) => Product.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } catch (_) {}
    }

    if (savedFavorites != null) {
      favorites
        ..clear()
        ..addAll(savedFavorites);
    }

    if (savedOrders != null && savedOrders.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedOrders) as List;
        orders
          ..clear()
          ..addAll(
            decoded.map(
              (item) => OrderData.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ),
          );
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products',
      jsonEncode(
        products.map((product) => product.toJson()).toList(),
      ),
    );
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorites',
      favorites.toList(),
    );
  }

  Future<void> saveMinOrderLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minOrderLimit', minOrderLimit);
  }

  Future<void> saveOrders() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'orders',
      jsonEncode(
        orders.map((order) => order.toJson()).toList(),
      ),
    );
  }

  int get cartCount {
    int count = 0;

    for (final quantity in cart.values) {
      count += quantity;
    }

    return count;
  }

  int get cartTotal {
    int total = 0;

    for (final entry in cart.entries) {
      total += entry.key.price * entry.value;
    }

    return total;
  }

  List<Product> get filteredProducts {
    if (searchText.trim().isEmpty) {
      return products;
    }

    final query = searchText.toLowerCase();

    return products.where((product) {
      return product.name.toLowerCase().contains(query);
    }).toList();
  }

  Widget productImage(
    Product product, {
    double size = 70,
  }) {
    if (product.imageBase64.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(product.imageBase64),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: const Icon(
        Icons.shopping_bag,
        size: 35,
      ),
    );
  }

  void addToCart(Product product) {
    if (!product.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is currently out of stock.'),
        ),
      );
      return;
    }

    setState(() {
      cart[product] = (cart[product] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
      ),
    );
  }

  void increaseQuantity(Product product) {
    setState(() {
      cart[product] = (cart[product] ?? 0) + 1;
    });
  }

  void decreaseQuantity(Product product) {
    setState(() {
      final quantity = cart[product] ?? 0;

      if (quantity <= 1) {
        cart.remove(product);
      } else {
        cart[product] = quantity - 1;
      }
    });
  }

  void toggleFavorite(Product product) {
    setState(() {
      if (favorites.contains(product.name)) {
        favorites.remove(product.name);
      } else {
        favorites.add(product.name);
      }
    });

    saveFavorites();
  }

  void showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                productImage(
                  product,
                  size: 120,
                ),
                const SizedBox(height: 15),
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Retail: Rs. ${product.price}',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  product.inStock ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    color: product.inStock
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: product.inStock
                        ? () {
                            Navigator.pop(context);
                            addToCart(product);
                          }
                        : null,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget homePage() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleProducts = filteredProducts;

    return RefreshIndicator(
      onRefresh: loadSavedData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  color: Color(0x22000000),
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              'fns_logo.png',
              width: double.infinity,
              height: 145,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 80),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.green.shade700,
            child: const Center(
              child: Text(
                'Welcome To FNS Traders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => searchText = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip('All'),
                ...categories.map(_categoryChip),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${visibleProducts.length} product(s)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (visibleProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('No products found.')),
            )
          else
            ...visibleProducts.map(_productCard),
        ],
      ),
    );
  }

  Widget _categoryChip(String category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: selectedCategory == category,
        onSelected: (_) => setState(() => selectedCategory = category),
      ),
    );
  }

  Widget _productCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: productImage(product, size: 58),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${product.category}\nRetail: Rs. ${product.price}'),
        isThreeLine: true,
        onTap: () => showProductDetails(product),
        trailing: SizedBox(
          width: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => toggleFavorite(product),
                icon: Icon(
                  favorites.contains(product.name)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: product.inStock ? () => addToCart(product) : null,
                icon: const Icon(Icons.add_shopping_cart),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Shopping Cart',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: cart.isEmpty
                          ? const Center(
                              child: Text('Your cart is empty'),
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              children: cart.entries.map((entry) {
                                final product = entry.key;
                                final quantity = entry.value;

                                return Card(
                                  child: ListTile(
                                    leading: productImage(
                                      product,
                                      size: 55,
                                    ),
                                    title: Text(product.name),
                                    subtitle: Text(
                                      'Rs. ${product.price} × $quantity',
                                    ),
                                    trailing: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            decreaseQuantity(
                                              product,
                                            );
                                            setSheetState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle,
                                          ),
                                        ),
                                        Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            increaseQuantity(
                                              product,
                                            );
                                            setSheetState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.add_circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Rs. $cartTotal',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: cart.isEmpty
                                  ? null
                                  : () {
                                      Navigator.pop(sheetContext);
                                      showCheckout();
                                    },
                              icon: const Icon(
                                Icons.shopping_cart_checkout,
                              ),
                              label: const Text('Checkout'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showCheckout() {
    if (cart.isEmpty) return;

    if (minOrderLimit > 0 && cartTotal < minOrderLimit) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Minimum Order Required'),
          content: Text(
            'Minimum order is Rs. $minOrderLimit.\n'
            'Your cart total is Rs. $cartTotal.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    String paymentMethod = 'Cash on Delivery';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      RadioListTile<String>(
                        title: const Text('Cash on Delivery'),
                        value: 'Cash on Delivery',
                        groupValue: paymentMethod,
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => paymentMethod = value);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Bank Transfer'),
                        value: 'Bank Transfer',
                        groupValue: paymentMethod,
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => paymentMethod = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Order Total',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Rs. $cartTotal',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            if (nameController.text.trim().isEmpty ||
                                phoneController.text.trim().isEmpty ||
                                addressController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all details.'),
                                ),
                              );
                              return;
                            }

                            placeOrder(
                              customer: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              address: addressController.text.trim(),
                              payment: paymentMethod,
                            );

                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Place Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> placeOrder({
    required String customer,
    required String phone,
    required String address,
    required String payment,
  }) async {
    final itemText = cart.entries
        .map((entry) => '${entry.key.name} x ${entry.value}')
        .join(', ');

    final order = OrderData(
      customer: customer,
      phone: phone,
      address: address,
      items: itemText,
      total: cartTotal,
      payment: payment,
    );

    setState(() {
      orders.add(order);
      cart.clear();
    });

    await saveOrders();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed successfully.')),
    );

    await _openWhatsApp(
      message:
          'FNS TRADER\'S Order\n'
          'Customer: $customer\n'
          'Phone: $phone\n'
          'Address: $address\n'
          'Items: $itemText\n'
          'Total: Rs. ${order.total}\n'
          'Payment: $payment',
    );
  }

  void showAdminLogin(BuildContext dialogContext) {
    final password = TextEditingController();

    showDialog(
      context: dialogContext,
      builder: (_) {
        return AlertDialog(
          title: const Text('Admin Login'),
          content: TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Admin Password',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (password.text == '1234') {
                  Navigator.pop(dialogContext);
                  showAdminPanel(dialogContext);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Wrong password')),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickProductImage(Product product, StateSetter setSheetState) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => product.imageBase64 = base64Encode(bytes));
    await saveProducts();
    setSheetState(() {});
  }

  Future<void> _editProduct(Product product, StateSetter setSheetState) async {
    final name = TextEditingController(text: product.name);
    final price = TextEditingController(text: product.price.toString());
    String category = product.category;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Product Name')),
                TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Retail Price')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categories.contains(category) ? category : 'Other',
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? 'Other'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final parsedPrice = int.tryParse(price.text.trim());
                if (name.text.trim().isEmpty || parsedPrice == null) return;
                setState(() {
                  product.name = name.text.trim();
                  product.price = parsedPrice;
                  product.category = category;
                });
                await saveProducts();
                setSheetState(() {});
                if (mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    price.dispose();
  }

  Future<void> _addProduct(StateSetter setSheetState) async {
    final name = TextEditingController();
    final price = TextEditingController();
    String category = 'General';
    String imageBase64 = '';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                    if (picked == null) return;
                    final bytes = await picked.readAsBytes();
                    setDialogState(() => imageBase64 = base64Encode(bytes));
                  },
                  icon: const Icon(Icons.photo),
                  label: const Text('Add Product Photo'),
                ),
                const SizedBox(height: 8),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Product Name')),
                TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Retail Price')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? 'Other'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final parsedPrice = int.tryParse(price.text.trim());
                if (name.text.trim().isEmpty || parsedPrice == null) return;
                final product = Product(
                  name: name.text.trim(),
                  price: parsedPrice,
                  category: category,
                  imageBase64: imageBase64,
                );
                setState(() => products.add(product));
                await saveProducts();
                setSheetState(() {});
                if (mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    price.dispose();
  }

  Future<void> _deleteProduct(Product product, StateSetter setSheetState) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Delete ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      products.remove(product);
      cart.remove(product);
      favorites.remove(product.name);
    });
    await saveProducts();
    await saveFavorites();
    setSheetState(() {});
  }

  void showAdminPanel(BuildContext panelContext) {
    showModalBottomSheet(
      context: panelContext,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.92,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 8, 0),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Admin Panel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                          IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    const TabBar(tabs: [Tab(text: 'Products'), Tab(text: 'Orders')]),
                    Expanded(
                      child: TabBarView(
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                                child: Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.shopping_cart_checkout),
                                    title: const Text('Set Minimum Order Limit'),
                                    subtitle: Text(
                                      minOrderLimit > 0
                                          ? 'Current limit: Rs. $minOrderLimit'
                                          : 'No minimum order limit set',
                                    ),
                                    trailing: const Icon(Icons.edit),
                                    onTap: () async {
                                      final controller = TextEditingController(
                                        text: minOrderLimit == 0 ? '' : minOrderLimit.toString(),
                                      );
                                      final value = await showDialog<int>(
                                        context: sheetContext,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text('Minimum Order Limit'),
                                          content: TextField(
                                            controller: controller,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Minimum amount (Rs.)',
                                              hintText: '0 = no limit',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () {
                                                final parsed = int.tryParse(controller.text.trim());
                                                if (parsed == null || parsed < 0) return;
                                                Navigator.pop(dialogContext, parsed);
                                              },
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                      );
                                      controller.dispose();
                                      if (value == null) return;
                                      setState(() => minOrderLimit = value);
                                      await saveMinOrderLimit();
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _addProduct(setSheetState),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add New Product'),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                                  itemCount: products.length,
                                  itemBuilder: (_, index) {
                                    final product = products[index];
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            productImage(product, size: 58),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text('${product.category} • Rs. ${product.price}'),
                                                  Text(product.inStock ? 'In Stock' : 'Out of Stock'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              onSelected: (value) async {
                                                if (value == 'photo') await _pickProductImage(product, setSheetState);
                                                if (value == 'edit') await _editProduct(product, setSheetState);
                                                if (value == 'delete') await _deleteProduct(product, setSheetState);
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(value: 'photo', child: Text('Add / Change Photo')),
                                                PopupMenuItem(value: 'edit', child: Text('Edit Product / Price')),
                                                PopupMenuItem(value: 'delete', child: Text('Delete Product')),
                                              ],
                                            ),
                                            Switch(
                                              value: product.inStock,
                                              onChanged: (value) async {
                                                setState(() => product.inStock = value);
                                                await saveProducts();
                                                setSheetState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          orders.isEmpty
                              ? const Center(child: Text('No customer orders yet.'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: orders.length,
                                  itemBuilder: (_, index) {
                                    final order = orders[index];
                                    return Card(
                                      child: ExpansionTile(
                                        title: Text(order.customer),
                                        subtitle: Text('Rs. ${order.total} • ${order.payment}'),
                                        childrenPadding: const EdgeInsets.all(14),
                                        children: [
                                          Align(alignment: Alignment.centerLeft, child: Text('Phone: ${order.phone}')),
                                          const SizedBox(height: 6),
                                          Align(alignment: Alignment.centerLeft, child: Text('Address: ${order.address}')),
                                          const SizedBox(height: 6),
                                          Align(alignment: Alignment.centerLeft, child: Text('Items: ${order.items}')),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildHome() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return homePage();
  }

  Widget buildCartPage() {
    return Center(
      child: FilledButton.icon(
        onPressed: showCart,
        icon: const Icon(Icons.shopping_cart),
        label: Text('Open Cart ($cartCount)'),
      ),
    );
  }

  Widget buildFavoritesPage() {
    final favoriteProducts =
        products.where((p) => favorites.contains(p.name)).toList();

    if (favoriteProducts.isEmpty) {
      return const Center(child: Text('No favorites yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: favoriteProducts.length,
      itemBuilder: (_, index) {
        final product = favoriteProducts[index];
        return Card(
          child: ListTile(
            leading: productImage(product),
            title: Text(product.name),
            subtitle: Text('Retail: Rs. ${product.price}'),
            onTap: () => showProductDetails(product),
          ),
        );
      },
    );
  }

  Widget buildAboutPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Image.asset(
          'fns_logo.png',
          width: double.infinity,
          height: 260,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 100),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (bottomIndex) {
      case 0:
        page = buildHome();
        break;
      case 1:
        page = buildCartPage();
        break;
      case 2:
        page = buildFavoritesPage();
        break;
      case 3:
        page = buildAboutPage();
        break;
      case 4:
        page = Builder(
          builder: (adminContext) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => showAdminLogin(adminContext),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Open Admin Panel'),
              ),
            );
          },
        );
        break;
      default:
        page = buildHome();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "FNS TRADER'S",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("FNS TRADER'S"),
          actions: [
            IconButton(
              onPressed: showCart,
              icon: Badge(
                label: Text('$cartCount'),
                isLabelVisible: cartCount > 0,
                child: const Icon(Icons.shopping_cart),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(42),
            child: Container(
              height: 42,
              width: double.infinity,
              color: Colors.green.shade700,
              child: ListView(
                controller: _headlineController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Center(
                      child: Text(
                        'بابا فلک ناز رحمة الله عليه اینڈ سنز ٹریڈرز   •   BA BA FALAK NAZ & SON\'S TRADER\'S   •   Welcome To FNS Traders   •   '
                        'بابا فلک ناز رحمة الله عليه اینڈ سنز ٹریڈرز   •   BA BA FALAK NAZ & SON\'S TRADER\'S   •   Welcome To FNS Traders   •   ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: page,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          tooltip: 'WhatsApp',
          onPressed: _openWhatsApp,
          child: const Icon(Icons.chat_rounded, size: 30),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: bottomIndex,
          onDestinationSelected: (index) {
            setState(() => bottomIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: 'About',
            ),
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          ],
        ),
      ),
    );
  }
}
