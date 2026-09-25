import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  Product({required this.name, required this.price, this.inStock = true, this.imageBase64 = '', this.category = 'Other'});
  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'inStock': inStock, 'imageBase64': imageBase64, 'category': category};
  factory Product.fromJson(Map<String, dynamic> json) => Product(name: json['name']?.toString()?? '', price: int.tryParse(json['price'].toString())?? 0, inStock: json['inStock']?? true, imageBase64: json['imageBase64']?.toString()?? '', category: json['category']?.toString()?? 'Other');
}

class OrderData {
  final String orderNo; final String dateTime; final String customer; final String phone; final String address; final String items; final int total; final String payment;
  OrderData({required this.orderNo, required this.dateTime, required this.customer, required this.phone, required this.address, required this.items, required this.total, required this.payment});
  Map<String, dynamic> toJson() => {'orderNo': orderNo, 'dateTime': dateTime, 'customer': customer, 'phone': phone, 'address': address, 'items': items, 'total': total, 'payment': payment};
  factory OrderData.fromJson(Map<String, dynamic> json) => OrderData(orderNo: json['orderNo']?.toString()?? 'FNS-${DateTime.now().millisecondsSinceEpoch}', dateTime: json['dateTime']?.toString()?? '', customer: json['customer']?.toString()?? '', phone: json['phone']?.toString()?? '', address: json['address']?.toString()?? '', items: json['items']?.toString()?? '', total: int.tryParse(json['total'].toString())?? 0, payment: json['payment']?.toString()?? '');
}

class FnsApp extends StatefulWidget {
  const FnsApp({super.key});
  @override State<FnsApp> createState() => _FnsAppState();
}

class _FnsAppState extends State<FnsApp> {
  static const String whatsappNumber = '923343738405';
  int minOrderLimit = 0;
  List<Product> products = [
    Product(name: 'Hydryllin Syrup 120ml', price: 200, category: 'General'),
    Product(name: 'Pulmonol Syrup 120ml', price: 200, category: 'General'),
    Product(name: 'Lederplex Syrup 150ml', price: 234, category: 'General'),
    Product(name: 'Extor 5/80 Tablet', price: 490, category: 'General'),
    Product(name: 'Risek 40mg Capsule', price: 861, category: 'General'),
  ];
  final Map<Product, int> cart = {};
  final Set<String> favorites = {};
  final List<OrderData> orders = [];
  String searchText = ''; int bottomIndex = 0; bool loading = true; String selectedCategory = 'All';
  late final ScrollController _headlineController;
  static const List<String> categories = ['General', 'Glucometer', 'B.P Operator', 'Stethoscope', 'Surgical', 'Syrup', 'Tablet', 'Other'];

  @override
  void initState() { super.initState(); _headlineController = ScrollController(); loadSavedData(); WidgetsBinding.instance.addPostFrameCallback((_) => _startHeadlineScroll()); }

