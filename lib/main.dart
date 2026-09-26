import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const FnsApp());

class Product {
  String name; int price; bool inStock; String imageBase64; String category;
  Product({required this.name, required this.price, this.inStock = true, this.imageBase64 = '', this.category = 'Other'});
  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'inStock': inStock, 'imageBase64': imageBase64, 'category': category};
  factory Product.fromJson(Map<String, dynamic> json) => Product(name: json['name']?.toString() ?? '', price: int.tryParse(json['price'].toString()) ?? 0, inStock: json['inStock'] ?? true, imageBase64: json['imageBase64']?.toString() ?? '', category: json['category']?.toString() ?? 'Other');
}

class FnsApp extends StatefulWidget { const FnsApp({super.key}); @override State<FnsApp> createState() => _FnsAppState(); }

class _FnsAppState extends State<FnsApp> {
  static const String whatsappNumber = '923343738405';
  int minOrderLimit = 500;
  List<Product> products = [
    Product(name: 'Hydryllin Syrup 120ml', price: 200, category: 'General'),
    Product(name: 'Pulmonol Syrup 120ml', price: 200, category: 'General'),
    Product(name: 'Lederplex Syrup 150ml', price: 234, category: 'General'),
    Product(name: 'Extor 5/80 Tablet', price: 490, category: 'General'),
    Product(name: 'Risek 40mg Capsule', price: 861, category: 'General'),
  ];
  final Map<Product, int> cart = {}; final Set<String> favorites = {}; String searchText = ''; int bottomIndex = 0; bool loading = true; String selectedCategory = 'All';
  late final ScrollController _headlineController;
  static const List<String> categories = ['General', 'Glucometer', 'B.P Operator', 'Stethoscope', 'Surgical', 'Syrup', 'Tablet', 'Other'];

  Future<void> _openWhatsApp({String? message}) async {
    final uri = Uri.parse('https://wa.me/$whatsappNumber${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}');
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  @override
  void initState() { super.initState(); _headlineController = ScrollController(); loadSavedData(); WidgetsBinding.instance.addPostFrameCallback((_) => _startHeadlineScroll()); }

  void _startHeadlineScroll() async {
    await Future.delayed(const Duration(milliseconds: 700));
    while (mounted) {
      if (!_headlineController.hasClients) { await Future.delayed(const Duration(milliseconds: 500)); continue; }
      final max = _headlineController.position.maxScrollExtent;
      if (max <= 0) { await Future.delayed(const Duration(milliseconds: 500)); continue; }
      await _headlineController.animateTo(max, duration: const Duration(seconds: 20), curve: Curves.linear);
      if (!mounted) return; await Future.delayed(const Duration(milliseconds: 400)); _headlineController.jumpTo(0);
    }
  }

  @override void dispose() { _headlineController.dispose(); super.dispose(); }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProducts = prefs.getString('products'); final savedFav = prefs.getStringList('favorites');
    minOrderLimit = prefs.getInt('minOrderLimit') ?? 500;
    if (savedProducts != null && savedProducts.isNotEmpty) { try { final d = jsonDecode(savedProducts) as List; products = d.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (_) {} }
    if (savedFav != null) { favorites..clear()..addAll(savedFav); }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveProducts() async { final prefs = await SharedPreferences.getInstance(); await prefs.setString('products', jsonEncode(products.map((p) => p.toJson()).toList())); }
  Future<void> saveFavorites() async { final prefs = await SharedPreferences.getInstance(); await prefs.setStringList('favorites', favorites.toList()); }

  List<Product> get filteredProducts {
    final q = searchText.trim().toLowerCase();
    return products.where((p) { final cat = selectedCategory == 'All' || p.category == selectedCategory; final s = q.isEmpty || p.name.toLowerCase().contains(q); return cat && s; }).toList();
  }

  Widget productImage(Product p, {double size = 70}) {
    if (p.imageBase64.isNotEmpty) { try { return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(p.imageBase64), width: size, height: size, fit: BoxFit.cover)); } catch (_) {} }
    return Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade200), child: const Icon(Icons.shopping_bag, size: 35));
  }

  void addToCart(Product p) { if (!p.inStock) return; setState(() => cart[p] = (cart[p] ?? 0) + 1); }

  Widget homePage() {
    final visible = filteredProducts;
    return ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 24), children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x22000000), offset: Offset(0, 3))]), child: Image.asset('fns_logo.png', height: 145, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.store, size: 80))),
      const SizedBox(height: 10),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), color: Colors.green.shade700, child: const Center(child: Text('مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(hintText: 'Search products...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => searchText = v)),
      const SizedBox(height: 12),
      SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: [ _chip('All'), ...categories.map(_chip)])),
      const SizedBox(height: 8), Text('${visible.length} product(s)', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      ...visible.map((p) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: productImage(p, size: 58), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${p.category} - Rs. ${p.price} - ${p.inStock ? "In Stock" : "Out"}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [ IconButton(onPressed: () { setState(() { if (favorites.contains(p.name)) favorites.remove(p.name); else favorites.add(p.name); }); saveFavorites(); }, icon: Icon(favorites.contains(p.name) ? Icons.favorite : Icons.favorite_border)), IconButton(onPressed: () => addToCart(p), icon: const Icon(Icons.add_shopping_cart))])))),
    ]);
  }

  Widget _chip(String c) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c), selected: selectedCategory == c, onSelected: (_) => setState(() => selectedCategory = c)));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // FINAL SCROLLING HEADLINE - NO NUMBER
              Container(
                height: 32, color: const Color(0xFF1E4DB7),
                child: SingleChildScrollView(
                  controller: _headlineController, scrollDirection: Axis.horizontal,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      ' بابا فلک ناز رحمۃ اللہ علیہ اینڈ سنز ٹریڈرز | Welcome To FNS TRADER´S | BABA FALAK NAZ & SON´S TRADER´S | بابا فلک ناز رحمۃ اللہ علیہ اینڈ سنز ٹریڈرز | Welcome To FNS TRADER´S | BABA FALAK NAZ & SON´S TRADER´S | ',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ),
              Expanded(child: bottomIndex == 0 ? homePage() : Center(child: Text('Page $bottomIndex'))),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF25D366), onPressed: () => _openWhatsApp(), child: const Icon(Icons.chat, color: Colors.white)),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: bottomIndex, onTap: (i) => setState(() => bottomIndex = i), type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green.shade700,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorite"), BottomNavigationBarItem(icon: Icon(Icons.info), label: "About"),
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
          ],
        ),
      ),
    );
  }
}
