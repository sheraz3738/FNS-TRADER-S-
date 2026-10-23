import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: AuthCheck()));
}

class AuthCheck extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), builder: (c, snap) {
      if (snap.hasData) return MainCustomerWrapper();
      return RegisterScreen();
    });
  }
}

class MainCustomerWrapper extends StatefulWidget { @override State<MainCustomerWrapper> createState() => _MainCustomerWrapperState(); }

class _MainCustomerWrapperState extends State<MainCustomerWrapper> {
  int currentIndex = 0;
  final pages = [CustomerScreen(), Center(child: Text("Cart")), Center(child: Text("Favorite")), Center(child: Text("About"))];

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Fav"),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "About"),
          // ADMIN HATA DIYA HAI YAHAN SE
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget { @override State<RegisterScreen> createState() => _RegisterScreenState(); }

class _RegisterScreenState extends State<RegisterScreen> {
  var shopNameC = TextEditingController(); var addressC = TextEditingController(); var contactC = TextEditingController(); var otpC = TextEditingController(); var passC = TextEditingController();
  String verId = ""; bool otpSent = false; bool isLogin = false; String msg = "";

  Future<void> sendOTP() async {
    if (shopNameC.text.isEmpty && !isLogin) { setState(() => msg = "Shop Name zaroori hai"); return; }
    String phone = contactC.text.trim(); if (phone.startsWith("0")) phone = "+92" + phone.substring(1); else if (!phone.startsWith("+")) phone = "+92$phone";
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(phoneNumber: phone, verificationCompleted: (c) {}, verificationFailed: (e) { setState(() => msg = e.message ?? "Fail"); }, codeSent: (v, t) { setState(() { verId = v; otpSent = true; msg = "OTP bhej diya $phone par"; }); }, codeAutoRetrievalTimeout: (v) { verId = v; });
    } catch (e) { setState(() => msg = e.toString()); }
  }

  Future<void> verify() async {
    try {
      var cred = PhoneAuthProvider.credential(verificationId: verId, smsCode: otpC.text.trim());
      var userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      await FirebaseFirestore.instance.collection('customers').doc(userCred.user!.uid).set({'shopName': shopNameC.text.trim(), 'address': addressC.text.trim(), 'contact': contactC.text.trim(), 'password': passC.text.trim(), 'createdAt': FieldValue.serverTimestamp()});
    } catch (e) { setState(() => msg = "OTP ghalat hai"); }
  }

  Future<void> login() async {
    try {
      String email = "${contactC.text.trim()}@fns.com";
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: passC.text.trim());
    } catch (e) { setState(() => msg = "Login Fail - Password check karen"); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(body: Column(children: [
      Container(width: double.infinity, color: Color(0xFF0D47A1), padding: EdgeInsets.all(8), child: Text("BABA FALAK NAZ & SONS TRADERS | Welcome To FNS TRADERS", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
      Container(width: double.infinity, color: Colors.green[700], padding: EdgeInsets.all(8), child: Text("مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      Expanded(child: Center(child: SingleChildScrollView(padding: EdgeInsets.all(16), child: Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        Text(isLogin ? "LOGIN" : "CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 10),
        if (!isLogin) TextField(controller: shopNameC, decoration: InputDecoration(labelText: "Shop Name *", border: OutlineInputBorder())),
        if (!isLogin) SizedBox(height: 10),
        if (!isLogin) TextField(controller: addressC, decoration: InputDecoration(labelText: "Shop Address *", border: OutlineInputBorder())),
        SizedBox(height: 10),
        TextField(controller: contactC, decoration: InputDecoration(labelText: "Mobile Number *", border: OutlineInputBorder())),
        SizedBox(height: 10),
        TextField(controller: passC, obscureText: true, decoration: InputDecoration(labelText: "Strong Password *", border: OutlineInputBorder())),
        SizedBox(height: 10),
        if (otpSent && !isLogin) TextField(controller: otpC, decoration: InputDecoration(labelText: "OTP *", border: OutlineInputBorder())),
        if (msg != "") Padding(padding: EdgeInsets.all(8), child: Text(msg, style: TextStyle(color: Colors.red))),
        SizedBox(height: 10),
        if (!isLogin && !otpSent) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: sendOTP, child: Text("SEND OTP"))),
        if (!isLogin && otpSent) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: verify, child: Text("VERIFY OTP & CREATE ID"))),
        if (isLogin) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: login, child: Text("LOGIN"))),
        TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "New? Create Account" : "Already have ID? Login"))
      ]))))))
    ]));
  }
}
