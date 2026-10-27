import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  final cart = <String, Map<String, dynamic>>{};
  final customer = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final discount = TextEditingController(text: '0');
  bool busy = false;

  @override void dispose() {
    customer.dispose(); phone.dispose(); address.dispose(); discount.dispose(); super.dispose();
  }

  Widget header() => Column(children: [
    Container(width: double.infinity, color: const Color(0xFF0D47A1), padding: const EdgeInsets.all(8),
      child: const Text("BABA FALAK NAZ & SONS TRADERS | FNS TRADERS", textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    Container(width: double.infinity, color: Colors.green.shade700, padding: const EdgeInsets.all(8),
      child: const Text("مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ", textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    const Padding(padding: EdgeInsets.all(10), child: Row(children: [
      Text('FNS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      SizedBox(width: 12), Expanded(child: Text("BABA FALAK NAZ & SONS TRADERS\nPlot No. A-46, Sector 8/A, Bilal Colony, K.I.A Karachi\n0334-3738405",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
    ])),
  ]);

  Future<void> productForm({String? id, Map<String,dynamic>? data}) async {
    final name = TextEditingController(text: data?['name']?.toString() ?? '');
    final price = TextEditingController(text: data?['price']?.toString() ?? '');
    final stock = TextEditingController(text: data?['stock']?.toString() ?? '0');
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
            final payload = {'name':name.text.trim(),'price':p,'stock':s,'imageUrl':imageUrl ?? '', 'updatedAt':FieldValue.serverTimestamp()};
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
      final doc = pw.Document();
      doc.addPage(pw.Page(pageFormat: thermal ? const PdfPageFormat(80*PdfPageFormat.mm, 250*PdfPageFormat.mm, marginAll: 5) : PdfPageFormat.a4,
        build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Center(child: pw.Text('FNS TRADERS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
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
                  subtitle: Text('Retail: Rs. ${p['price'] ?? 0} | Stock: ${p['stock'] ?? 0}'),
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

  Widget backupTab()=>Center(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.cloud_done,size:60,color:Colors.green),
    const Text('Firebase cloud records',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    const Text('Products, customers aur invoices Firebase mein save honge. Manual backup JSON text ke taur par share kar sakte hain.'),
    const SizedBox(height:16),FilledButton.icon(onPressed:busy?null:backup,icon:const Icon(Icons.share),label:Text(busy?'Please wait...':'Export backup')),
    TextButton(onPressed:()=>FirebaseAuth.instance.signOut(),child:const Text('Log out')),
  ])));

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFFF5F5F5),
    body:SafeArea(child:Column(children:[
      header(),
      Expanded(child:IndexedStack(index:tab,children:[productsTab(),billingTab(),backupTab()])),
    ])),
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
      NavigationDestination(icon:Icon(Icons.inventory_2),label:'Products'),
      NavigationDestination(icon:Icon(Icons.receipt_long),label:'Billing'),
      NavigationDestination(icon:Icon(Icons.backup),label:'Backup'),
    ]),
  );
}
