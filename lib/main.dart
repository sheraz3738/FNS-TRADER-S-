import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const FnsApp());

class Product {
  String name; int price; bool inStock; String imageBase64; String category;
  Product({required this.name, required this.price, this.inStock=true, this.imageBase64='', this.category='General'});
  Map<String, dynamic> toJson() => {'name':name,'price':price,'inStock':inStock,'imageBase64':imageBase64,'category':category};
  factory Product.fromJson(Map<String,dynamic> j) => Product(name:j['name']??'', price:int.tryParse(j['price'].toString())??0, inStock:j['inStock']??true, imageBase64:j['imageBase64']??'', category:j['category']??'General');
}

class FnsApp extends StatefulWidget { const FnsApp({super.key}); @override State<FnsApp> createState()=>_FnsAppState(); }

class _FnsAppState extends State<FnsApp> {
  static const String whatsappNumber = '923343738405';
  static const String shopAddress = 'Plot No, L34 Street No, 02 Sector 8/D K.I.A Karachi';
  static const String shopMobile = '0334-3738405';
  List<Product> products = [];
  final Map<int,int> cart = {};
  final Set<int> fav = {};
  String search=''; String cat='All'; int bottomIndex=0;
  int minOrder = 1000;
  bool _isAdmin=false;
  final ScrollController headlineController = ScrollController();
  final List<String> categories = ['All','General','Glucometer','B.P Operator','Stethoscope','Surgical','Syrup','Tablet','Other'];

