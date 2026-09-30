import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerSignupScreen extends StatefulWidget {
  @override
  _CustomerSignupScreenState createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopController = TextEditingController();
  final _passController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _otpController = TextEditingController();

  String _verificationId = "";
  bool _otpSent = false;
  bool _loading = false;

  // 1. OTP Bhejna
  void sendOTP() async {
    setState(() => _loading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+92${_phoneController.text.trim().substring(1)}', // 03XX -> +92
      verificationCompleted: (c) {},
      verificationFailed: (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message!)));
        setState(() => _loading = false);
      },
      codeSent: (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _loading = false;
        });
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  // 2. Account Verify + Create
  void verifyAndCreate() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Yahan aap Firebase Firestore me 6 details save karoge
      // Name, Phone, Shop, City, Address, Password

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account Ban Gaya! BA BA FALAK NAZ TRADERS me Khush Amdeed")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Galat OTP!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Customer Account")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Full Name")),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Mobile Number (03XX-XXXXXXX)")),
            TextField(controller: _shopController, decoration: InputDecoration(labelText: "Shop Name")),
            TextField(controller: _cityController, decoration: InputDecoration(labelText: "City")),
            TextField(controller: _addressController, decoration: InputDecoration(labelText: "Full Address")),
            TextField(controller: _passController, obscureText: true, decoration: InputDecoration(labelText: "Password")),
            
            SizedBox(height: 20),
            if (!_otpSent)
              ElevatedButton(onPressed: _loading ? null : sendOTP, child: Text(_loading ? "OTP Bhej Rahe Hain..." : "Send OTP")),
            
            if (_otpSent) ...[
              TextField(controller: _otpController, decoration: InputDecoration(labelText: "6 Digit OTP Code")),
              SizedBox(height: 10),
              ElevatedButton(onPressed: verifyAndCreate, child: Text("Verify & Create Account")),
            ]
          ],
        ),
      ),
    );
  }
}
