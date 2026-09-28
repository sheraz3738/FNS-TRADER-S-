import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bill_screen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FNS Traders Customer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignupScreen(),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameCtrl = TextEditingController();
  final shopCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  bool isLoading = false;
  bool showPass = false;

  Future<void> createId() async {
    if ([nameCtrl.text, shopCtrl.text, mobileCtrl.text, passCtrl.text, addressCtrl.text].any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sab fields bharo")));
      return;
    }
    setState(() => isLoading = true);
    try {
      String docId = mobileCtrl.text.trim();
      await FirebaseFirestore.instance.collection('customers').doc(docId).set({
        'customerName': nameCtrl.text.trim(),
        'shopName': shopCtrl.text.trim(),
        'mobile': docId,
        'password': passCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BillScreen(
        shopName: shopCtrl.text, customerName: nameCtrl.text, mobile: docId, address: addressCtrl.text,
      )));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FNS Traders - Create ID")),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Customer Name")),
          const SizedBox(height: 10),
          TextField(controller: shopCtrl, decoration: const InputDecoration(labelText: "Shop Name")),
          const SizedBox(height: 10),
          TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile Number (ID banega)")),
          const SizedBox(height: 10),
          TextField(controller: passCtrl, obscureText:!showPass, decoration: InputDecoration(labelText: "Password (6+ huruf)", suffixIcon: IconButton(icon: Icon(showPass? Icons.visibility : Icons.visibility_off), onPressed: ()=>setState(()=>showPass=!showPass)))),
          const SizedBox(height: 10),
          TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Address")),
          const SizedBox(height: 30),
          isLoading? const CircularProgressIndicator() : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: createId, child: const Text("Create My Shop ID"))),
          TextButton(onPressed: ()=>Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>const LoginScreen())), child: const Text("Already have ID? Login"))
        ]),
      ),
    );
  }
}