  void _startHeadlineScroll() async {
    await Future.delayed(const Duration(milliseconds: 700));
    while (mounted) {
      if (!_headlineController.hasClients) { await Future.delayed(const Duration(milliseconds: 500)); continue; }
      final max = _headlineController.position.maxScrollExtent;
      if (max <= 0) { await Future.delayed(const Duration(milliseconds: 500)); continue; }
      await _headlineController.animateTo(max, duration: const Duration(seconds: 12), curve: Curves.linear);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _headlineController.jumpTo(0);
    }
  }
  @override void dispose() { _headlineController.dispose(); super.dispose(); }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProducts = prefs.getString('products'); final savedFavorites = prefs.getStringList('favorites'); final savedOrders = prefs.getString('orders'); minOrderLimit = prefs.getInt('minOrderLimit')?? 0;
    if (savedProducts!= null && savedProducts.isNotEmpty) { try { final decoded = jsonDecode(savedProducts) as List; products = decoded.map((item) => Product.fromJson(Map<String, dynamic>.from(item))).toList(); } catch (_) {} }
    if (savedFavorites!= null) { favorites..clear()..addAll(savedFavorites); }
    if (savedOrders!= null && savedOrders.isNotEmpty) { try { final decoded = jsonDecode(savedOrders) as List; orders..clear()..addAll(decoded.map((item) => OrderData.fromJson(Map<String, dynamic>.from(item)))); } catch (_) {} }
    if (mounted) { setState(() { loading = false; }); }
  }
  Future<void> saveProducts() async { final prefs = await SharedPreferences.getInstance(); await prefs.setString('products', jsonEncode(products.map((product) => product.toJson()).toList())); }
  Future<void> saveFavorites() async { final prefs = await SharedPreferences.getInstance(); await prefs.setStringList('favorites', favorites.toList()); }
  Future<void> saveMinOrderLimit() async { final prefs = await SharedPreferences.getInstance(); await prefs.setInt('minOrderLimit', minOrderLimit); }
  Future<void> saveOrders() async { final prefs = await SharedPreferences.getInstance(); await prefs.setString('orders', jsonEncode(orders.map((order) => order.toJson()).toList())); }
  int get cartCount { int count = 0; for (final quantity in cart.values) { count += quantity; } return count; }
  int get cartTotal { int total = 0; for (final entry in cart.entries) { total += entry.key.price * entry.value; } return total; }
  List<Product> get filteredProducts {
    final query = searchText.trim().toLowerCase();
    return products.where((product) { final matchesCategory = selectedCategory == 'All' || product.category == selectedCategory; final matchesSearch = query.isEmpty || product.name.toLowerCase().contains(query) || product.category.toLowerCase().contains(query); return matchesCategory && matchesSearch; }).toList();
  }
  Widget productImage(Product product, {double size = 70}) {
    if (product.imageBase64.isNotEmpty) { try { return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(product.imageBase64), width: size, height: size, fit: BoxFit.cover)); } catch (_) {} }
    return Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade200), child: const Icon(Icons.shopping_bag, size: 35));
  }
  void addToCart(Product product) {
    if (!product.inStock) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This product is currently out of stock.'))); return; }
    setState(() { cart[product] = (cart[product]?? 0) + 1; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
  }
  void increaseQuantity(Product product) { setState(() { cart[product] = (cart[product]?? 0) + 1; }); }
  void decreaseQuantity(Product product) { setState(() { final quantity = cart[product]?? 0; if (quantity <= 1) { cart.remove(product); } else { cart[product] = quantity - 1; } }); }
  void toggleFavorite(Product product) { setState(() { if (favorites.contains(product.name)) { favorites.remove(product.name); } else { favorites.add(product.name); } }); saveFavorites(); }

  Widget homePage() {
    if (loading) { return const Center(child: CircularProgressIndicator()); }
    final visibleProducts = filteredProducts;
    return RefreshIndicator(onRefresh: loadSavedData, child: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 24), children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x22000000), offset: Offset(0, 3))]), child: Image.asset('fns_logo.png', width: double.infinity, height: 145, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 80))),
      const SizedBox(height: 10),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), color: Colors.green.shade700, child: const Center(child: Text('Welcome To FNS Traders', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(hintText: 'Search products...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (value) => setState(() => searchText = value)),
      const SizedBox(height: 12),
      SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: [_categoryChip('All'),...categories.map(_categoryChip)])),
      const SizedBox(height: 8),
      Text('${visibleProducts.length} product(s)', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      if (visibleProducts.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No products found.'))) else...visibleProducts.map(_productCard),
    ]));
  }
  Widget _categoryChip(String category) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(category), selected: selectedCategory == category, onSelected: (_) => setState(() => selectedCategory = category)));
  Widget _productCard(Product product) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(contentPadding: const EdgeInsets.all(10), leading: productImage(product, size: 58), title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${product.category}\nRetail: Rs. ${product.price}'), isThreeLine: true, trailing: SizedBox(width: 48, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(padding: EdgeInsets.zero, onPressed: () => toggleFavorite(product), icon: Icon(favorites.contains(product.name)? Icons.favorite : Icons.favorite_border)), IconButton(padding: EdgeInsets.zero, onPressed: product.inStock? () => addToCart(product) : null, icon: const Icon(Icons.add_shopping_cart))]))));
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'FNS TRADERS', home: Scaffold(body: homePage()));
  }
}
