import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const FnsCustomerApp());

class Product {
  String name; int price; double discount; bool inStock; String imageBase64; String category;
  Product({required this.name, required this.price, this.discount=0, this.inStock=true, this.imageBase64='', this.category='General'});
  int get finalPrice => discount > 0? (price - (price * discount / 100)).round() : price;
  Map<String, dynamic> toJson() => {'name':name,'price':price,'discount':discount,'inStock':inStock,'imageBase64':imageBase64,'category':category};
  factory Product.fromJson(Map<String,dynamic> j) => Product(name:j['name']??'', price:int.tryParse(j['price'].toString())??0, discount:double.tryParse(j['discount'].toString())??0, inStock:j['inStock']??true, imageBase64:j['imageBase64']??'', category:j['category']??'General');
}

class FnsCustomerApp extends StatefulWidget { const FnsCustomerApp({super.key}); @override State<FnsCustomerApp> createState()=>_FnsCustomerAppState(); }

class _FnsCustomerAppState extends State<FnsCustomerApp> {
  static const String whatsappNumber = '923343738405';
  static const String shopAddress = 'Plot No, L34 Street No, 02 Sector 8/D K.I.A Karachi';
  static const String shopMobile = '0334-3738405';
  List<Product> products = [];
  final Map<int,int> cart = {};
  final Set<int> fav = {};
  String search=''; String cat='All'; int bottomIndex=0;
  int minOrder = 1000;
  final ScrollController headlineController = ScrollController();
  final List<String> categories = ['All','General','Glucometer','B.P Operator','Stethoscope','Surgical','Syrup','Tablet','Other'];

  String getDT(){ final now=DateTime.now(); String two(int n)=>n.toString().padLeft(2,'0'); final d="${two(now.day)}-${two(now.month)}-${now.year}"; int hh=now.hour; String ap=hh>=12?'PM':'AM'; if(hh>12) hh-=12; if(hh==0) hh=12; return "$d - ${two(hh)}:${two(now.minute)} $ap"; }
  String generateInvoiceNo(){ final now=DateTime.now(); return "INV-${now.year}${now.month}${now.day}-${now.hour}${now.minute}${now.second}"; }

  @override void initState(){ super.initState(); _loadData(); WidgetsBinding.instance.addPostFrameCallback((_)=>_autoScroll()); }
  Future<void> _autoScroll() async { while(mounted){ await Future.delayed(const Duration(seconds:1)); if(!headlineController.hasClients) continue; final max=headlineController.position.maxScrollExtent; if(max<=0) continue; await headlineController.animateTo(max, duration: const Duration(seconds:25), curve:Curves.linear); await Future.delayed(const Duration(milliseconds:600)); headlineController.jumpTo(0);} }
  Future<void> _loadData() async { final sp=await SharedPreferences.getInstance(); final s=sp.getString('products_v2'); if(s!=null){ products=(jsonDecode(s) as List).map((e)=>Product.fromJson(e)).toList(); } minOrder=sp.getInt('minOrder')??1000; setState((){}); }
  Future<void> _openWhatsApp({String? message}) async { final msg=Uri.encodeComponent(message??'Assalam-o-Alaikum FNS Traders'); await launchUrl(Uri.parse('https://wa.me/$whatsappNumber?text=$msg'), mode:LaunchMode.externalApplication); }

  @override Widget build(BuildContext context){
    return MaterialApp(debugShowCheckedModeBanner:false, home:Scaffold(
      body:SafeArea(child:Column(children:[
        Container(height:34, color:const Color(0xFF1E4DB7), alignment:Alignment.centerLeft, child:SingleChildScrollView(controller:headlineController, scrollDirection:Axis.horizontal, physics:const NeverScrollableScrollPhysics(), child:const Padding(padding:EdgeInsets.symmetric(horizontal:16), child:Text(' بابا فلک ناز رحمۃ اللہ علیہ اینڈ سنز ٹریڈرز | Welcome To FNS TRADERS | Special Discount Available | ', style:TextStyle(color:Colors.white, fontWeight:FontWeight.bold))))),
        Container(width:double.infinity, padding:const EdgeInsets.symmetric(vertical:8), color:Colors.green.shade700, child:const Center(child:Text('مَا شَاءَ اللَّهُ لَا قُوَّةَ إِلَّا بِاللَّهِ', style:TextStyle(color:Colors.white, fontSize:18, fontWeight:FontWeight.w700)))),
        Expanded(child:[_buildHome(), _buildCart(), _buildFav(), _buildBill()][bottomIndex]),
      ])),
      floatingActionButton:FloatingActionButton(backgroundColor:const Color(0xFF25D366), onPressed:()=>_openWhatsApp(), child:const Icon(Icons.chat, color:Colors.white)),
      bottomNavigationBar:BottomNavigationBar(currentIndex:bottomIndex, type:BottomNavigationBarType.fixed, selectedItemColor:const Color(0xFF1E4DB7), onTap:(i)=>setState(()=>bottomIndex=i), items:const[BottomNavigationBarItem(icon:Icon(Icons.home), label:"Home"), BottomNavigationBarItem(icon:Icon(Icons.shopping_cart), label:"Cart"), BottomNavigationBarItem(icon:Icon(Icons.favorite), label:"Fav"), BottomNavigationBarItem(icon:Icon(Icons.receipt_long), label:"Bill")]),
    ));
  }

