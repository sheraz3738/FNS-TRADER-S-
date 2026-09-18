import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const FnsApp());

class Product {
  final String name;
  final int price;
  const Product(this.name, this.price);
}

const products = <Product>[
  Product('Hydryllin Syrup 120ml', 200),
  Product('Pulmonol Syrup 120ml', 200),
  Product('Lederplex Syrup 150ml', 234),
  Product('Extor 5/80 Tablet', 490),
  Product('Risek 40mg Capsule', 861),
];

class FnsApp extends StatefulWidget {
  const FnsApp({super.key});
  @override
  State<FnsApp> createState() => _FnsAppState();
}

class _FnsAppState extends State<FnsApp> {
  final Map<Product, int> cart = {};
  String search = '';

  int get total => cart.entries.fold(0, (s, e) => s + e.key.price * e.value);

  void add(Product p) => setState(() => cart[p] = (cart[p] ?? 0) + 1);

  Future<void> checkout() async {
    final items = cart.entries
        .map((e) => '${e.key.name} x${e.value}')
        .join(', ');
    final msg = Uri.encodeComponent(
      "FNS TRADER'S Order\n$items\nTotal: Rs. $total\n\nDelivery address: ",
    );
    final uri = Uri.parse('https://wa.me/923343738405?text=$msg');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final shown = products
        .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "FNS TRADER'S",
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("FNS TRADER'S"),
          actions: [
            Badge(
              label: Text('${cart.values.fold(0, (a, b) => a + b)}'),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Cart', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ...cart.entries.map((e) => ListTile(
                          title: Text(e.key.name),
                          subtitle: Text('Rs. ${e.key.price} × ${e.value}'),
                        )),
                        Text('Total: Rs. $total',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: cart.isEmpty ? null : checkout,
                          icon: const Icon(Icons.chat),
                          label: const Text('Order on WhatsApp'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),
            Image.asset('fns_logo.png', height: 100),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search products',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final p = shown[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(p.name),
                      subtitle: Text('Retail: Rs. ${p.price}'),
                      trailing: FilledButton(
                        onPressed: () => add(p),
                        child: const Text('Add'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
