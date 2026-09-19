import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const FnsApp());

class Product {
  String id;
  String name;
  int price;
  String category;
  bool stock;
  String? imageBase64;

  Product(
    this.id,
    this.name,
    this.price,
    this.category, {
    this.stock = true,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'stock': stock,
        'imageBase64': imageBase64,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        j['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
        j['name'] ?? '',
        int.tryParse('${j['price'] ?? 0}') ?? 0,
        j['category'] ?? 'Other',
        stock: j['stock'] ?? true,
        imageBase64: j['imageBase64'],
      );
}

class Order {
  final String customer;
  final String phone;
  final String address;
  final String payment;
  final int total;
  final String items;

  Order({
    required this.customer,
    required this.phone,
    required this.address,
    required this.payment,
    required this.total,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'customer': customer,
        'phone': phone,
        'address': address,
        'payment': payment,
        'total': total,
        'items': items,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        customer: j['customer'] ?? '',
        phone: j['phone'] ?? '',
        address: j['address'] ?? '',
        payment: j['payment'] ?? 'Cash on Delivery',
        total: int.tryParse('${j['total'] ?? 0}') ?? 0,
        items: j['items'] ?? '',
      );
}

class FnsApp extends StatefulWidget {
  const FnsApp({super.key});

  @override
  State<FnsApp> createState() => _FnsAppState();
}

class _FnsAppState extends State<FnsApp> {
  final List<Product> products = [
    Product('1', 'Hydryllin Syrup 120ml', 200, 'Syrup'),
    Product('2', 'Pulmonol Syrup 120ml', 200, 'Syrup'),
    Product('3', 'Lederplex Syrup 150ml', 234, 'Syrup'),
    Product('4', 'Extor 5/80 Tablet', 490, 'Tablet'),
    Product('5', 'Risek 40mg Capsule', 861, 'Capsule'),
  ];

  final Map<Product, int> cart = {};
  final List<Order> orders = [];
  final Set<Product> favorites = {};

  String search = '';
  String selectedCategory = 'All';
  int bottomIndex = 0;
  bool loading = true;

  int get total =>
      cart.entries.fold(0, (sum, e) => sum + e.key.price * e.value);

  int get cartCount =>
      cart.values.fold(0, (sum, quantity) => sum + quantity);

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedProducts = prefs.getString('fns_products');
    final savedOrders = prefs.getString('fns_orders');

    if (savedProducts != null) {
      final list = jsonDecode(savedProducts) as List;

      products
        ..clear()
        ..addAll(
          list.map(
            (e) => Product.fromJson(
              Map<String, dynamic>.from(e),
            ),
          ),
        );
    }

    if (savedOrders != null) {
      final list = jsonDecode(savedOrders) as List;

      orders
        ..clear()
        ..addAll(
          list.map(
            (e) => Order.fromJson(
              Map<String, dynamic>.from(e),
            ),
          ),
        );
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
      'fns_products',
      jsonEncode(
        products.map((p) => p.toJson()).toList(),
      ),
    );
  }

  Future<void> saveOrders() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'fns_orders',
      jsonEncode(
        orders.map((o) => o.toJson()).toList(),
      ),
    );
  }

