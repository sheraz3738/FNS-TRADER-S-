import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const FnsApp());

class Product {
  String name;
  int price;
  String category;

  Product(this.name, this.price, this.category);
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
}

class FnsApp extends StatefulWidget {
  const FnsApp({super.key});

  @override
  State<FnsApp> createState() => _FnsAppState();
}

class _FnsAppState extends State<FnsApp> {
  final List<Product> products = [
    Product('Hydryllin Syrup 120ml', 200, 'Syrup'),
    Product('Pulmonol Syrup 120ml', 200, 'Syrup'),
    Product('Lederplex Syrup 150ml', 234, 'Syrup'),
    Product('Extor 5/80 Tablet', 490, 'Tablet'),
    Product('Risek 40mg Capsule', 861, 'Capsule'),
  ];

  final Map<Product, int> cart = {};
  final List<Order> orders = [];
  final Set<Product> favorites = {};

  String search = '';
  String selectedCategory = 'All';
  int bottomIndex = 0;

  int get total =>
      cart.entries.fold(0, (sum, e) => sum + e.key.price * e.value);

  int get cartCount =>
      cart.values.fold(0, (sum, quantity) => sum + quantity);

  void addToCart(Product product) {
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
              const Icon(Icons.medication, size: 60),
              const SizedBox(height: 10),
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
                'Category: ${product.category}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Retail Price: Rs. ${product.price}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  addToCart(product);
                  Navigator.pop(context);
                },
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
                height: MediaQuery.of(context).size.height * 0.75,
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
                                final product = entry.key;
                                final quantity = entry.value;

                                return Card(
                                  child: ListTile(
                                    title: Text(product.name),
                                    subtitle: Text(
                                      'Rs. ${product.price} × $quantity',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            removeFromCart(product);
                                            setSheetState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        ),
                                        Text('$quantity'),
                                        IconButton(
                                          onPressed: () {
                                            addToCart(product);
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
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

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
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
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
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            payment = value;
                          });
                        }
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
                    if (nameController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty ||
                        addressController.text.trim().isEmpty) {
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
                      customer: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                      payment: payment,
                      total: total,
                      items: items,
                    );

                    setState(() {
                      orders.add(order);
                    });

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

                    cart.clear();

                    Navigator.pop(context);

                    await openWhatsApp(message);

                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Order details sent to WhatsApp'),
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
    final list = products.map((p) => p.category).toSet().toList();
    return ['All', ...list];
  }

  List<Product> get shownProducts {
    return products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(search.toLowerCase());

      final matchesCategory =
          selectedCategory == 'All' ||
          product.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget homePage() {
    return Column(
      children: [
        const SizedBox(height: 10),

        // Logo
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
            onChanged: (value) {
              setState(() {
                search = value;
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
                    final product = shownProducts[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        onTap: () => showProductDetails(product),
                        leading: const CircleAvatar(
                          child: Icon(Icons.medication),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${product.category}\nRetail: Rs. ${product.price}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => toggleFavorite(product),
                              icon: Icon(
                                favorites.contains(product)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                            ),
                            FilledButton(
                              onPressed: () => addToCart(product),
                              child: const Text('Add'),
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

  Widget favoritesPage() {
    final favs = favorites.toList();

    if (favs.isEmpty) {
      return const Center(
        child: Text(
          'No favorite products',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: favs.map((product) {
        return Card(
          child: ListTile(
            title: Text(product.name),
            subtitle: Text('Rs. ${product.price}'),
            trailing: FilledButton(
              onPressed: () => addToCart(product),
              child: const Text('Add'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget ordersPage() {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders yet',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, index) {
        final order = orders[index];

        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(
              'Order ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Rs. ${order.total} • ${order.payment}'),
            children: [
              ListTile(
                title: const Text('Customer'),
                subtitle: Text('${order.customer} • ${order.phone}'),
              ),
              ListTile(
                title: const Text('Items'),
                subtitle: Text(order.items),
              ),
              ListTile(
                title: const Text('Delivery Address'),
                subtitle: Text(order.address),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget aboutPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Image.asset(
          'fns_logo.png',
          height: 130,
        ),
        const SizedBox(height: 20),
        const Text(
          "FNS TRADER'S",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "BABA FALAK NAZ & SON'S TRADER'S",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17),
        ),
        const SizedBox(height: 20),
        const ListTile(
          leading: Icon(Icons.phone),
          title: Text('Call / WhatsApp'),
          subtitle: Text('0334-3738405'),
        ),
        ListTile(
          leading: const Icon(Icons.chat),
          title: const Text('WhatsApp'),
          subtitle: const Text('Contact FNS TRADER\\'S'),
          onTap: () {
            openWhatsApp("Assalam o Alaikum FNS TRADER'S");
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      favoritesPage(),
      ordersPage(),
      aboutPage(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "FNS TRADER'S",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("FNS TRADER'S"),
          actions: [
            Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: showCart,
              ),
            ),
          ],
        ),
        body: pages[bottomIndex],
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
          ],
        ),
      ),
    );
  }
}
