import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() { runApp(const FnsApp()); }

class Product {
  String name; int price; bool inStock; String imageBase64; String category;
  Product({required this.name, required this.price, this.inStock = true, this.imageBase64 = '', this.category = 'Other'});
  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'inStock': inStock, 'imageBase64': imageBase64, 'category': category};
  factory Product.fromJson(Map<String, dynamic> j) => Product(name: j['name'].toString(), price: int.tryParse(j['price'].toString()) ?? 0, inStock: j['inStock'] ?? true, imageBase64: j['imageBase64'].toString(), category: j['category']?.toString() ?? 'Other');
}

class OrderData {
  final String orderNo, dateTime, customer, phone, address, items; final int total; final String payment;
  OrderData({required this.orderNo, required this.dateTime, required this.customer, required this.phone, required this.address, required this.items, required this.total, required this.payment});
  Map<String, dynamic> toJson() => {'orderNo': orderNo, 'dateTime': dateTime, 'customer': customer, 'phone': phone, 'address': address, 'items': items, 'total': total, 'payment': payment};
  factory OrderData.fromJson(Map<String, dynamic> j) => OrderData(orderNo: j['orderNo'].toString(), dateTime: j['dateTime'].toString(), customer: j['customer'].toString(), phone: j['phone'].toString(), address: j['address'].toString(), items: j['items'].toString(), total: int.tryParse(j['total'].toString()) ?? 0, payment: j['payment'].toString());
}

class FnsApp extends StatefulWidget { const FnsApp({super.key}); @override State<FnsApp> createState() => _FnsAppState(); }

class _FnsAppState extends State<FnsApp> {
  static const String whatsappNumber = '923343738405';
  int minOrderLimit = 0;
  List<Product> products = [
    Product(name: 'Hydryllin Syrup 120ml', price: 200, category: 'Syrup'),
    Product(name: 'Pulmonol Syrup 120ml', price: 200, category: 'Syrup'),
    Product(name: 'Lederplex Syrup 150ml', price: 234, category: 'Syrup'),
    Product(name: 'Extor 5/80 Tablet', price: 490, category: 'Tablet'),
    Product(name: 'Risek 40mg Capsule', price: 861, category: 'Tablet'),
  ];
  final Map<Product, int> cart = {};
  final Set<String> favorites = {};
  final List<OrderData> orders = [];
  String searchText = '';
  int bottomIndex = 0;
  bool loading = true;
  String selectedCategory = 'All';
  late ScrollController headlineController;
  Offset fabPosition = const Offset(280, 550);
  static const List<String> categories = ['General', 'Glucometer', 'B.P Operator', 'Stethoscope', 'Surgical', 'Syrup', 'Tablet', 'Other'];

