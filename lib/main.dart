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
      name: json['name']?.toString()?? '',
      price: int.tryParse(json['price'].toString())?? 0,
      inStock: json['inStock']?? true,
      imageBase64: json['imageBase64']?.toString()?? '',
      category: json['category']?.toString()?? 'Other',
    );
  }
}

class OrderData {
  final String orderNo;
  final String dateTime;
  final String customer;
  final String phone;
  final String address;
  final String items;
  final int total;
  final String payment;

  OrderData({
    required this.orderNo,
    required this.dateTime,
    required this.customer,
    required this.phone,
    required this.address,
    required this.items,
    required this.total,
    required this.payment,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderNo': orderNo,
      'dateTime': dateTime,
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
      orderNo: json['orderNo']?.toString()?? 'FNS-${DateTime.now().millisecondsSinceEpoch}',
      dateTime: json['dateTime']?.toString()?? '',
      customer: json['customer']?.toString()?? '',
      phone: json['phone']?.toString()?? '',
      address: json['address']?.toString()?? '',
      items: json['items']?.toString()?? '',
      total: int.tryParse(json['total'].toString())?? 0,
      payment: json['payment']?.toString()?? '',
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
    Product(name: 'Hydryllin Syrup 120ml', price: 200, category: 'General'),
    Product(name: 'Pulmonol Syrup 120ml', price: 200, category: 'General'),
    Product(name: 'Lederplex Syrup 150ml', price: 234, category: 'General'),
    Product(name: 'Extor 5/80 Tablet', price: 490, category: 'General'),
    Product(name: 'Risek 40mg Capsule', price: 861, category: 'General'),
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
    final encodedMessage = message == null? '' : '&text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse('https://wa.me/$whatsappNumber?${encodedMessage.isEmpty? '' : encodedMessage.substring(1)}');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {}
    final fallback = Uri.parse('whatsapp://send?phone=$whatsappNumber${message == null? '' : '&text=${Uri.encodeComponent(message)}'}');
    try {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _headlineController = ScrollController();
    loadSavedData();
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
    minOrderLimit = prefs.getInt('minOrderLimit')?? 0;
    if (savedProducts!= null && savedProducts.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedProducts) as List;
        products = decoded.map((item) => Product.fromJson(Map<String, dynamic>.from(item))).toList();
      } catch (_) {}
    }
    if (savedFavorites!= null) {
      favorites..clear()..addAll(savedFavorites);
    }
    if (savedOrders!= null && savedOrders.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedOrders) as List;
        orders..clear()..addAll(decoded.map((item) => OrderData.fromJson(Map<String, dynamic>.from(item))));
      } catch (_) {}
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', jsonEncode(products.map((p) => p.toJson()).toList()));
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  Future<void> saveMinOrderLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minOrderLimit', minOrderLimit);
  }

  Future<void> saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('orders', jsonEncode(orders.map((o) => o.toJson()).toList()));
  }

  int get cartCount { int count = 0; for (final q in cart.values) count += q; return count; }
  int get cartTotal { int total = 0; for (final e in cart.entries) total += e.key.price * e.value; return total; }

  List<Product> get filteredProducts {
    final query = searchText.trim().toLowerCase();
    return products.where((p) {
      final matchesCategory = selectedCategory == 'All' || p.category == selectedCategory;
      final matchesSearch = query.isEmpty || p.name.toLowerCase().contains(query) || p.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget productImage(Product product, {double size = 70}) {
    if (product.imageBase64.isNotEmpty) {
      try {
        return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(product.imageBase64), width: size, height: size, fit: BoxFit.cover));
      } catch (_) {}
    }
    return Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade200), child: const Icon(Icons.shopping_bag, size: 35));
  }

  void addToCart(Product product) {
    if (!product.inStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This product is currently out of stock.')));
      return;
    }
    setState(() => cart[product] = (cart[product]?? 0) + 1);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
  }

  void increaseQuantity(Product product) => setState(() => cart[product] = (cart[product]?? 0) + 1);
  void decreaseQuantity(Product product) {
    setState(() {
      final q = cart[product]?? 0;
      if (q <= 1) cart.remove(product); else cart[product] = q - 1;
    });
  }

  void toggleFavorite(Product product) {
    setState(() {
      if (favorites.contains(product.name)) favorites.remove(product.name); else favorites.add(product.name);
    });
    saveFavorites();
  }

  void showProductDetails(Product product) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      productImage(product, size: 120), const SizedBox(height: 15),
      Text(product.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Text('Retail: Rs. ${product.price}', style: const TextStyle(fontSize: 18)), const SizedBox(height: 15),
      Text(product.inStock? 'In Stock' : 'Out of Stock', style: TextStyle(color: product.inStock? Colors.green : Colors.red, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: product.inStock? () { Navigator.pop(context); addToCart(product); } : null, icon: const Icon(Icons.shopping_cart), label: const Text('Add to Cart'))),
    ]))));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: [homePage(), cartFullPage(), favFullPage(), aboutFullPage(), adminLoginPage()][bottomIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: bottomIndex, type: BottomNavigationBarType.fixed, selectedItemColor: Colors.green[800],
          onTap: (i) => setState(() => bottomIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          ],
        ),
      ),
    );
  }

  Widget homePage() {
    if (loading) return const Center(child: CircularProgressIndicator());
    final visibleProducts = filteredProducts;
    return RefreshIndicator(
      onRefresh: loadSavedData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x22000000), offset: Offset(0, 3))]),
            child: Image.asset('fns_logo.png', width: double.infinity, height: 145, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 80)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.green.shade700,
            child: const Center(
              child: Text(
                'مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(hintText: 'Search products...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (value) => setState(() => searchText = value)),
          const SizedBox(height: 12),
          SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: [_categoryChip('All'),...categories.map(_categoryChip)])),
          const SizedBox(height: 8),
          Text('${visibleProducts.length} product(s)', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (visibleProducts.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No products found.'))) else...visibleProducts.map(_productCard),
        ],
      ),
    );
  }

  Widget _categoryChip(String category) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(category), selected: selectedCategory == category, onSelected: (_) => setState(() => selectedCategory = category)));

  Widget _productCard(Product product) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(contentPadding: const EdgeInsets.all(10), leading: productImage(product, size: 58), title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${product.category}\nRetail: Rs. ${product.price}'), isThreeLine: true, onTap: () => showProductDetails(product), trailing: SizedBox(width: 48, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(padding: EdgeInsets.zero, onPressed: () => toggleFavorite(product), icon: Icon(favorites.contains(product.name)? Icons.favorite : Icons.favorite_border)), IconButton(padding: EdgeInsets.zero, onPressed: product.inStock? () => addToCart(product) : null, icon: const Icon(Icons.add_shopping_cart))]))));

  Widget cartFullPage() => Scaffold(appBar: AppBar(title: Text('Cart (${cartCount}) - Rs. $cartTotal'), backgroundColor: Colors.green), body: Column(children: [Expanded(child: cart.isEmpty? const Center(child: Text('Your cart is empty')) : ListView(padding: const EdgeInsets.all(12), children: cart.entries.map((entry) => Card(child: ListTile(leading: productImage(entry.key, size: 55), title: Text(entry.key.name), subtitle: Text('Rs. ${entry.key.price} x ${entry.value}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () { decreaseQuantity(entry.key); }, icon: const Icon(Icons.remove_circle)), Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(onPressed: () { increaseQuantity(entry.key); }, icon: const Icon(Icons.add_circle))])))).toList())), if (cart.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text('Total: Rs. $cartTotal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => showCheckoutSheet(), child: const Text('Checkout')))]))]));

  Widget favFullPage() => Scaffold(appBar: AppBar(title: const Text('Favorites'), backgroundColor: Colors.green), body: favorites.isEmpty? const Center(child: Text('No favorites')) : ListView(children: products.where((p) => favorites.contains(p.name)).map((p) => ListTile(leading: productImage(p), title: Text(p.name), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => toggleFavorite(p)))).toList()));

  Widget aboutFullPage() => Scaffold(appBar: AppBar(title: const Text('About'), backgroundColor: Colors.green), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset('fns_logo.png', height: 120, errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 80)), const SizedBox(height: 12), const Text('مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 6), const Text('BABA FALAK NAZ & SON\'S TRADERS', style: TextStyle(fontWeight: FontWeight.bold)), const Text('FNS TRADERS'), ElevatedButton(onPressed: () => _openWhatsApp(), child: const Text('WhatsApp: 0334-3738405'))])));

  Widget adminLoginPage() {
    final ctrl = TextEditingController();
    return Scaffold(appBar: AppBar(title: const Text('Admin Login'), backgroundColor: Colors.green), body: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password (Default 1234)', border: OutlineInputBorder())), const SizedBox(height: 15), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { if (ctrl.text == '1234') { Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanelFull(products: products, onUpdate: (l) { setState(() => products = l); saveProducts(); }, minLimit: minOrderLimit, onLimitChange: (v) { setState(() => minOrderLimit = v); saveMinOrderLimit(); }))); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong Password'))); } }, child: const Text('Login')))])));
  }

  void showCheckoutSheet() {
    final nameC = TextEditingController(); final phoneC = TextEditingController(); final addrC = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 15, right: 15, top: 15), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Customer Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')), TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone')), TextField(controller: addrC, decoration: const InputDecoration(labelText: 'Address')), const SizedBox(height: 15),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
        final orderNo = 'FNS-${DateTime.now().millisecondsSinceEpoch}'; final itemsStr = cart.entries.map((e) => '${e.key.name} x${e.value}').join(', ');
        final order = OrderData(orderNo: orderNo, dateTime: DateTime.now().toString().substring(0, 16), customer: nameC.text, phone: phoneC.text, address: addrC.text, items: itemsStr, total: cartTotal, payment: 'Cash');
        orders.add(order); await saveOrders();
        final pdf = pw.Document();
        pdf.addPage(pw.Page(build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('FNS TRADERS - Invoice', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)), pw.Text('MASHALLAH LA QUWATA ILLA BILLAH'), pw.SizedBox(height: 10), pw.Text('Order: $orderNo'), pw.Text('Customer: ${nameC.text}'), pw.Text('Phone: ${phoneC.text}'), pw.Text('Address: ${addrC.text}'), pw.Divider(),...cart.entries.map((e) => pw.Text('${e.key.name} x${e.value} = Rs. ${e.key.price * e.value}')), pw.Divider(), pw.Text('Total: Rs. $cartTotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))])));
        await Printing.layoutPdf(onLayout: (f) async => pdf.save());
        _openWhatsApp(message: 'New Order $orderNo\nCustomer: ${nameC.text}\nPhone: ${phoneC.text}\nAddress: ${addrC.text}\nItems: $itemsStr\nTotal: Rs. $cartTotal');
        setState(() => cart.clear()); Navigator.pop(ctx);
      }, child: const Text('Confirm & Print PDF'))), const SizedBox(height: 15),
    ])));
  }
}

