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

  Product({
    required this.name,
    required this.price,
    this.inStock = true,
    this.imageBase64 = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'inStock': inStock,
      'imageBase64': imageBase64,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name']?.toString() ?? '',
      price: int.tryParse(json['price'].toString()) ?? 0,
      inStock: json['inStock'] ?? true,
      imageBase64: json['imageBase64']?.toString() ?? '',
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

  List<Product> products = [
    Product(
      name: 'Hydryllin Syrup 120ml',
      price: 200,
    ),
    Product(
      name: 'Pulmonol Syrup 120ml',
      price: 200,
    ),
    Product(
      name: 'Lederplex Syrup 150ml',
      price: 234,
    ),
    Product(
      name: 'Extor 5/80 Tablet',
      price: 490,
    ),
    Product(
      name: 'Risek 40mg Capsule',
      price: 861,
    ),
  ];

  final Map<Product, int> cart = {};
  final Set<String> favorites = {};
  final List<OrderData> orders = [];

  String searchText = '';
  int bottomIndex = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedProducts = prefs.getString('products');
    final savedFavorites = prefs.getStringList('favorites');
    final savedOrders = prefs.getString('orders');

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
    final visibleProducts = filteredProducts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        setState(() {
                          searchText = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        Expanded(
          child: visibleProducts.isEmpty
              ? const Center(
                  child: Text('No products found'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    20,
                  ),
                  itemCount: visibleProducts.length,
                  itemBuilder: (context, index) {
                    final product = visibleProducts[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: productImage(product),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Retail: Rs. ${product.price}\n'
                            '${product.inStock ? 'In Stock' : 'Out of Stock'}',
                            style: TextStyle(
                              color: product.inStock
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  toggleFavorite(product),
                              icon: Icon(
                                favorites.contains(product.name)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favorites.contains(product.name)
                                    ? Colors.red
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => showProductDetails(product),
                      ),
                    );
                  },
                ),
        ),
      ],
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

    final message = Uri.encodeComponent(
      'FNS TRADER\'S Order\n'
      'Customer: $customer\n'
      'Phone: $phone\n'
      'Address: $address\n'
      'Items: $itemText\n'
      'Total: Rs. ${order.total}\n'
      'Payment: $payment',
    );

    final uri = Uri.parse(
      'https://wa.me/$whatsappNumber?text=$message',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  void showAdminPanel(BuildContext panelContext) {
    showModalBottomSheet(
      context: panelContext,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.9,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Admin Panel',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        itemBuilder: (_, index) {
                          final product = products[index];
                          return Card(
                            child: ListTile(
                              leading: productImage(product, size: 50),
                              title: Text(product.name),
                              subtitle: Text(
                                'Rs. ${product.price} • '
                                '${product.inStock ? 'In Stock' : 'Out of Stock'}',
                              ),
                              trailing: Switch(
                                value: product.inStock,
                                onChanged: (value) async {
                                  setState(() => product.inStock = value);
                                  await saveProducts();
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 70),
            const SizedBox(height: 15),
            const Text(
              "FNS TRADER'S",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "BA FALAK NAZ & SON'S TRADER'S",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'WhatsApp: 0334-3738405',
              textAlign: TextAlign.center,
            ),
          ],
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
        ),
        body: page,
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
