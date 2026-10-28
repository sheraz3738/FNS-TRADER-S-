import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
  String search = '';
  static const List<String> productCategories = ['Medicines','Syrups','Tablets/Capsules','Syringes','Surgical Items','BP & Sugar','General Items','Medical Equipment','Other Items'];
  final ScrollController welcomeController = ScrollController();
  Timer? welcomeTimer;

  @override
  void initState() {
    super.initState();
    welcomeTimer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (!welcomeController.hasClients) return;
      final max = welcomeController.position.maxScrollExtent;
      if (max <= 0) return;
      if (welcomeController.offset >= max) {
        welcomeController.jumpTo(0);
      } else {
        welcomeController.jumpTo(welcomeController.offset + 1);
      }
    });
  }

  final cart = <String, Map<String, dynamic>>{};
  final customer = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final discount = TextEditingController(text: '0');
  bool busy = false;

  @override void dispose() {
    welcomeTimer?.cancel();
    welcomeController.dispose();
    customer.dispose(); phone.dispose(); address.dispose(); discount.dispose(); super.dispose();
  }

  Widget header() => Column(children: [
    Container(height:44,width:double.infinity,color:Colors.blue.shade800,
      child:ListView(controller:welcomeController,scrollDirection:Axis.horizontal,physics:const NeverScrollableScrollPhysics(),children:const [
        Center(child:Padding(padding:EdgeInsets.symmetric(horizontal:16),child:Text(
          'BABA FALAK NAZ & SONS TRADERS  |  WELCOME TO FNS TRADERS  |  بابا فلک ناز رحمۃ اللّٰہ علیہ اینڈ سنز ٹریڈرز',
          style:TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))))
      ])),
    Container(width:double.infinity,color:Colors.green.shade700,padding:const EdgeInsets.all(8),
      child:const Text('مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ',textAlign:TextAlign.center,
        style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold))),
    Card(margin:const EdgeInsets.all(10),elevation:4,clipBehavior:Clip.antiAlias,
      child:SizedBox(width:double.infinity,height:180,child:Padding(padding:const EdgeInsets.all(6),
        child:Image.asset('fns_logo.png',fit:BoxFit.contain,
          errorBuilder:(context,error,stackTrace)=>const Center(child:Text('FNS TRADERS',
            style:TextStyle(fontSize:34,fontWeight:FontWeight.bold,color:Colors.blue))))))),
  ]);

  Future<void> productForm({String? id, Map<String,dynamic>? data}) async {
    final name = TextEditingController(text: data?['name']?.toString() ?? '');
    final price = TextEditingController(text: data?['price']?.toString() ?? '');
    final stock = TextEditingController(text: data?['stock']?.toString() ?? '0');
    String category = productCategories.contains(data?['category']) ? data!['category'].toString() : 'Other Items';
    String? imageUrl = data?['imageUrl']?.toString();
    Uint8List? bytes;
    bool saving = false;
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: Text(id == null ? 'Add product' : 'Edit product'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (bytes != null) Image.memory(bytes!, height: 100) else if (imageUrl != null && imageUrl!.isNotEmpty)
          Image.network(imageUrl!, height: 100, errorBuilder: (_,__,___)=>const Icon(Icons.image_not_supported,size:60))
          else const Icon(Icons.inventory_2, size: 55),
        TextButton.icon(onPressed: saving ? null : () async {
          final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1200);
          if (x != null) { bytes = await x.readAsBytes(); setD(() {}); }
        }, icon: const Icon(Icons.photo_library), label: const Text('Choose picture from gallery')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Product name')),
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(labelText: 'Product category'),
          items: productCategories.map((value) => DropdownMenuItem(
            value: value, child: Text(value),
          )).toList(),
          onChanged: saving ? null : (value) {
            if (value != null) setD(() => category = value);
          },
        ),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Retail price (Rs.)')),
        TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock quantity')),
      ])),
      actions: [
        TextButton(onPressed: saving ? null : ()=>Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: saving ? null : () async {
          final p = int.tryParse(price.text.trim()); final s = int.tryParse(stock.text.trim());
          if (name.text.trim().isEmpty || p == null || s == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, valid price aur stock likhein.'))); return;
          }
          setD(()=>saving=true);
          try {
            if (bytes != null) {
              final ref = FirebaseStorage.instance.ref('products/${DateTime.now().millisecondsSinceEpoch}_${name.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.jpg');
              await ref.putData(bytes!, SettableMetadata(contentType: 'image/jpeg'));
              imageUrl = await ref.getDownloadURL();
            }
            final payload = {'name':name.text.trim(),'category':category,'price':p,'stock':s,'imageUrl':imageUrl ?? '', 'updatedAt':FieldValue.serverTimestamp()};
            if (id == null) { payload['createdAt'] = FieldValue.serverTimestamp(); await FirebaseFirestore.instance.collection('products').add(payload); }
            else { await FirebaseFirestore.instance.collection('products').doc(id).update(payload); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch(e) {
            setD(()=>saving=false);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save nahi hua: $e. Firebase Storage enable/check karein.')));
          }
        }, child: saving ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Save')),
      ],
    )));
    name.dispose(); price.dispose(); stock.dispose();
  }

  int get subtotal => cart.values.fold(0, (n,p)=>n+(p['price'] as int)*(p['qty'] as int));
  int get finalTotal => (subtotal - (int.tryParse(discount.text) ?? 0)).clamp(0, 1<<31);

  Future<void> checkout(bool thermal) async {
    if (cart.isEmpty) return;
    setState(()=>busy=true);
    final now = DateTime.now();
    final invNo = 'FNS-${now.millisecondsSinceEpoch}';
    final items = cart.entries.map((e)=>{'productId':e.key,'name':e.value['name'],'price':e.value['price'],'qty':e.value['qty'],'amount':(e.value['price'] as int)*(e.value['qty'] as int)}).toList();
    try {
      await FirebaseFirestore.instance.collection('invoices').add({
        'invoiceNo':invNo,'customerName':customer.text.trim(),'phone':phone.text.trim(),'address':address.text.trim(),
        'items':items,'subtotal':subtotal,'discount':int.tryParse(discount.text) ?? 0,'total':finalTotal,
        'createdAt':FieldValue.serverTimestamp(),
      });
      Uint8List? logoBytes;
      try { logoBytes = (await rootBundle.load('fns_logo.png')).buffer.asUint8List(); } catch (_) {}
      final doc = pw.Document();
      doc.addPage(pw.Page(pageFormat: thermal ? const PdfPageFormat(80*PdfPageFormat.mm, 250*PdfPageFormat.mm, marginAll: 5) : PdfPageFormat.a4,
        build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (logoBytes != null) pw.Center(child: pw.Image(pw.MemoryImage(logoBytes), height: 65, fit: pw.BoxFit.contain)) else pw.Center(child: pw.Text('FNS TRADERS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.Center(child: pw.Text('BABA FALAK NAZ & SONS TRADERS')),
          pw.Text('Plot No. A-46, Sector 8/A, Bilal Colony, K.I.A Karachi'),
          pw.Text('Phone: 0334-3738405'),
          pw.Divider(), pw.Text('Invoice: $invNo'), pw.Text('Date: ${now.toString().substring(0,16)}'),
          pw.Text('Customer: ${customer.text}'), pw.Text('Phone: ${phone.text}'), pw.Text('Address: ${address.text}'), pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(headers:['S.No','Product','Qty','Rate','Amount'], data:[for(int i=0;i<items.length;i++) [ '${i+1}',items[i]['name'].toString(),items[i]['qty'].toString(),'Rs. ${items[i]['price']}','Rs. ${items[i]['amount']}']]),
          pw.SizedBox(height:8), pw.Align(alignment:pw.Alignment.centerRight,child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.end,children:[
            pw.Text('Subtotal: Rs. $subtotal'), pw.Text('Discount: Rs. ${int.tryParse(discount.text) ?? 0}'),
            pw.Text('TOTAL: Rs. $finalTotal',style:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:16)),
          ])), pw.SizedBox(height:15), pw.Center(child:pw.Text('Thank you for your business')),
        ])));
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
      if (mounted) setState(()=>cart.clear());
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Invoice/print error: $e')));
    } finally { if (mounted) setState(()=>busy=false); }
  }

  Future<void> backup() async {
    setState(()=>busy=true);
    try {
      final customersSnap=await FirebaseFirestore.instance.collection('customers').get();
      final invoicesSnap=await FirebaseFirestore.instance.collection('invoices').get();
      final productsSnap=await FirebaseFirestore.instance.collection('products').get();
      final data=jsonEncode({
        'exportedAt':DateTime.now().toIso8601String(),
        'customers':customersSnap.docs.map((d)=>{'id':d.id,...d.data()}).toList(),
        'products':productsSnap.docs.map((d)=>{'id':d.id,...d.data()}).toList(),
        'invoices':invoicesSnap.docs.map((d)=>{'id':d.id,...d.data()}).toList(),
      }, toEncodable:(o)=>o is Timestamp ? o.toDate().toIso8601String() : o.toString());
      await Share.share(data, subject:'FNS TRADERS backup JSON');
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Backup error: $e')));
    } finally { if(mounted) setState(()=>busy=false); }
  }

  Widget productsTab() => Column(children: [
    Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        onChanged: (v) => setState(() => search = v),
        decoration: const InputDecoration(
          hintText: 'Search product...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
    ),
    Expanded(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Products load error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.where((d) =>
            (d.data()['name'] ?? '').toString().toLowerCase().contains(search.toLowerCase())).toList();
          if (docs.isEmpty) return const Center(child: Text('Abhi products nahi hain. + button se add karein.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i];
              final p = d.data();
              final url = (p['imageUrl'] ?? '').toString();
              return Card(
                child: ListTile(
                  leading: url.isEmpty
                    ? const CircleAvatar(child: Icon(Icons.inventory_2))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, width: 55, height: 55, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                      ),
                  title: Text((p['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${p['category'] ?? 'Other Items'} | Retail: Rs. ${p['price'] ?? 0} | Stock: ${p['stock'] ?? 0}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: 'Add to bill',
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                      onPressed: () => setState(() => cart.update(
                        d.id,
                        (v) => {...v, 'qty': (v['qty'] as int) + 1},
                        ifAbsent: () => {'name': p['name'] ?? '', 'price': (p['price'] as num?)?.toInt() ?? 0, 'qty': 1},
                      )),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => productForm(id: d.id, data: p),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    ),
  ]);

  Widget field(TextEditingController c,String label,{TextInputType? type})=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,keyboardType:type,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  Widget billingTab()=>ListView(padding:const EdgeInsets.all(12),children:[
    const Text('NEW BILL / INVOICE',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
    field(customer,'Customer name'),field(phone,'Phone',type:TextInputType.phone),field(address,'Address'),
    const Divider(),if(cart.isEmpty)const Text('Products tab se cart mein items add karein.'),
    ...cart.entries.map((e)=>Card(child:ListTile(title:Text(e.value['name'].toString()),subtitle:Text('Rs. ${e.value['price']} × ${e.value['qty']} = Rs. ${(e.value['price'] as int)*(e.value['qty'] as int)}'),
      trailing:Row(mainAxisSize:MainAxisSize.min,children:[
        IconButton(onPressed:()=>setState(()=>e.value['qty']=(e.value['qty'] as int)>1?(e.value['qty'] as int)-1:1),icon:const Icon(Icons.remove_circle_outline)),
        IconButton(onPressed:()=>setState(()=>e.value['qty']=(e.value['qty'] as int)+1),icon:const Icon(Icons.add_circle_outline)),
        IconButton(onPressed:()=>setState(()=>cart.remove(e.key)),icon:const Icon(Icons.delete_outline,color:Colors.red)),
      ])))),
    field(discount,'Discount (Rs.)',type:TextInputType.number),
    Text('Subtotal: Rs. $subtotal',style:const TextStyle(fontSize:16)),
    Text('Final Total: Rs. $finalTotal',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:()=>checkout(false),icon:const Icon(Icons.print),label:Text(busy?'Please wait...':'Save & Print A4')),
    OutlinedButton.icon(onPressed:busy?null:()=>checkout(true),icon:const Icon(Icons.receipt_long),label:const Text('Save & Print Thermal 80mm')),
  ]);

  Future<void> printCustomerOrder({
    required String orderId,
    required Map<String, dynamic> order,
    required Map<String, dynamic> customerData,
  }) async {
    final items = (order['items'] as List?) ?? [];
    final now = DateTime.now();
    Uint8List? logoBytes;
    try { logoBytes = (await rootBundle.load('fns_logo.png')).buffer.asUint8List(); } catch (_) {}
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logoBytes != null) pw.Center(child: pw.Image(pw.MemoryImage(logoBytes), height: 75, fit: pw.BoxFit.contain)) else pw.Center(child: pw.Text('FNS TRADERS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
          pw.Center(child: pw.Text('BABA FALAK NAZ & SONS TRADERS')),
          pw.Center(child: pw.Text('Plot No. A-46, Sector 8/A, Bilal Colony, K.I.A Karachi')),
          pw.Center(child: pw.Text('Phone: 0334-3738405')),
          pw.Divider(),
          pw.Text('ORDER BILL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Order No: $orderId'),
          pw.Text('Date: ${now.toString().substring(0, 16)}'),
          pw.Text('Customer / Shop: ${customerData['shopName'] ?? 'Customer'}'),
          pw.Text('Mobile: ${customerData['contact'] ?? ''}'),
          pw.Text('Address: ${customerData['address'] ?? ''}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['S.No', 'Product', 'Qty', 'Rate', 'Amount'],
            data: [
              for (int i = 0; i < items.length; i++)
                () {
                  final m = Map<String, dynamic>.from(items[i] as Map);
                  final qty = (m['quantity'] ?? m['qty'] ?? 0) as num;
                  final price = (m['price'] ?? m['rate'] ?? 0) as num;
                  final amount = (m['amount'] ?? (qty * price)) as num;
                  return ['${i + 1}', '${m['name'] ?? 'Product'}', '${qty}', 'Rs. ${price}', 'Rs. ${amount}'];
                }(),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('TOTAL: Rs. ${order['total'] ?? 0}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 24),
          pw.Center(child: pw.Text('Please check product expiry dates at the time of delivery.', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9))),
          pw.Center(child: pw.Text('Please keep this bill for your records and any expiry-related claim.', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9))),
          pw.SizedBox(height: 5),
          pw.Center(child: pw.Text('We Believe in Truth in Business', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
          pw.Center(child: pw.Text('Thank you for your order!', textAlign: pw.TextAlign.center)),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Widget ordersTab() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(child: Text('Orders load nahi huay. Firestore Rules check karein.'));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) {
        return const Center(child: Text('Abhi koi customer order nahi hai.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data();
          final items = (data['items'] as List?) ?? [];
          final itemLines = items.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            return '${m['name'] ?? 'Product'} × ${m['quantity'] ?? m['qty'] ?? 0}';
          }).join('\n');
          final customerId = (data['customerId'] ?? '').toString();
          final status = (data['status'] ?? 'Pending').toString();
          return Card(
            child: ListTile(
              onTap: () async {
                Map<String, dynamic> customerData = {};
                if (customerId.isNotEmpty) {
                  try {
                    final profile = await FirebaseFirestore.instance.collection('customers').doc(customerId).get();
                    customerData = profile.data() ?? {};
                  } catch (_) {}
                }
                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) => StatefulBuilder(
                    builder: (dialogContext, setDialogState) => AlertDialog(
                      title: Text('Order ${doc.id}'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer / Shop: ${customerData['shopName'] ?? data['customerName'] ?? 'Customer'}'),
                            Text('Mobile: ${customerData['contact'] ?? data['customerPhone'] ?? ''}'),
                            Text('Address: ${customerData['address'] ?? data['customerAddress'] ?? ''}'),
                            const SizedBox(height: 8),
                            Text('Status: ${data['status'] ?? 'Pending'}'),
                            Text('Total: Rs. ${data['total'] ?? 0}'),
                            const SizedBox(height: 12),
                            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(itemLines.isEmpty ? 'No item details found' : itemLines),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await printCustomerOrder(orderId: doc.id, order: data, customerData: customerData);
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print error: $e')));
                            }
                          },
                          icon: const Icon(Icons.print),
                          label: const Text('Print Bill'),
                        ),
                        FilledButton.icon(
                          onPressed: (data['status'] ?? 'Pending') == 'Confirmed' ? null : () async {
                            try {
                              await doc.reference.update({'status': 'Confirmed', 'confirmedAt': FieldValue.serverTimestamp()});
                              data['status'] = 'Confirmed';
                              setDialogState(() {});
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Confirmed')));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Confirm nahi hua: $e')));
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirm Order'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              leading: Icon(status == 'Confirmed' ? Icons.check_circle : Icons.shopping_bag, color: status == 'Confirmed' ? Colors.green : Colors.orange),
              title: Text('Order ${doc.id}'),
              subtitle: Text(
                '${data['customerName'] ?? data['customerEmail'] ?? 'Customer'}\n'
                '$status\n'
                '$itemLines',
              ),
              isThreeLine: true,
              trailing: Text('Rs. ${data['total'] ?? 0}'),
            ),
          );
        },
      );
    },
  );

  Widget backupTab()=>Center(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.cloud_done,size:60,color:Colors.green),
    const Text('Firebase cloud records',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    const Text('Products, customers aur invoices Firebase mein save honge. Manual backup JSON text ke taur par share kar sakte hain.'),
    const SizedBox(height:16),FilledButton.icon(onPressed:busy?null:backup,icon:const Icon(Icons.share),label:Text(busy?'Please wait...':'Export backup')),
    TextButton(onPressed:()=>FirebaseAuth.instance.signOut(),child:const Text('Log out')),
  ])));

  Widget settingsTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    const ListTile(leading:Icon(Icons.store,color:Colors.blue),title:Text('FNS TRADERS'),subtitle:Text('Admin settings')),
    const ListTile(leading:Icon(Icons.location_on,color:Colors.blue),title:Text('Business address'),subtitle:Text('Plot No. A-46, Sector 8/A, Bilal Colony, K.I.A Karachi')),
    const ListTile(leading:Icon(Icons.phone,color:Colors.green),title:Text('Contact'),subtitle:Text('0334-3738405')),
    const ListTile(leading:Icon(Icons.image,color:Colors.blue),title:Text('Product details'),subtitle:Text('Add Product mein name, retail price, stock aur gallery picture set karein.')),
    FilledButton.icon(onPressed:()=>FirebaseAuth.instance.signOut(),icon:const Icon(Icons.logout),label:const Text('Log out')),
  ]);

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFFF5F5F5),
    body:SafeArea(child:Column(children:[
      header(),
      Expanded(child:IndexedStack(index:tab,children:[productsTab(),billingTab(),ordersTab(),backupTab(),settingsTab()])),
    ])),
    floatingActionButton: tab == 0
      ? FloatingActionButton.extended(
          onPressed: () => productForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
        )
      : null,
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
      NavigationDestination(icon:Icon(Icons.inventory_2),label:'Products'),
      NavigationDestination(icon:Icon(Icons.receipt_long),label:'Billing'),
      NavigationDestination(icon:Icon(Icons.shopping_bag),label:'Orders'),
      NavigationDestination(icon:Icon(Icons.backup),label:'Backup'),
      NavigationDestination(icon:Icon(Icons.settings),label:'Settings'),
    ]),
  );
}