  String detectCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('syrup') || n.contains('syp')) return 'Syrup';
    if (n.contains('tablet') || n.contains('tab') || n.contains('capsule')) return 'Tablet';
    if (n.contains('b.p') || n.contains('bp') || n.contains('operator')) return 'B.P Operator';
    if (n.contains('glucometer') || n.contains('gluco')) return 'Glucometer';
    if (n.contains('stetho')) return 'Stethoscope';
    if (n.contains('surgical') || n.contains('syringe') || n.contains('bandage')) return 'Surgical';
    return 'General';
  }

  Future<void> openWhatsApp({String? message}) async {
    final uri = Uri.parse('https://wa.me/$whatsappNumber${message == null ? '' : '?text=${Uri.encodeComponent(message)}'}');
    try { if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return; } catch (_) {}
  }

  Future<void> printInvoice(OrderData order, {bool isThermal = false}) async {
    final pdf = pw.Document();
    Uint8List? logoBytes;
    try { final data = await rootBundle.load('fns_logo.png'); logoBytes = data.buffer.asUint8List(); } catch (_) {}
    final pageFormat = isThermal ? PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm) : PdfPageFormat.a4;
    pdf.addPage(pw.Page(pageFormat: pageFormat, build: (c) {
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        if (logoBytes != null) pw.Image(pw.MemoryImage(logoBytes), width: 150, height: 100),
        pw.SizedBox(height: 8),
        pw.Text('BABA FALAK NAZ & SONS TRADERS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text('FNS TRADERS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 1),
        pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Order No: ${order.orderNo}'), pw.Text('Date: ${order.dateTime}'), pw.Text('Customer: ${order.customer}'), pw.Text('Phone: ${order.phone}'), pw.Text('Address: ${order.address}'), pw.Divider(),
          pw.Text('ITEMS: ${order.items}'), pw.Divider(),
          pw.Text('TOTAL: Rs. ${order.total}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Payment: ${order.payment}'), pw.SizedBox(height: 10), pw.Center(child: pw.Text('Thank You!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        ])),
      ]);
    }));
    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  @override void initState() { super.initState(); headlineController = ScrollController(); loadSavedData(); WidgetsBinding.instance.addPostFrameCallback((_) => startHeadlineScroll()); }

  void startHeadlineScroll() async {
    await Future.delayed(const Duration(milliseconds: 500));
    while (mounted) {
      if (!headlineController.hasClients) { await Future.delayed(const Duration(milliseconds: 500)); continue; }
      final max = headlineController.position.maxScrollExtent;
      if (max <= 0) { await Future.delayed(const Duration(seconds: 1)); continue; }
      await headlineController.animateTo(max, duration: const Duration(seconds: 25), curve: Curves.linear);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));
      headlineController.jumpTo(0);
    }
  }

  @override void dispose() { headlineController.dispose(); super.dispose(); }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final sp = prefs.getString('products');
    final sf = prefs.getStringList('favorites');
    final so = prefs.getString('orders');
    minOrderLimit = prefs.getInt('minOrderLimit') ?? 0;
    if (sp != null && sp.isNotEmpty) { try { products = (jsonDecode(sp) as List).map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (_) {} }
    if (sf != null) { favorites.clear(); favorites.addAll(sf); }
    if (so != null && so.isNotEmpty) { try { orders.clear(); orders.addAll((jsonDecode(so) as List).map((e) => OrderData.fromJson(Map<String, dynamic>.from(e)))); } catch (_) {} }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveProducts() async { final p = await SharedPreferences.getInstance(); await p.setString('products', jsonEncode(products.map((e) => e.toJson()).toList())); }
  Future<void> saveFavorites() async { final p = await SharedPreferences.getInstance(); await p.setStringList('favorites', favorites.toList()); }
  Future<void> saveOrders() async { final p = await SharedPreferences.getInstance(); await p.setString('orders', jsonEncode(orders.map((e) => e.toJson()).toList())); }
  Future<void> saveMinOrderLimit() async { final p = await SharedPreferences.getInstance(); await p.setInt('minOrderLimit', minOrderLimit); }

  int get cartCount { int c = 0; for (final q in cart.values) c += q; return c; }
  int get cartTotal { int t = 0; for (final e in cart.entries) t += e.key.price * e.value; return t; }

  List<Product> get filteredProducts {
    final q = searchText.toLowerCase().trim();
    return products.where((p) {
      final cat = selectedCategory == 'All' || p.category == selectedCategory;
      final s = q.isEmpty || p.name.toLowerCase().contains(q);
      return cat && s;
    }).toList();
  }

  Widget productImage(Product p, {double size = 70}) {
    if (p.imageBase64.isNotEmpty) {
      try { return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(p.imageBase64), width: size, height: size, fit: BoxFit.cover)); } catch (_) {}
    }
    return Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade200), child: const Icon(Icons.shopping_bag, size: 35));
  }

  void addToCart(Product p) { if (!p.inStock) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of stock'))); return; } setState(() => cart[p] = (cart[p] ?? 0) + 1); }
  void increaseQuantity(Product p) => setState(() => cart[p] = (cart[p] ?? 0) + 1);
  void decreaseQuantity(Product p) { setState(() { final q = cart[p] ?? 0; if (q <= 1) cart.remove(p); else cart[p] = q - 1; }); }
  void toggleFavorite(Product p) { setState(() { if (favorites.contains(p.name)) favorites.remove(p.name); else favorites.add(p.name); }); saveFavorites(); }

  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(children: [
          getCurrentPage(),
          Positioned(left: fabPosition.dx, top: fabPosition.dy, child: GestureDetector(onPanUpdate: (d) { setState(() => fabPosition = Offset(fabPosition.dx + d.delta.dx, fabPosition.dy + d.delta.dy)); }, child: FloatingActionButton(backgroundColor: const Color(0xFF25D366), onPressed: () => openWhatsApp(), child: const Icon(Icons.chat, color: Colors.white, size: 32)))),
        ]),
        bottomNavigationBar: BottomNavigationBar(currentIndex: bottomIndex, type: BottomNavigationBarType.fixed, selectedItemColor: Colors.green[800], onTap: (i) => setState(() => bottomIndex = i), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'), BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'), BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite'), BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'), BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin')]),
      ),
    );
  }

  Widget getCurrentPage() {
    switch (bottomIndex) {
      case 0: return homePage();
      case 1: return cartFullPage();
      case 2: return favFullPage();
      case 3: return aboutFullPage();
      case 4: return adminLoginPage();
      default: return homePage();
    }
  }

  Widget homePage() {
    if (loading) return const Center(child: CircularProgressIndicator());
    final visible = filteredProducts;
    List<Widget> productWidgets = [];
    for (var p in visible) {
      productWidgets.add(Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(contentPadding: const EdgeInsets.all(10), leading: productImage(p, size: 58), title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${p.category}\nRs. ${p.price}'), isThreeLine: true, trailing: Column(children: [IconButton(padding: EdgeInsets.zero, onPressed: () => toggleFavorite(p), icon: Icon(favorites.contains(p.name) ? Icons.favorite : Icons.favorite_border)), IconButton(padding: EdgeInsets.zero, onPressed: p.inStock ? () => addToCart(p) : null, icon: const Icon(Icons.add_shopping_cart))]))));
    }
    return RefreshIndicator(
      onRefresh: loadSavedData,
      child: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 100), children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(10)), child: SingleChildScrollView(controller: headlineController, scrollDirection: Axis.horizontal, child: const Row(children: [SizedBox(width: 10), Text('BABA FALAK NAZ & SONS TRADERS | WELCOME TO FNS TRADERS | ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)), SizedBox(width: 100)]))),
        const SizedBox(height: 10),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(blurRadius: 8, color: Color(0x22000000), offset: Offset(0, 3))]), child: Image.asset('fns_logo.png', width: double.infinity, height: 145, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 80))),
        const SizedBox(height: 10),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), color: Colors.green.shade700, child: const Center(child: Text('مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(hintText: 'Search products...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => searchText = v)),
        const SizedBox(height: 12),
        SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: [catChip('All'), ...categories.map(catChip)])),
        const SizedBox(height: 8),
        Text('${visible.length} product(s)', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (visible.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No products found'))) else Column(children: productWidgets),
      ]),
    );
  }

  Widget catChip(String c) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c), selected: selectedCategory == c, onSelected: (_) => setState(() => selectedCategory = c)));

  Widget cartFullPage() {
    List<Widget> cartWidgets = [];
    for (var e in cart.entries) {
      cartWidgets.add(Card(child: ListTile(leading: productImage(e.key, size: 55), title: Text(e.key.name), subtitle: Text('Rs. ${e.key.price} x ${e.value}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => decreaseQuantity(e.key), icon: const Icon(Icons.remove_circle)), Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(onPressed: () => increaseQuantity(e.key), icon: const Icon(Icons.add_circle))]))));
    }
    return Scaffold(
      appBar: AppBar(title: Text('Cart ($cartCount) - Rs. $cartTotal'), backgroundColor: Colors.green),
      body: Column(children: [
        Expanded(child: cart.isEmpty ? const Center(child: Text('Your cart is empty')) : ListView(padding: const EdgeInsets.all(12), children: cartWidgets)),
        if (cart.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text('Total: Rs. $cartTotal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), if (minOrderLimit > 0 && cartTotal < minOrderLimit) Text('Minimum Order Rs. $minOrderLimit Required', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), const SizedBox(height: 10), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (minOrderLimit > 0 && cartTotal < minOrderLimit) ? null : () => showCheckoutSheet(), child: const Text('Checkout')))])),
      ]),
    );
  }

  Widget favFullPage() => Scaffold(appBar: AppBar(title: const Text('Favorites'), backgroundColor: Colors.green), body: favorites.isEmpty ? const Center(child: Text('No favorites')) : ListView(children: products.where((p) => favorites.contains(p.name)).map((p) => ListTile(leading: productImage(p), title: Text(p.name), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => toggleFavorite(p)))).toList()));
  Widget aboutFullPage() => Scaffold(appBar: AppBar(title: const Text('About'), backgroundColor: Colors.green), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset('fns_logo.png', height: 120, errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 80)), const SizedBox(height: 12), const Text('مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Text('BABA FALAK NAZ & SONS TRADERS', style: TextStyle(fontWeight: FontWeight.bold)), const Text('FNS TRADERS')])));

  Widget adminLoginPage() {
    final ctrl = TextEditingController();
    return Scaffold(appBar: AppBar(title: const Text('Admin Login'), backgroundColor: Colors.green), body: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password (1234)', border: OutlineInputBorder())), const SizedBox(height: 15), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { if (ctrl.text == '1234') { Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanelFull(products: products, orders: orders, onUpdate: (l) { setState(() => products = l); saveProducts(); }, onPrint: printInvoice, minLimit: minOrderLimit, onLimitChange: (v) { setState(() => minOrderLimit = v); saveMinOrderLimit(); }, detectCategory: detectCategory))); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong Password'))); } }, child: const Text('Login')))])));
  }

  void showCheckoutSheet() {
    final nameC = TextEditingController(); final phoneC = TextEditingController(); final addrC = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 15, right: 15, top: 15), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Customer Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')), TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone')), TextField(controller: addrC, decoration: const InputDecoration(labelText: 'Address')), const SizedBox(height: 15), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { final orderNo = 'FNS-${DateTime.now().millisecondsSinceEpoch}'; final itemsStr = cart.entries.map((e) => '${e.key.name} x${e.value}').join(', '); final order = OrderData(orderNo: orderNo, dateTime: DateTime.now().toString().substring(0, 16), customer: nameC.text, phone: phoneC.text, address: addrC.text, items: itemsStr, total: cartTotal, payment: 'Cash'); orders.add(order); await saveOrders(); await printInvoice(order, isThermal: false); openWhatsApp(message: 'New Order $orderNo\nCustomer: ${nameC.text}\nPhone: ${phoneC.text}\nAddress: ${addrC.text}\nItems: $itemsStr\nTotal: Rs. $cartTotal'); setState(() => cart.clear()); Navigator.pop(ctx); }, child: const Text('Confirm & Print PDF'))), const SizedBox(height: 15)])));
  }
}

