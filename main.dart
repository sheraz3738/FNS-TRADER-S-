import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const FnsApp());

class Product {
  String name; int price; bool inStock; String imageBase64; String category;
  Product({required this.name, required this.price, this.inStock=true, this.imageBase64='', this.category='Other'});
  Map<String,dynamic> toJson()=>{'name':name,'price':price,'inStock':inStock,'imageBase64':imageBase64,'category':category};
  factory Product.fromJson(Map<String,dynamic> j)=>Product(name:j['name']??'', price:int.tryParse(j['price'].toString())??0, inStock:j['inStock']??true, imageBase64:j['imageBase64']??'', category:j['category']??'Other');
}

class FnsApp extends StatefulWidget{const FnsApp({super.key}); @override State<FnsApp> createState()=>_FnsAppState();}
class _FnsAppState extends State<FnsApp>{
  static const String whatsappNumber='923343738405';
  List<Product> products=[
    Product(name:'Hydryllin Syrup 120ml',price:200,category:'General'),
    Product(name:'Pulmonol Syrup 120ml',price:200,category:'General'),
    Product(name:'Lederplex Syrup 150ml',price:234,category:'General'),
    Product(name:'Extor 5/80 Tablet',price:490,category:'General'),
    Product(name:'Risek 40mg Capsule',price:861,category:'General'),
  ];
  final Map<Product,int> cart={};
  final Set<String> favorites={};
  String searchText=''; bool loading=true; String selectedCategory='All';
  static const List<String> categories=['General','Glucometer','B.P Operator','Stethoscope','Surgical','Syrup','Tablet','Other'];

  @override
  void initState(){super.initState(); loadSavedData();}
  Future<void> loadSavedData() async {
    final prefs=await SharedPreferences.getInstance();
    final saved=prefs.getString('products');
    if(saved!=null && saved.isNotEmpty){try{final d=jsonDecode(saved) as List; products=d.map((e)=>Product.fromJson(Map<String,dynamic>.from(e))).toList();}catch(_){}}
    setState(()=>loading=false);
  }
  Future<void> saveProducts() async {final p=await SharedPreferences.getInstance(); await p.setString('products', jsonEncode(products.map((e)=>e.toJson()).toList()));}
  int get cartCount{int c=0; for(final v in cart.values) c+=v; return c;}
  int get cartTotal{int t=0; for(final e in cart.entries) t+=e.key.price*e.value; return t;}
  List<Product> get filtered{final q=searchText.toLowerCase(); return products.where((p){final cat=selectedCategory=='All'||p.category==selectedCategory; final s=q.isEmpty||p.name.toLowerCase().contains(q); return cat&&s;}).toList();}
  void addToCart(Product p){setState(()=>cart[p]=(cart[p]??0)+1); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${p.name} added')));}
  void inc(Product p){setState(()=>cart[p]=(cart[p]??0)+1);}
  void dec(Product p){setState((){final q=cart[p]??0; if(q<=1) cart.remove(p); else cart[p]=q-1;});}

  Future<void> generateBill(String cust, String phone, String addr) async {
    final pdf=pw.Document();
    pdf.addPage(pw.Page(build:(c)=>pw.Column(children:[
      pw.Text('FNS TRADERS',style:pw.TextStyle(fontSize:24,fontWeight:pw.FontWeight.bold)),
      pw.SizedBox(height:10), pw.Text('Customer: $cust'), pw.Text('Phone: $phone'), pw.Text('Address: $addr'),
      pw.Divider(),
     ...cart.entries.map((e)=>pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween, children:[pw.Text('${e.key.name} x ${e.value}'), pw.Text('Rs. ${e.key.price*e.value}') ])),
      pw.Divider(), pw.Text('Total: Rs. $cartTotal',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),
    ])));
    await Printing.layoutPdf(onLayout:(f)=>pdf.save());
  }

  void checkout(){
    final c1=TextEditingController(); final c2=TextEditingController(); final c3=TextEditingController();
    showDialog(context:context, builder:(_)=>AlertDialog(title:const Text('Checkout'), content:Column(mainAxisSize:MainAxisSize.min, children:[
      TextField(controller:c1,decoration:const InputDecoration(labelText:'Customer Name')), TextField(controller:c2,decoration:const InputDecoration(labelText:'Phone')), TextField(controller:c3,decoration:const InputDecoration(labelText:'Address')),
    ]), actions:[
      TextButton(onPressed:()=>Navigator.pop(context), child:const Text('Cancel')),
      FilledButton(onPressed:(){Navigator.pop(context); generateBill(c1.text,c2.text,c3.text); setState(()=>cart.clear());}, child:const Text('Generate Bill')),
    ]));
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(debugShowCheckedModeBanner:false, title:'FNS TRADERS', home:Scaffold(
      appBar:AppBar(title:const Text('FNS TRADERS',style:TextStyle(fontWeight:FontWeight.bold,color:Colors.white)), backgroundColor:Colors.blue[900], centerTitle:true),
      body: loading? const Center(child:CircularProgressIndicator()) : Column(children:[
        Container(margin:const EdgeInsets.all(10), padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18), boxShadow:[BoxShadow(blurRadius:8,color:const Color(0x22000000),offset:const Offset(0,3))]), child:Image.asset('fns_logo.png', height:130, fit:BoxFit.contain, errorBuilder:(_,__,___)=>Icon(Icons.store,size:80,color:Colors.blue[900]))),
        Container(width:double.infinity, padding:const EdgeInsets.symmetric(vertical:10), color:Colors.green.shade700, child:const Center(child:Text('Welcome To FNS Traders',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700)))),
        Padding(padding:const EdgeInsets.all(12), child:TextField(decoration:const InputDecoration(hintText:'Search products...',prefixIcon:Icon(Icons.search),border:OutlineInputBorder()), onChanged:(v)=>setState(()=>searchText=v))),
        SizedBox(height:40, child:ListView(scrollDirection:Axis.horizontal, padding:const EdgeInsets.symmetric(horizontal:12), children:[ChoiceChip(label:const Text('All'), selected:selectedCategory=='All', onSelected:(_)=>setState(()=>selectedCategory='All')),...categories.map((cat)=>Padding(padding:const EdgeInsets.only(left:8), child:ChoiceChip(label:Text(cat), selected:selectedCategory==cat, onSelected:(_)=>setState(()=>selectedCategory=cat))))])),
        Expanded(child:ListView(padding:const EdgeInsets.all(12), children: filtered.map((p)=>Card(child:ListTile(title:Text(p.name,style:const TextStyle(fontWeight:FontWeight.bold)), subtitle:Text('Rs. ${p.price} - ${p.category}'), trailing:IconButton(icon:const Icon(Icons.add_shopping_cart), onPressed:()=>addToCart(p))))).toList())),
      ]),
      bottomNavigationBar: BottomAppBar(child: Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8), child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Text('Items: $cartCount | Rs. $cartTotal',style:const TextStyle(fontWeight:FontWeight.bold)),
        FilledButton(onPressed: cart.isEmpty? null : checkout, child:const Text('Checkout')),
      ]))),
    ));
  }
}
