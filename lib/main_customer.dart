import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FNSCustomer());
}

class FNSCustomer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

// LOGIN / CREATE ACCOUNT - Admin ID jaisa hi
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final storeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // CREATE ACCOUNT - Paki ID same Admin jaisi
  create() async {
    var count = await FirebaseFirestore.instance.collection('customers').count().get();
    String id = 'FNS-${101 + count.count!}';
    await FirebaseFirestore.instance.collection('customers').doc(id).set({
      'customerId': id,
      'storeName': storeCtrl.text,
      'name': nameCtrl.text,
      'mobile': mobileCtrl.text,
      'password': passCtrl.text,
      'time': FieldValue.serverTimestamp(),
    });
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CustomerHome(customerId: id)));
  }

  login() async {
    var q = await FirebaseFirestore.instance.collection('customers')
      .where('mobile', isEqualTo: mobileCtrl.text)
      .where('password', isEqualTo: passCtrl.text).get();
    if(q.docs.isNotEmpty){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CustomerHome(customerId: q.docs.first.id)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID Ghalat Hai')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade300, Colors.orange.shade700])),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', height: 80, errorBuilder: (_,__,___) => Icon(Icons.local_pharmacy, size: 80, color: Colors.orange)),
                    Text("Baba Falak Naz & Son's", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Trader's (Karachi)"),
                    SizedBox(height: 20),
                    if(!isLogin) TextField(controller: storeCtrl, decoration: InputDecoration(labelText: 'Store Name', prefixIcon: Icon(Icons.store))),
                    if(!isLogin) SizedBox(height: 10),
                    TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isLogin ? 'Mobile / ID' : 'Customer Name', prefixIcon: Icon(Icons.person))),
                    SizedBox(height: 10),
                    if(!isLogin) TextField(controller: mobileCtrl, decoration: InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone))),
                    if(!isLogin) SizedBox(height: 10),
                    TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
                    SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: EdgeInsets.symmetric(vertical: 15)), onPressed: (){ isLogin ? login() : create(); }, child: Text(isLogin ? 'LOGIN' : 'CREATE ACCOUNT', style: TextStyle(color: Colors.white)))),
                    TextButton(onPressed: (){ setState(()=> isLogin = !isLogin); }, child: Text(isLogin ? 'Create New Account' : 'Already have account? Login'))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// CUSTOMER HOME - Bilkul Admin Jaisa
class CustomerHome extends StatefulWidget {
  final String customerId;
  CustomerHome({required this.customerId});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int index = 0;
  final scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    // Auto Scrolling Ayat
    Timer.periodic(Duration(milliseconds: 50), (timer){
      if(scrollController.hasClients){
        scrollController.jumpTo(scrollController.offset + 1);
        if(scrollController.offset >= scrollController.position.maxScrollExtent) scrollController.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(110),
        child: AppBar(
          backgroundColor: Colors.orange,
          flexibleSpace: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 5),
                Text("Baba Falak Naz & Son's Trader's (Karachi)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Delivery Charges Rs.150 + Free on Rs.5000+", style: TextStyle(color: Colors.white, fontSize: 11)),
                // SCROLLING AYAT
                Container(
                  height: 25, color: Colors.black,
                  child: ListView(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    children: [Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ - وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ", style: TextStyle(color: Colors.white)))],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(5),
                  child: TextField(decoration: InputDecoration(hintText: 'Hydryllin, Pulmonol, Glucometer, Panadol etc.', filled: true, fillColor: Colors.white, prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: EdgeInsets.zero)),
                )
              ],
            ),
          ),
        ),
      ),
      body: Center(child: Text('Yahan Aap Ki Products Ayengi - Admin Jaisi List')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final url = "https://wa.me/923001234567?text=Order ID: ${widget.customerId}";
          if(await canLaunch(url)) await launch(url);
        },
        child: Icon(Icons.chat),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: Colors.orange,
        onTap: (i)=> setState(()=> index = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Fav'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Bill'),
          // Admin ka button yahan nahi hai
        ],
      ),
    );
  }
}