class AdminPanelFull extends StatefulWidget {
  final List<Product> products; final Function(List<Product>) onUpdate; final int minLimit; final Function(int) onLimitChange;
  const AdminPanelFull({super.key, required this.products, required this.onUpdate, required this.minLimit, required this.onLimitChange});
  @override State<AdminPanelFull> createState() => _AdminPanelFullState();
}
class _AdminPanelFullState extends State<AdminPanelFull> {
  final _name = TextEditingController(); final _price = TextEditingController(); final _cat = TextEditingController(text: 'General'); String _img = ''; final picker = ImagePicker();
  Future<void> pickImage() async { final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); if (x!= null) { final b = await x.readAsBytes(); setState(() => _img = base64Encode(b)); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Admin - Stock with Photo'), backgroundColor: Colors.green), body: SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Add Stock with Picture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    TextField(controller: _name, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder())), const SizedBox(height: 8),
    TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number), const SizedBox(height: 8),
    TextField(controller: _cat, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())), const SizedBox(height: 8),
    Row(children: [ElevatedButton(onPressed: pickImage, child: const Text('Pick Photo')), const SizedBox(width: 10), if (_img.isNotEmpty) Image.memory(base64Decode(_img), width: 60, height: 60)]),
    const SizedBox(height: 8), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { if (_name.text.isEmpty) return; final p = Product(name: _name.text, price: int.tryParse(_price.text)?? 0, category: _cat.text, imageBase64: _img); final list = List<Product>.from(widget.products)..add(p); widget.onUpdate(list); _name.clear(); _price.clear(); setState(() => _img = ''); }, child: const Text('Add Stock'))),
    const Divider(height: 30), Text('Limit Fix - Current: Rs. ${widget.minLimit}'), Wrap(spacing: 6, children: [0, 500, 1000, 1500, 2000, 2500, 5000].map((v) => ChoiceChip(label: Text('Rs. $v'), selected: widget.minLimit == v, onSelected: (_) => widget.onLimitChange(v))).toList()),
    const Divider(height: 30), const Text('Stock ON/OFF & Delete', style: TextStyle(fontWeight: FontWeight.bold)),
  ...widget.products.map((p) => Card(child: ListTile(leading: p.imageBase64.isNotEmpty? Image.memory(base64Decode(p.imageBase64), width: 40, height: 40, errorBuilder: (a, b, c) => const Icon(Icons.image)) : const Icon(Icons.medication), title: Text(p.name), subtitle: Text('Rs. ${p.price} - ${p.inStock? "In Stock" : "Out of Stock"}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Switch(value: p.inStock, onChanged: (v) { setState(() => p.inStock = v); widget.onUpdate(widget.products); }), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { final list = List<Product>.from(widget.products)..remove(p); widget.onUpdate(list); })])))),
  ])));
}
