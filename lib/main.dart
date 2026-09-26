import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() async { WidgetsFlutterBinding.ensureInitialized(); await Firebase.initializeApp(); runApp(AdminApp()); }
class AdminApp extends StatelessWidget { @override Widget build(BuildContext context) { return MaterialApp(debugShowCheckedModeBanner: false, home: AdminHome()); } }
class AdminHome extends StatefulWidget { @override State<AdminHome> createState() => _AdminHomeState(); }
class _AdminHomeState extends State<AdminHome> {
  final ayatCtrl = ScrollController();
  @override void initState(){ super.initState(); Timer.periodic(Duration(milliseconds: 80), (t){ if(ayatCtrl.hasClients){ ayatCtrl.jumpTo(ayatCtrl.offset + 1.2); if(ayatCtrl.offset >= ayatCtrl.position.maxScrollExtent) ayatCtrl.jumpTo(0); }}); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: Size.fromHeight(120), child: AppBar(backgroundColor: Color(0xFFFF8C00), flexibleSpace: SafeArea(child: Column(children: [
        Padding(padding: EdgeInsets.all(8), child: Row(children: [CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.local_pharmacy, color: Colors.orange)), SizedBox(width: 10), Text("Baba Falak Naz & Son's Trader's (Karachi)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))])),
        Container(height: 28, color: Colors.black, child: ListView(controller: ayatCtrl, scrollDirection: Axis.horizontal, children: [Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: Text("بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ • وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ • FNS TRADERS KARACHI", style: TextStyle(color: Colors.white)))])),
        Padding(padding: EdgeInsets.all(8), child: SizedBox(height: 40, child: TextField(decoration: InputDecoration(hintText: 'Hydryllin, Pulmonol, Glucometer etc.', filled: true, fillColor: Colors.white, prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: EdgeInsets.zero))))
      ])))),
      body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('orders').orderBy('time', descending: true).snapshots(), builder: (c, s){ if(!s.hasData) return Center(child: CircularProgressIndicator()); return ListView.builder(itemCount: s.data!.docs.length, itemBuilder: (c,i){ var d=s.data!.docs[i]; return Card(child: ListTile(title: Text("${d['customerId']} - ${d['storeName']}"), subtitle: Text("Rs.${d['total']}"), trailing: Text(d['status'])));});}),
      bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, selectedItemColor: Colors.orange, items: [BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'), BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'), BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'), BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin')]),
    );
  }
}
