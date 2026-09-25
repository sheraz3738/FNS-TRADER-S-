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
  factory Product.fromJson(Map<String, dynamic> j) => Product(name: j['name']?.toString()??'', price: int.tryParse(j['price'].toString())??0, inStock: j['inStock']??true, imageBase64: j['imageBase64']?.toString()??'', category: j['category']?.toString()??'Other');
}

class OrderData {
  final String orderNo, dateTime, customer, phone, address, items; final int total; final String payment;
  OrderData({required this.orderNo, required this.dateTime, required this.customer, required this.phone, required this.address, required this.items, required this.total, required this.payment});
  Map<String, dynamic> toJson() => {'orderNo':orderNo,'dateTime':dateTime,'customer':customer,'phone':phone,'address':address,'items':items,'total':total,'payment':payment};
  factory OrderData.fromJson(Map<String, dynamic> j) => OrderData(orderNo: j['orderNo'].toString(), dateTime: j['dateTime'].toString(), customer: j['customer'].toString(), phone: j['phone'].toString(), address: j['address'].toString(), items: j['items'].toString(), total: int.tryParse(j['total'].toString())??0, payment: j['payment'].toString());
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
  final Map<Product, int> cart = {}; final Set<String> favorites = {}; final List<OrderData> orders = [];
  String searchText = ''; int bottomIndex = 0; bool loading = true; String selectedCategory = 'All';
  late ScrollController _headlineController;
  Offset _fabPosition = const Offset(280, 550);
  static const List<String> categories = ['General','Glucometer','B.P Operator','Stethoscope','Surgical','Syrup','Tablet','Other'];

  String detectCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('syrup') || n.contains('syp')) return 'Syrup';
    if (n.contains('tablet') || n.contains('tab') || n.contains('capsule') || n.contains('cap')) return 'Tablet';
    if (n.contains('b.p') || n.contains('bp') || n.contains('blood pressure') || n.contains('operator')) return 'B.P Operator';
    if (n.contains('glucometer') || n.contains('gluco')) return 'Glucometer';
    if (n.contains('stetho')) return 'Stethoscope';
    if (n.contains('surgical') || n.contains('syringe') || n.contains('bandage') || n.contains('gauze')) return 'Surgical';
    return 'General';
  }

  Future<void> _openWhatsApp({String? message}) async {
    final uri = Uri.parse('https://wa.me/$whatsappNumber${message == null? '' : '?text=${Uri.encodeComponent(message)}'}');
    try { if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return; } catch (_) {}
 