  String getCurrentDateTime() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2,'0');
    final date = "${two(now.day)}-${two(now.month)}-${now.year}";
    final h = now.hour > 12? now.hour - 12 : now.hour == 0? 12 : now.hour;
    final ampm = now.hour >= 12? 'PM' : 'AM';
    return "$date - ${two(h)}:${two(now.minute)}:$am2 - $am2".replaceAll("am2", ampm);
  }
  // Sahi DateTime Function
  String getDT(){
    final now = DateTime.now();
    String two(int n)=>n.toString().padLeft(2,'0');
    final d="${two(now.day)}-${two(now.month)}-${now.year}";
    int hh=now.hour; String ap=hh>=12?'PM':'AM'; if(hh>12) hh-=12; if(hh==0) hh=12;
    return "$d - ${two(hh)}:${two(now.minute)} $ap";
  }
  String generateInvoiceNo(){
    final now=DateTime.now();
    return "INV-${now.year}${now.month}${now.day}-${now.hour}${now.minute}${now.second}";
  }

  @override void initState(){ super.initState(); _loadData(); WidgetsBinding.instance.addPostFrameCallback((_)=>_autoScroll()); }
  Future<void> _autoScroll() async { while(mounted){ await Future.delayed(const Duration(seconds:1)); if(!headlineController.hasClients) continue; final max=headlineController.position.maxScrollExtent; if(max<=0) continue; await headlineController.animateTo(max, duration: const Duration(seconds:25), curve:Curves.linear); await Future.delayed(const Duration(milliseconds:600)); headlineController.jumpTo(0);} }
  Future<void> _loadData() async {
    final sp=await SharedPreferences.getInstance();
    final s=sp.getString('products_v2');
    if(s!=null){ products=(jsonDecode(s) as List).map((e)=>Product.fromJson(e)).toList(); }
    else{ products=[Product(name:'Hydryllin Syrup 120ml',price:200,category:'Syrup'), Product(name:'Pulmonol Syrup 120ml',price:200,category:'Syrup'), Product(name:'Glucometer',price:2500,category:'Glucometer'), Product(name:'Panadol Tablet',price:50,category:'Tablet')]; }
    minOrder=sp.getInt('minOrder')??1000; setState((){});
  }
  Future<void> _save() async { final sp=await SharedPreferences.getInstance(); sp.setString('products_v2', jsonEncode(products.map((e)=>e.toJson()).toList())); sp.setInt('minOrder', minOrder); }
  Future<void> _openWhatsApp({String? message}) async {
    final msg=Uri.encodeComponent(message??'Assalam-o-Alaikum FNS Traders');
    await launchUrl(Uri.parse('https://wa.me/$whatsappNumber?text=$msg'), mode:LaunchMode.externalApplication);
  }

  // ===== DIRECT PRINT FUNCTIONS =====
  Future<void> printA4Bill(int total) async {
    final pdf=pw.Document();
    pdf.addPage(pw.Page(pageFormat:PdfPageFormat.a4, build:(c){
      return pw.Container(padding:const pw.EdgeInsets.all(14), decoration:pw.BoxDecoration(border:pw.Border.all(width:1.5)), child:pw.Column(children:[
        pw.Text('BABA FALAK NAZ & SONS TRADERS', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:18)),
        pw.Divider(thickness:2),
        pw.Text('Address: $shopAddress', style:const pw.TextStyle(fontSize:11)),
        pw.Text('Mobile / WhatsApp: $shopMobile', style:const pw.TextStyle(fontSize:11)),
        pw.Divider(),
        pw.Align(alignment:pw.Alignment.centerLeft, child:pw.Text('Invoice No: ${generateInvoiceNo()}', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:11))),
        pw.Align(alignment:pw.Alignment.centerLeft, child:pw.Text('Date/Time: ${getDT()}', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:11))),
        pw.SizedBox(height:8),
       ...cart.entries.map((e)=>pw.Padding(padding:const pw.EdgeInsets.symmetric(vertical:2), child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween, children:[pw.Expanded(child:pw.Text('${products[e.key].name} x${e.value}', style:const pw.TextStyle(fontSize:10))), pw.Text('Rs.${products[e.key].price*e.value}', style:const pw.TextStyle(fontSize:10))]))),
        pw.Divider(), pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween, children:[pw.Text('TOTAL:', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:13)), pw.Text('Rs.$total', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:13))]),
        pw.Divider(), pw.Align(alignment:pw.Alignment.centerLeft, child:pw.Text('Note:', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:10))),
        pw.Align(alignment:pw.Alignment.centerLeft, child:pw.Text('* Goods once sold will not be taken back or exchanged.\n* Expiry items will not be returned.\n* Please check your bill and goods before leaving.', style:const pw.TextStyle(fontSize:9))),
        pw.SizedBox(height:8), pw.Container(width:double.infinity, color:PdfColors.black, padding:const pw.EdgeInsets.all(6), child:pw.Center(child:pw.Text('THANK YOU - VISIT AGAIN', style:pw.TextStyle(color:PdfColors.white, fontWeight:pw.FontWeight.bold, fontSize:12)))),
      ]));
    }));
    await Printing.layoutPdf(onLayout:(f) async => pdf.save());
  }
  Future<void> printThermalBill(int total) async {
    final pdf=pw.Document();
    pdf.addPage(pw.Page(pageFormat:const PdfPageFormat(80*PdfPageFormat.mm, double.infinity), build:(c){
      return pw.Column(children:[
        pw.Text('BABA FALAK NAZ & SONS', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:11)), pw.Text('TRADERS', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:11)),
        pw.Text('Address: $shopAddress', textAlign:pw.TextAlign.center, style:const pw.TextStyle(fontSize:7)), pw.Text('M/W: $shopMobile', style:const pw.TextStyle(fontSize:7)), pw.Divider(thickness:1),
        pw.Align(alignment:pw.Alignment.centerLeft, child:pw.Text('Inv: ${generateInvoiceNo()}', style:const pw.TextStyle(fontSize:7))), pw.Align(alignment:pw.Alignment.centerLeft, child:pw.Text('DT: ${getDT()}', style:const pw.TextStyle(fontSize:7))), pw.Divider(),
       ...cart.entries.map((e)=>pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween, children:[pw.Expanded(child:pw.Text('${products[e.key].name} x${e.value}', style:const pw.TextStyle(fontSize:7))), pw.Text('Rs.${products[e.key].price*e.value}', style:const pw.TextStyle(fontSize:7))])),
        pw.Divider(), pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween, children:[pw.Text('TOTAL Rs.$total', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:9))]), pw.SizedBox(height:6), pw.Text('Thank You - Visit Again', style:pw.TextStyle(fontWeight:pw.FontWeight.bold, fontSize:9)),
      ]);
    }));
    await Printing.layoutPdf(onLayout:(f) async => pdf.save());
  }

  @override Widget build(BuildContext context){
    return MaterialApp(debugShowCheckedModeBanner:false, home:Scaffold(
      body:SafeArea(child:Column(children:[
        Container(height:34, color:const Color(0xFF1E4DB7), alignment:Alignment.centerLeft, child:SingleChildScrollView(controller:headlineController, scrollDirection:Axis.horizontal, physics:const NeverScrollableScrollPhysics(), child:const Padding(padding:EdgeInsets.symmetric(horizontal:16), child:Text(' بابا فلک ناز رحمۃ اللہ علیہ اینڈ سنز ٹریڈرز | Welcome To FNS TRADERS | BABA FALAK NAZ & SONS TRADERS | ', style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold))))),
        Container(width:double.infinity, padding:const EdgeInsets.symmetric(vertical:8), color:Colors.green.shade700, child:const Center(child:Text('مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ', style:TextStyle(color:Colors.white, fontSize:18, fontWeight:FontWeight.w700)))),
        Expanded(child:[_buildHome(), _buildCart(), _buildFav(), _buildBill(), _buildAdminLogin()][bottomIndex]),
      ])),
      floatingActionButton:FloatingActionButton(backgroundColor:const Color(0xFF25D366), onPressed:()=>_openWhatsApp(), child:const Icon(Icons.chat, color:Colors.white)),
      bottomNavigationBar:BottomNavigationBar(currentIndex:bottomIndex, type:BottomNavigationBarType.fixed, selectedItemColor:const Color(0xFF1E4DB7), onTap:(i)=>setState(()=>bottomIndex=i), items:const[BottomNavigationBarItem(icon:Icon(Icons.home), label:"Home"), BottomNavigationBarItem(icon:Icon(Icons.shopping_cart), label:"Cart"), BottomNavigationBarItem(icon:Icon(Icons.favorite), label:"Fav"), BottomNavigationBarItem(icon:Icon(Icons.receipt_long), label:"Bill"), BottomNavigationBarItem(icon:Icon(Icons.admin_panel_settings), label:"Admin")]),
    ));
  }

  List<Product> get filtered => products.where((p){ final ms=p.name.toLowerCase().contains(search.toLowerCase()); final mc=cat=='All'||p.category==cat; return ms&&mc; }).toList();
  Widget _buildHome(){ return ListView(padding:const EdgeInsets.all(12), children:[ Image.asset('fns_logo.png', height:110, errorBuilder:(_,__,___)=>const Icon(Icons.store, size:60)), TextField(decoration:InputDecoration(prefixIcon:const Icon(Icons.search), hintText:'Search...', border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))), onChanged:(v)=>setState(()=>search=v)), const SizedBox(height:8), SizedBox(height:40, child:ListView.separated(scrollDirection:Axis.horizontal, itemCount:categories.length, separatorBuilder:(_,__)=>const SizedBox(width:6), itemBuilder:(_,i){ final c=categories[i]; return ChoiceChip(label:Text(c), selected:cat==c, onSelected:(_)=>setState(()=>cat=c)); })),...filtered.asMap().entries.map((e){ final realIdx=products.indexOf(e.value); final p=e.value; return Card(child:ListTile(leading:p.imageBase64.isNotEmpty?Image.memory(base64Decode(p.imageBase64), width:50, height:50, fit:BoxFit.cover):const Icon(Icons.medical_services), title:Text(p.name), subtitle:Text('Rs.${p.price} | ${p.category} ${p.inStock?'':' (Out of Stock)'}'), trailing:Row(mainAxisSize:MainAxisSize.min, children:[IconButton(icon:Icon(fav.contains(realIdx)?Icons.favorite:Icons.favorite_border, color:Colors.red), onPressed:()=>setState((){ if(fav.contains(realIdx)) fav.remove(realIdx); else fav.add(realIdx); })), IconButton(icon:const Icon(Icons.add_shopping_cart), onPressed:p.inStock?(){ setState(()=>cart[realIdx]=(cart[realIdx]??0)+1); }:null)]))); })]); }
  Widget _buildCart(){ int total=0; cart.forEach((k,v){ if(k<products.length) total+=products[k].price*v; }); return Column(children:[Expanded(child:ListView(children:cart.entries.map((en)=>ListTile(title:Text(products[en.key].name), subtitle:Text('Qty ${en.value} x Rs.${products[en.key].price}'), trailing:IconButton(icon:const Icon(Icons.delete), onPressed:()=>setState(()=>cart.remove(en.key))))).toList())), Container(padding:const EdgeInsets.all(12), color:Colors.grey.shade200, child:Column(children:[Text('Total Rs.$total | Min Rs.$minOrder', style:const TextStyle(fontWeight:FontWeight.bold)), SizedBox(width:double.infinity, child:ElevatedButton(onPressed:total==0?null:()=>_orderDialog(total), child:const Text('Confirm Order')))]))]); }
  void _orderDialog(int total){ if(total<minOrder){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Minimum Order Rs.$minOrder'))); return; } final n=TextEditingController(), s=TextEditingController(), a=TextEditingController(), m=TextEditingController(); showDialog(context:context, builder:(_)=>AlertDialog(title:const Text('Order Details'), content:Column(mainAxisSize:MainAxisSize.min, children:[TextField(controller:n, decoration:const InputDecoration(labelText:'Customer Name')), TextField(controller:s, decoration:const InputDecoration(labelText:'Store Name')), TextField(controller:a, decoration:const InputDecoration(labelText:'Address')), TextField(controller:m, decoration:const InputDecoration(labelText:'Mobile'))]), actions:[TextButton(onPressed:()=>Navigator.pop(context), child:const Text('Cancel')), ElevatedButton(onPressed:(){ final msg="NEW ORDER - FNS TRADERS\nDate/Time: ${getDT()}\nName:${n.text}\nStore:${s.text}\nAddress:${a.text}\nMobile:${m.text}\n\nItems:\n${cart.entries.map((e)=>"${products[e.key].name} x ${e.value}").join("\n")}\nTotal: Rs. $total\n\nShop: $shopAddress"; Navigator.pop(context); _openWhatsApp(message:msg); }, child:const Text('Send WhatsApp'))])); }
  Widget _buildFav(){ final list=fav.where((i)=>i<products.length).toList(); if(list.isEmpty) return const Center(child:Text('No Fav')); return ListView(children:list.map((i)=>ListTile(title:Text(products[i].name))).toList()); }
  Widget _buildBill(){ int total=0; cart.forEach((k,v){ if(k<products.length) total+=products[k].price*v; }); return SingleChildScrollView(padding:const EdgeInsets.all(12), child:Column(children:[Container(padding:const EdgeInsets.all(14), decoration:BoxDecoration(border:Border.all(width:1.5), color:Colors.white), child:Column(children:[Image.asset('fns_logo.png', height:90, errorBuilder:(_,__,___)=>const Icon(Icons.store, size:60)), const Text('BABA FALAK NAZ & SONS TRADERS', textAlign:TextAlign.center, style:TextStyle(fontWeight:FontWeight.bold, fontSize:16)), const Divider(thickness:2), Text('Address: $shopAddress', textAlign:TextAlign.center, style:const TextStyle(fontSize:11, fontWeight:FontWeight.w600)), Text('Mobile / WhatsApp: $shopMobile', style:const TextStyle(fontSize:11, fontWeight:FontWeight.w600)), const Divider(), Align(alignment:Alignment.centerLeft, child:Text('Invoice No: ${generateInvoiceNo()}', style:const TextStyle(fontWeight:FontWeight.bold, fontSize:12))), Align(alignment:Alignment.centerLeft, child:Text('Date/Time: ${getDT()}', style:const TextStyle(fontWeight:FontWeight.bold, fontSize:12))), const SizedBox(height:8),...cart.entries.map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:2), child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[Expanded(child:Text('${products[e.key].name} x${e.value}', style:const TextStyle(fontSize:12))), Text('Rs.${products[e.key].price*e.value}', style:const TextStyle(fontSize:12))]))), const Divider(thickness:1.5), Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[const Text('TOTAL:', style:TextStyle(fontWeight:FontWeight.bold, fontSize:14)), Text('Rs.$total', style:const TextStyle(fontWeight:FontWeight.bold, fontSize:14))]), const Divider(), const Align(alignment:Alignment.centerLeft, child:Text('Note:', style:TextStyle(fontWeight:FontWeight.bold, fontSize:11))), const Align(alignment:Alignment.centerLeft, child:Text('* Goods once sold will not be taken back or exchanged.\n* Expiry items will not be returned.\n* Please check your bill and goods before leaving.', style:TextStyle(fontSize:10))), const SizedBox(height:8), Container(width:double.infinity, color:Colors.black, padding:const EdgeInsets.all(6), child:const Center(child:Text('THANK YOU - VISIT AGAIN', style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold))))])), const SizedBox(height:12), Row(children:[Expanded(child:ElevatedButton.icon(onPressed:(){ int t=0; cart.forEach((k,v){ if(k<products.length) t+=products[k].price*v; }); printA4Bill(t); }, icon:const Icon(Icons.print), label:const Text('A4 Print'))), const SizedBox(width:8), Expanded(child:ElevatedButton.icon(onPressed:(){ int t=0; cart.forEach((k,v){ if(k<products.length) t+=products[k].price*v; }); printThermalBill(t); }, icon:const Icon(Icons.receipt), label:const Text('Thermal 80mm')))],)])); }
  Widget _buildAdminLogin(){ final pass=TextEditingController(); return StatefulBuilder(builder:(ctx,setSt){ return ListView(padding:const EdgeInsets.all(16), children:[const Text('Admin Panel', style:TextStyle(fontSize:20, fontWeight:FontWeight.bold)), if(!_isAdmin)...[TextField(controller:pass, obscureText:true, decoration:const InputDecoration(labelText:'Password fns123', border:OutlineInputBorder())), const SizedBox(height:10), ElevatedButton(onPressed:(){ if(pass.text=='fns123') setState(()=>_isAdmin=true); }, child:const Text('Login'))] else...[_buildFullAdmin(), ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.red), onPressed:()=>setState(()=>_isAdmin=false), child:const Text('Logout'))]]); }); }
  Widget _buildFullAdmin(){ final nameCtrl=TextEditingController(); final priceCtrl=TextEditingController(); String selCat='General'; return StatefulBuilder(builder:(ctx,setSt){ return Column(crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('Add New Product', style:TextStyle(fontWeight:FontWeight.bold)), TextField(controller:nameCtrl, decoration:const InputDecoration(labelText:'Name')), TextField(controller:priceCtrl, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Price')), DropdownButton<String>(value:selCat, items:categories.where((c)=>c!='All').map((c)=>DropdownMenuItem(value:c, child:Text(c))).toList(), onChanged:(v)=>setSt(()=>selCat=v!)), ElevatedButton(onPressed:() async { if(nameCtrl.text.isEmpty) return; setState(()=>products.add(Product(name:nameCtrl.text, price:int.tryParse(priceCtrl.text)??0, category:selCat))); await _save(); nameCtrl.clear(); priceCtrl.clear(); setSt((){}); }, child:const Text('Add Product')), const Divider(), const Text('All Products - Edit / Stock / Photo / Delete', style:TextStyle(fontWeight:FontWeight.bold)),...products.asMap().entries.map((en){ final idx=en.key; final p=en.value; return Card(child:ListTile(leading:p.imageBase64.isNotEmpty?Image.memory(base64Decode(p.imageBase64), width:50, height:50):const Icon(Icons.image_not_supported), title:Text(p.name), subtitle:Text('Rs.${p.price} | ${p.category} | ${p.inStock?'In Stock':'Stopped'}'), isThreeLine:true, trailing:PopupMenuButton<String>(onSelected:(val) async { if(val=='toggle_stock'){ setState(()=>products[idx].inStock=!products[idx].inStock); await _save(); } if(val=='delete'){ setState(()=>products.removeAt(idx)); await _save(); } if(val=='add_photo'){ final XFile? x=await ImagePicker().pickImage(source:ImageSource.gallery, imageQuality:50); if(x!=null){ final b=await x.readAsBytes(); setState(()=>products[idx].imageBase64=base64Encode(b)); await _save(); } } if(val=='remove_photo'){ setState(()=>products[idx].imageBase64=''); await _save(); } }, itemBuilder:(_)=>[PopupMenuItem(value:'toggle_stock', child:Text(p.inStock?'Stop / Out of Stock':'Start / In Stock')), const PopupMenuItem(value:'add_photo', child:Text('Photo Lagao / Change')), const PopupMenuItem(value:'remove_photo', child:Text('Photo Hatao')), const PopupMenuItem(value:'delete', child:Text('Delete Product', style:TextStyle(color:Colors.red)))]))); }).toList(), ]); }); }
}
