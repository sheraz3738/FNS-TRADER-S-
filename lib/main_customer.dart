
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
  runApp(const FnsCustomerApp());
}

class FnsCustomerApp extends StatelessWidget {
  const FnsCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FNS TRADERS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) return const MainCustomerWrapper();
        return const RegisterScreen();
      },
    );
  }
}

class MainCustomerWrapper extends StatefulWidget {
  const MainCustomerWrapper({super.key});

  @override
  State<MainCustomerWrapper> createState() =>
      _MainCustomerWrapperState();
}

class _MainCustomerWrapperState extends State<MainCustomerWrapper> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      CustomerScreen(onOpenOrders: () => setState(() => currentIndex = 3)),
      const CartScreen(),
      const FavoriteScreen(),
      const MyOrdersScreen(),
      const AiSearchScreen(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade700,
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite), label: 'Favorite'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long), label: 'My Orders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome), label: 'AI Search'),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
  String msg = '';

  String makeEmail(String mobile) {
    String digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0092')) digits = digits.substring(2);
    if (digits.startsWith('92') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return 'customer_$digits@fns.com';
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (contactC.text.trim().isEmpty || passC.text.isEmpty ||
        (!isLogin &&
        (shopNameC.text.trim().isEmpty || addressC.text.trim().isEmpty))) {
      setState(() => msg = 'Tamam zaroori fields fill karein.');
      return;
    }

    if (!isLogin && passC.text.length < 6) {
      setState(() => msg = 'Password kam az kam 6 characters ka ho.');
      return;
    }

    setState(() {
      loading = true;
      msg = '';
    });

    try {
      final email = makeEmail(contactC.text.trim());
      final auth = FirebaseAuth.instance;

      if (isLogin) {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: passC.text,
        );
      } else {
        final result = await auth.createUserWithEmailAndPassword(
          email: email,
          password: passC.text,
        );

        await FirebaseFirestore.instance
            .collection('customers')
            .doc(result.user!.uid)
            .set({
          'shopName': shopNameC.text.trim(),
          'address': addressC.text.trim(),
          'contact': contactC.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      String error = e.message ?? 'Account nahi ban saka.';
      if (e.code == 'email-already-in-use') {
        error = 'Is number ka account pehle se hai. Login karein.';
      } else if (e.code == 'weak-password') {
        error = 'Password kam az kam 6 characters ka rakhein.';
      } else if (e.code == 'invalid-credential') {
        error = 'Mobile number ya password check karein.';
      } else if (e.code == 'operation-not-allowed') {
        error = 'Firebase mein Email/Password enable karein.';
      }
      if (mounted) setState(() => msg = error);
    } catch (e) {
      if (mounted) setState(() => msg = 'Error: $e');
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Text(
                'BABA FALAK NAZ & SONS TRADERS | WELCOME TO FNS TRADERS',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.green.shade700,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'مَا شَاءَ اللّٰهُ لَا قُوَّةَ إِلَّا بِاللّٰهِ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('FNS TRADERS',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            isLogin ? 'CUSTOMER LOGIN' : 'CREATE ACCOUNT',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (!isLogin) ...[
                            TextField(
                              controller: shopNameC,
                              decoration: const InputDecoration(
                                labelText: 'Shop Name *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: addressC,
                              decoration: const InputDecoration(
                                labelText: 'Shop Address *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          TextField(
                            controller: contactC,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number *',
                              hintText: '03XXXXXXXXX',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: passC,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (msg.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(msg, style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: loading ? null : submit,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: loading
                                  ? const CircularProgressIndicator()
                                  : Text(isLogin ? 'LOGIN' : 'CREATE NEW ACCOUNT'),
                            ),
                          ),
                          TextButton(
                            onPressed: loading ? null : () {
                              setState(() {
                                isLogin = !isLogin;
                                msg = '';
                              });
                            },
                            child: Text(isLogin
                                ? 'New customer? Create Account'
                                : 'Already have an account? Login'),
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

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) => const SimplePage(
      title: 'Cart', message: 'Home par products select karein.');
}

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});
  @override
  Widget build(BuildContext context) => const SimplePage(
      title: 'Favorite', message: 'Favorite products yahan dikhaye jayenge.');
}

class AiSearchScreen extends StatelessWidget {
  const AiSearchScreen({super.key});
  @override
  Widget build(BuildContext context) => const SimplePage(
      title: 'AI Search', message: 'AI Search feature abhi connect nahi hai.');
}

class SimplePage extends StatelessWidget {
  final String title;
  final String message;
  const SimplePage({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(message)),
  );
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SimplePage(title: 'My Orders', message: 'Login karein.');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Orders load nahi ho sake.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Abhi koi order nahi hai.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final status = data['status'] ?? 'Pending';
              final items = (data['items'] as List?) ?? [];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('Order ${docs[index].id}'),
                  subtitle: Text(
                    'Status: $status\n'
                    'Items: ${items.length}\n'
                    'Total: Rs. ${data['total'] ?? 0}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