  List<Product> get filtered => products.where((p){ final ms=p.name.toLowerCase().contains(search.toLowerCase()); final mc=cat=='All'||p.category==cat; return ms&&mc; }).toList();
  Widget _buildHome(){ return ListView(padding:const EdgeInsets.all(12), children:[ Image.asset('fns_logo.png', height:110, errorBuilder:(_,__,___)=>const Icon(Icons.store, size:60)), TextField(decoration:InputDecoration(prefixIcon:const Icon(Icons.search), hintText:'Search...', border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))), onChanged:(v)=>setState(()=>search=v)), const SizedBox(height:8), SizedBox(height:40, child:ListView.separated(scrollDirection:Axis.horizontal, itemCount:categories.length, separatorBuilder:(_,__)=>const SizedBox(width:6), itemBuilder:(_,i){ final c=categories[i]; return ChoiceChip(label:Text(c), selected:cat==c, onSelected:(_)=>setState(()=>cat=c)); })),...filtered.asMap().entries.map((e){ final realIdx=products.indexOf(e.value); final p=e.value; return Card(child:ListTile(leading:p.imageBase64.isNotEmpty?Image.memory(base64Decode(p.imageBase64), width:50, height:50, fit:BoxFit.cover):const Icon(Icons.medical_services), title:Text(p.name), subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[ if(p.discount>0) Text('Rs.${p.price} ${p.discount}% OFF', style:const TextStyle(fontSize:11, color:Colors.red, decoration:TextDecoration.lineThrough)), Text('Final: Rs.${p.finalPrice} | ${p.category} ${p.inStock?'':' (Out of Stock)'}', style:TextStyle(color:p.discount>0?Colors.green:Colors.black, fontWeight:FontWeight.bold)), ]), trailing:Row(mainAxisSize:MainAxisSize.min, children:[IconButton(icon:Icon(fav.contains(realIdx)?Icons.favorite:Icons.favorite_border, color:Colors.red), onPressed:()=>setState((){ if(fav.contains(realIdx)) fav.remove(realIdx); else fav.add(realIdx); })), IconButton(icon:const Icon(Icons.add_shopping_cart), onPressed:p.inStock?(){ setState(()=>cart[realIdx]=(cart[realIdx]??0)+1); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${p.name} Added'))); }:null)]))); })]); }
  Widget _buildCart(){ int total=0; cart.forEach((k,v){ if(k<products.length) total+=products[k].finalPrice*v; }); return Column(children:[Expanded(child:ListView(children:cart.entries.map((en){ final p=products[en.key]; return ListTile(title:Text(p.name), subtitle:Text('Qty ${en.value} x Rs.${p.finalPrice} ${p.discount>0?'(${p.discount}% OFF)':''}'), trailing:IconButton(icon:const Icon(Icons.delete), onPressed:()=>setState(()=>cart.remove(en.key)))); }).toList())), Container(padding:const EdgeInsets.all(12), color:Colors.grey.shade200, child:Column(children:[Text('Total Rs.$total | Min Order Rs.$minOrder', style:const TextStyle(fontWeight:FontWeight.bold)), SizedBox(width:double.infinity, child:ElevatedButton(onPressed:total==0?null:()=>_orderDialog(total), child:const Text('Confirm Order')))]))]); }
  void _orderDialog(int total){ if(total<minOrder){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Minimum Order Rs.$minOrder'))); return; } final n=TextEditingController(), s=TextEditingController(), a=TextEditingController(), m=TextEditingController(); showDialog(context:context, builder:(_)=>AlertDialog(title:const Text('Order Details'), content:Column(mainAxisSize:MainAxisSize.min, children:[TextField(controller:n, decoration:const InputDecoration(labelText:'Customer Name')), TextField(controller:s, decoration:const InputDecoration(labelText:'Store Name')), TextField(controller:a, decoration:const InputDecoration(labelText:'Address')), TextField(controller:m, decoration:const InputDecoration(labelText:'Mobile'))]), actions:[TextButton(onPressed:()=>Navigator.pop(context), child:const Text('Cancel')), ElevatedButton(onPressed:(){ final msg="NEW ORDER - FNS TRADERS\nDate/Time: ${getDT()}\nInvoice: ${generateInvoiceNo()}\nName:${n.text}\nStore:${s.text}\nAddress:${a.text}\nMobile:${m.text}\n\nItems:\n${cart.entries.map((e){ final p=products[e.key]; return "${p.name} x ${e.value} @ Rs.${p.finalPrice} ${p.discount>0?'(${p.discount}% OFF)':''} = Rs.${p.finalPrice*e.value}"; }).join("\n")}\n\nTotal: Rs. $total\n\nShop: $shopAddress"; Navigator.pop(context); _openWhatsApp(message:msg); }, child:const Text('Send WhatsApp'))])); }
  Widget _buildFav(){ final list=fav.where((i)=>i<products.length).toList(); if(list.isEmpty) return const Center(child:Text('No Fav')); return ListView(children:list.map((i)=>ListTile(title:Text(products[i].name), subtitle: Text('Final Rs.${products[i].finalPrice}'))).toList()); }
  Widget _buildBill(){ int total=0; cart.forEach((k,v){ if(k<products.length) total+=products[k].finalPrice*v; }); return Center(child:Text('Bill Total: Rs.$total')); }
}