  Widget productImage(
    Product product, {
    double size = 65,
  }) {
    if (product.imageBase64 != null &&
        product.imageBase64!.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(product.imageBase64!),
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
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade200,
      ),
      child: Icon(
        product.stock ? Icons.medication : Icons.block,
        size: size * .5,
      ),
    );
  }

  void addToCart(Product product) {
    if (!product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is out of stock'),
        ),
      );
      return;
    }

    setState(() {
      cart[product] = (cart[product] ?? 0) + 1;
    });
  }

  void removeFromCart(Product product) {
    setState(() {
      if ((cart[product] ?? 0) > 1) {
        cart[product] = cart[product]! - 1;
      } else {
        cart.remove(product);
      }
    });
  }

  void toggleFavorite(Product product) {
    setState(() {
      if (favorites.contains(product)) {
        favorites.remove(product);
      } else {
        favorites.add(product);
      }
    });
  }

  Future<void> openWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);

    final uri = Uri.parse(
      'https://wa.me/923343738405?text=$encoded',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  void showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              productImage(product, size: 150),
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
              Text('Category: ${product.category}'),
              const SizedBox(height: 8),
              Text(
                'Retail Price: Rs. ${product.price}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.stock ? 'In Stock' : 'Out of Stock',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: product.stock
                    ? () {
                        addToCart(product);
                        Navigator.pop(context);
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to Cart'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .75,
                child: Column(
                  children: [
                    const Text(
                      'Shopping Cart',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: cart.isEmpty
                          ? const Center(
                              child: Text('Cart is empty'),
                            )
                          : ListView(
                              children: cart.entries.map((entry) {
                                final p = entry.key;
                                final q = entry.value;

                                return Card(
                                  child: ListTile(
                                    leading: productImage(
                                      p,
                                      size: 55,
                                    ),
                                    title: Text(p.name),
                                    subtitle:
                                        Text('Rs. ${p.price} × $q'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            removeFromCart(p);
                                            setSheetState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        ),
                                        Text('$q'),
                                        IconButton(
                                          onPressed: () {
                                            addToCart(p);
                                            setSheetState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const Divider(),
                    Text(
                      'Total: Rs. $total',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: cart.isEmpty
                            ? null
                            : () {
                                Navigator.pop(context);
                                showCheckout();
                              },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Checkout'),
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
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();

    String payment = 'Cash on Delivery';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Checkout'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: address,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: payment,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Cash on Delivery',
                          child: Text('Cash on Delivery'),
                        ),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          payment = v ?? payment;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty ||
                        phone.text.trim().isEmpty ||
                        address.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all details'),
                        ),
                      );
                      return;
                    }

                    final items = cart.entries
                        .map(
                          (e) =>
                              '${e.key.name} × ${e.value} = Rs. ${e.key.price * e.value}',
                        )
                        .join('\n');

                    final order = Order(
                      customer: name.text.trim(),
                      phone: phone.text.trim(),
                      address: address.text.trim(),
                      payment: payment,
                      total: total,
                      items: items,
                    );

                    setState(() {
                      orders.add(order);
                    });

                    await saveOrders();

                    final message = '''
FNS TRADER'S ORDER

Customer: ${order.customer}
Mobile: ${order.phone}

Items:
${order.items}

Total: Rs. ${order.total}

Payment: ${order.payment}

Delivery Address:
${order.address}
''';

                    setState(() {
                      cart.clear();
                    });

                    Navigator.pop(context);

                    await openWhatsApp(message);

                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Order details sent to WhatsApp',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Place Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> get categories {
    final list = products
        .map((p) => p.category)
        .where((x) => x.trim().isNotEmpty)
        .toSet()
        .toList();

    return ['All', ...list];
  }

  List<Product> get shownProducts {
    return products.where((product) {
      final searchMatch = product.name
          .toLowerCase()
          .contains(search.toLowerCase());

      final categoryMatch =
          selectedCategory == 'All' ||
          product.category == selectedCategory;

      return searchMatch && categoryMatch;
    }).toList();
  }
void showAdminLogin() {
  final password = TextEditingController();

  showDialog(
    context: context,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (password.text == '1234') {
                Navigator.pop(context);
                showAdminPanel();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wrong password'),
                  ),
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

void showAdminPanel() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Product management will be added here.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  Widget homePage() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Image.asset(
          'fns_logo.png',
          height: 105,
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search products',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              setState(() {
                search = v;
              });
            },
          ),
        ),
        SizedBox(
          height: 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
                Expanded(
          child: shownProducts.isEmpty
              ? const Center(
                  child: Text('No products found'),
                )
              : ListView.builder(
                  itemCount: shownProducts.length,
                  itemBuilder: (_, index) {
                    final p = shownProducts[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        onTap: () => showProductDetails(p),
                        leading: productImage(p, size: 60),
                        title: Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${p.category}\nRetail: Rs. ${p.price}${p.stock ? '' : '\nOut of Stock'}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => toggleFavorite(p),
                              icon: Icon(
                                favorites.contains(p)
                             ? Icons.favorite
                              : Icons.favorite_border,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
    @override
  Widget build(BuildContext context) {
    Widget page;

    if (bottomIndex == 0) {
      page = homePage();
    } else if (bottomIndex == 1) {
      page = favorites.isEmpty
          ? const Center(
              child: Text('No favorite products'),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: favorites.map((p) {
                return Card(
                  child: ListTile(
                    leading: productImage(p, size: 55),
                    title: Text(p.name),
                    subtitle: Text('Retail: Rs. ${p.price}'),
                    trailing: IconButton(
                      onPressed: () => toggleFavorite(p),
                      icon: const Icon(Icons.favorite),
                    ),
                    onTap: () => showProductDetails(p),
                  ),
                );
              }).toList(),
            );
    } else if (bottomIndex == 2) {
      page = orders.isEmpty
          ? const Center(
              child: Text('No orders yet'),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: orders.map((order) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(order.customer),
                    subtitle: Text(
                      '${order.items}\nTotal: Rs. ${order.total}\n'
                      'Address: ${order.address}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            );
    } else if (bottomIndex == 3) {
      page = const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            "FNS TRADER'S\n\n"
            "BA FALAK NAZ & SON'S TRADER'S\n\n"
            "Call / WhatsApp: 0334-3738405",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    
} else {
  page = Center(
    child: FilledButton.icon(
      onPressed: showAdminLogin,
      icon: const Icon(Icons.admin_panel_settings),
      label: const Text('Open Admin Panel'),
    ),
  );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "FNS TRADER'S",
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            bottomIndex == 0
                ? "FNS TRADER'S"
                : bottomIndex == 1
                    ? 'Favorites'
                    : bottomIndex == 2
                        ? 'Orders'
                        : bottomIndex == 3
                            ? 'About'
                            : 'Admin',
          ),
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
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : page,
        bottomNavigationBar: NavigationBar(
          selectedIndex: bottomIndex,
          onDestinationSelected: (index) {
            setState(() {
              bottomIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
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
