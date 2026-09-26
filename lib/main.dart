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
  List<Product> products = [ Product(name: 'Hydryllin Syrup 120ml', price: 200), Product(name: 'Pulmonol Syrup 120ml', price: 200), ];
  final Map<Product, int> cart = {}; final Set<String> favorites = {}; String searchText = ''; int bottomIndex = 0; String selectedCategory = 'All';
  late final ScrollController _headlineController;
  static const List<String> categories = ['General', 'Glucometer', 'B.P Operator', 'Stethoscope', 'Surgical', 'Syrup', 'Tablet', 'Other'];

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$whatsappNumber');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() { super.initState(); _headlineController = ScrollController(); WidgetsBinding.instance.addPostFrameCallback((_) => _startHeadlineScroll()); }
  void _startHeadlineScroll() async {
    await Future.delayed(const Duration(milliseconds: 700));
    while (mounted) {
      if (!_headlineController.hasClients) { await Future.delayed(const Duration(milliseconds: 500)); continue; }
      final max = _headlineController.position.maxScrollExtent;
      if (max <= 0) { await Future.delayed(const Duration(milliseconds: 500)); continue; }
      await _headlineController.animateTo(max, duration: const Duration(seconds: 22), curve: Curves.linear);
      if (!mounted) return; await Future.delayed(const Duration(milliseconds: 400)); _headlineController.jumpTo(0);
    }
  }
  @override void dispose() { _headlineController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 32, color: const Color(0xFF1E4DB7),
                child: SingleChildScrollView(
                  controller: _headlineController, scrollDirection: Axis.horizontal,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(' بابا فلک ناز رحمۃ اللہ علیہ اینڈ سنز ٹریڈرز | Welcome To FNS TRADER´S | BABA FALAK NAZ & SON´S TRADER´S | بابا فلک ناز رحمۃ اللہ علیہ اینڈ سنز ٹریڈرز | Welcome To FNS TRADER´S | BABA FALAK NAZ & SON´S TRADER´S | ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ),
              Expanded(child: ListView(padding: const EdgeInsets.all(14), children: [
                Image.asset('fns_logo.png', height: 145, errorBuilder: (_,__,___) => const Icon(Icons.store, size: 80)),
                const SizedBox(height: 10),
                Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), color: Colors.green.shade700, child: const Center(child: Text('مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)))),
                const SizedBox(height: 20), const Center(child: Text('Aapka purana design yahin rahega', style: TextStyle(fontWeight: FontWeight.bold))),
              ])),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF25D366), onPressed: _openWhatsApp, child: const Icon(Icons.chat, color: Colors.white)),
        bottomNavigationBar: BottomNavigationBar(currentIndex: bottomIndex, onTap: (i) => setState(() => bottomIndex = i), type: BottomNavigationBarType.fixed, items: const [ BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"), BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorite"), BottomNavigationBarItem(icon: Icon(Icons.info), label: "About"), BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),]),
      ),
    );
  }
}
