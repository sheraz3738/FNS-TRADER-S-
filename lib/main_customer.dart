
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthCheck(),
    ),
  );
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MainCustomerWrapper();
        }

        return RegisterScreen();
      },
    );
  }
}

class MainCustomerWrapper extends StatefulWidget {
  @override
  State<MainCustomerWrapper> createState() =>
      _MainCustomerWrapperState();
}

class _MainCustomerWrapperState extends State<MainCustomerWrapper> {
  int currentIndex = 0;

  final pages = [
    CustomerScreen(),
    Center(child: Text("Cart")),
    Center(child: Text("Favorite")),
    Center(child: Text("About")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Fav",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: "About",
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final shopNameC = TextEditingController();
  final addressC = TextEditingController();
  final contactC = TextEditingController();
  final passC = TextEditingController();

  bool isLogin = false;
  bool loading = false;
  String msg = "";

  // Mobile number se consistent Firebase email banayein.
  String makeEmail(String mobile) {
    String digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('0092')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('92') && digits.length == 12) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }

    return 'customer_$digits@fns.com';
  }

  Future<void> createAccount() async {
    FocusScope.of(context).unfocus();

    if (shopNameC.text.trim().isEmpty ||
        addressC.text.trim().isEmpty ||
        contactC.text.trim().isEmpty ||
        passC.text.isEmpty) {
      setState(() => msg = "Tamam fields fill karein.");
      return;
    }

    if (passC.text.length < 6) {
      setState(() => msg = "Password kam az kam 6 characters ka ho.");
      return;
    }

    setState(() {
      loading = true;
      msg = "";
    });

    try {
      final email = makeEmail(contactC.text.trim());

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: passC.text,
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .set({
        'shopName': shopNameC.text.trim(),
        'address': addressC.text.trim(),
        'contact': contactC.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // AuthCheck successful login ke baad Customer Home khol dega.
    } on FirebaseAuthException catch (e) {
      String error;

      switch (e.code) {
        case 'email-already-in-use':
          error = "Is number ka account pehle se bana hua hai. Login karein.";
          break;
        case 'weak-password':
          error = "Password mazboot rakhein.";
          break;
        case 'invalid-email':
          error = "Mobile number check karein.";
          break;
        case 'operation-not-allowed':
          error = "Firebase mein Email/Password enable karein.";
          break;
        case 'network-request-failed':
          error = "Internet connection check karein.";
          break;
        default:
          error = e.message ?? "Account nahi ban saka.";
      }

      if (mounted) setState(() => msg = error);
    } catch (e) {
      if (mounted) {
        setState(() {
          msg = "Account save nahi hua. Internet aur Firebase check karein.";
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    if (contactC.text.trim().isEmpty || passC.text.isEmpty) {
      setState(() => msg = "Mobile number aur password enter karein.");
      return;
    }

    setState(() {
      loading = true;
      msg = "";
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: makeEmail(contactC.text.trim()),
        password: passC.text,
      );

      // AuthCheck Customer Home khol dega.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          msg = e.code == 'user-not-found' ||
                  e.code == 'wrong-password' ||
                  e.code == 'invalid-credential'
              ? "Account ya password ghalat hai."
              : (e.message ?? "Login nahi ho saka.");
        });
      }
    } catch (e) {
      if (mounted) setState(() => msg = "Login nahi ho saka.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    shopNameC.dispose();
    addressC.dispose();
    contactC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF0D47A1),
              padding: const EdgeInsets.all(12),
              child: const Text(
                "BABA FALAK NAZ & SONS TRADERS\n"
                "Welcome To FNS TRADERS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.green,
              padding: const EdgeInsets.all(10),
              child: const Text(
                "مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isLogin ? "CUSTOMER LOGIN" : "CREATE CUSTOMER ACCOUNT",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (!isLogin) ...[
                            TextField(
                              controller: shopNameC,
                              decoration: const InputDecoration(
                                labelText: "Shop Name *",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: addressC,
                              decoration: const InputDecoration(
                                labelText: "Shop Address *",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          TextField(
                            controller: contactC,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "Mobile Number *",
                              hintText: "03XXXXXXXXX",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: passC,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password *",
                              helperText: "Kam az kam 6 characters",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (msg.isNotEmpty)
                            Text(
                              msg,
                              style: const TextStyle(color: Colors.red),
                            ),

                          const SizedBox(height: 12),

                          ElevatedButton(
                            onPressed: loading
                                ? null
                                : (isLogin ? login : createAccount),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: loading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      isLogin
                                          ? "LOGIN"
                                          : "CREATE NEW ACCOUNT",
                                    ),
                            ),
                          ),

                          TextButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      isLogin = !isLogin;
                                      msg = "";
                                    });
                                  },
                            child: Text(
                              isLogin
                                  ? "New customer? Create Account"
                                  : "Already have an account? Login",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