class AdminPanelFull extends StatefulWidget {
  final List<Product> products; final List<OrderData> orders; final Function(List<Product>) onUpdate; final Function(OrderData, {bool isThermal}) onPrint; final int minLimit; final Function(int) onLimitChange; final String Function(String) detectCategory;
  const AdminPanelFull({super.key, required this.products, required this.orders, required this.onUpdate, required this.onPrint, required this.minLimit, required this.onLimitChange, required this.detectCategory});
  @override State<AdminPanelFull> createState() => _AdminPanelFullState();
}

class _AdminPanelFullState extends State<AdminPanelFull> {
  final _name = TextEditingController(); final _price = TextEditingController(); final _cat = TextEditingController(); final _limitCustom = TextEditingController(); String _img = ''; final picker = ImagePicker();
  @override void initState() { super.initState(); _limitCustom.text = widget.minLimit.toString(); }
  Future<void> pickImage() async { final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); if (x != null) { final b = await x.readAsBytes(); setState(() => _img = base64Encode(b)); } }
  void showPrintOptions(OrderData order) { showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Print Bill'), content: const Text('کون سا پرنٹ نکالنا ہے؟'), actions: [TextButton(onPressed: () { Navigator.pop(context); widget.onPrint(order, isThermal: false); }, child: const Text('A4 Size')), TextButton(onPressed: () { Navigator.pop(context); widget.onPrint(order, isThermal: true); }, child: const Text('Thermal 80mm'))])); }
  @override Widget build(BuildContext context) {
    List<Widget> stockWidgets = [];
    for (var p in widget.products) {
      stockWidgets.add(Card(child: ListTile(leading: p.imageBase64.isNotEmpty ? Image.memory(base64Decode(p.imageBase64), width: 40, height: 40, errorBuilder: (a, b, c) => const Icon(Icons.image)) : const Icon(Icons.medication), title: Text(p.name), subtitle: Text('Rs. ${p.price} - ${p.category}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Switch(value: p.inStock, onChanged: (v) { setState(() => p.inStock = v); widget.onUpdate(widget.products); }), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { final list = List<Product>.from(widget.products)..remove(p); widget.onUpdate(list); })]))));
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin Panel'), backgroundColor: Colors.green, bottom: const TabBar(tabs: [Tab(text: 'Stock'), Tab(text: 'Orders')])),
        body: TabBarView(children: [
          SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add Stock with Picture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()), onChanged: (v) { setState(() => _cat.text = widget.detectCategory(v)); }),
            const SizedBox(height: 8),
            TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: _cat, decoration: const InputDecoration(labelText: 'Category (Auto Detect)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(children: [ElevatedButton(onPressed: pickImage, child: const Text('Pick Photo')), const SizedBox(width: 10), if (_img.isNotEmpty) Image.memory(base64Decode(_img), width: 60, height: 60)]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { if (_name.text.isEmpty) return; final finalCat = _cat.text.isEmpty ? widget.detectCategory(_name.text) : _cat.text; final p = Product(name: _name.text, price: int.tryParse(_price.text) ?? 0, category: finalCat, imageBase64: _img); final list = List<Product>.from(widget.products)..add(p); widget.onUpdate(list); _name.clear(); _price.clear(); _cat.clear(); setState(() => _img = ''); }, child: const Text('Add Stock'))),
            const Divider(height: 30),
            const Text('MINIMUM ORDER LIMIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            const SizedBox(height: 8),
            Text('Current Limit: Rs. ${widget.minLimit}'),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: TextField(controller: _limitCustom, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Limit لکھیں مثلا 1000', border: OutlineInputBorder()))), const SizedBox(width: 8), ElevatedButton(onPressed: () { final v = int.tryParse(_limitCustom.text) ?? 0; widget.onLimitChange(v); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Limit Rs. $v Save ہو گیا'))); }, child: const Text('Save'))]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [0, 500, 1000, 1500, 2000, 5000, 10000, 20000].map((v) => ChoiceChip(label: Text(v == 0 ? 'No Limit' : 'Rs. $v'), selected: widget.minLimit == v, onSelected: (_) { widget.onLimitChange(v); _limitCustom.text = v.toString(); setState(() {}); })).toList()),
            const Divider(height: 30),
            const Text('Stock ON/OFF & Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            Column(children: stockWidgets),
          ])),
          widget.orders.isEmpty ? const Center(child: Text('کوئی آرڈر نہیں')) : ListView.builder(itemCount: widget.orders.length, itemBuilder: (c, i) { final o = widget.orders[widget.orders.length - 1 - i]; return Card(margin: const EdgeInsets.all(8), child: ListTile(title: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${o.customer} - ${o.phone}\n${o.items}\nRs. ${o.total}'), isThreeLine: true, trailing: IconButton(icon: const Icon(Icons.print, color: Colors.green), onPressed: () => showPrintOptions(o)))); }),
        ]),
      ),
    );
  }
}
