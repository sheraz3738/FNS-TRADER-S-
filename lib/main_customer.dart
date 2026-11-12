
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

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

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('Kya aap FNS TRADERS se exit karna chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CustomerScreen(
        onOpenCart: () => setState(() => currentIndex = 1),
        onOpenOrders: () => setState(() => currentIndex = 2),
        onOpenProfile: () => setState(() => currentIndex = 3),
        onOpenAi: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AiSearchScreen())),
      ),
      CartScreen(onOrderPlaced: () => setState(() => currentIndex = 2)),
      const MyOrdersScreen(),
      const ProfileSettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green.shade700,
          onTap: (i) => setState(() => currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'My Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
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

class CartScreen extends StatefulWidget {
  final VoidCallback? onOrderPlaced;
  const CartScreen({super.key, this.onOrderPlaced});
  @override State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int get totalItems => fnsCustomerCart.values.fold(0, (sum, q) => sum + q);

  @override
  Widget build(BuildContext context) {
    final entries = fnsCustomerCart.entries.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: entries.isEmpty
          ? const Center(child: Text('Cart abhi khali hai. Home se products add karein.'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final entry in entries)
                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance.collection('products').doc(entry.key).get(),
                          builder: (context, snapshot) {
                            final product = snapshot.data?.data() ?? {};
                            final name = (product['name'] ?? 'Product').toString();
                            final rate = ((product['netRate'] ?? product['price']) as num?)?.toInt() ?? 0;
                            final discount = ((product['discountRate'] ?? product['itemDiscount'] ?? 0) as num).toInt().clamp(0, rate);
                            final lineTotal = (rate - discount) * entry.value;
                            return Card(
                              child: ListTile(
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Rate: Rs. $rate  •  Discount: Rs. $discount\n${entry.value} × Rs. ${rate - discount} = Rs. $lineTotal'),
                                isThreeLine: true,
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(onPressed: () => setState(() { if (entry.value <= 1) { fnsCustomerCart.remove(entry.key); } else { fnsCustomerCart[entry.key] = entry.value - 1; } }), icon: const Icon(Icons.remove_circle_outline)),
                                  Text(entry.value.toString()),
                                  IconButton(onPressed: () => setState(() { fnsCustomerCart[entry.key] = entry.value + 1; }), icon: const Icon(Icons.add_circle_outline, color: Colors.green)),
                                  IconButton(onPressed: () => setState(() => fnsCustomerCart.remove(entry.key)), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                                ]),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: SlideToOrderButton(
                      itemCount: totalItems,
                      onComplete: () {
                        placeFNSCustomerOrder(
                          context,
                          cart: fnsCustomerCart,
                          totalItems: totalItems,
                          skipConfirmation: true,
                          onOrderPlaced: widget.onOrderPlaced,
                        ).then((_) { if (mounted) setState(() {}); });
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});
  @override
  Widget build(BuildContext context) => const SimplePage(
      title: 'Favorite', message: 'Favorite products yahan dikhaye jayenge.');
}

class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  String selected = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Products')),
      body: Column(
        children: [
          if (selected.isEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Expanded(child: _choiceCard(
                  icon: Icons.trending_up,
                  title: 'Trending',
                  subtitle: 'Popular items',
                  onTap: () => setState(() => selected = 'Trending'),
                )),
                const SizedBox(width: 8),
                Expanded(child: _choiceCard(
                  icon: Icons.lightbulb_outline,
                  title: 'Suggestions',
                  subtitle: 'Recommended',
                  onTap: () => setState(() => selected = 'Suggestions'),
                )),
              ]),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => selected = ''),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(selected, style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Products load nahi ho sake.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  final flag = selected == 'Trending' ? 'isTrending' : 'isSuggested';
                  final marked = docs.where((d) => d.data()[flag] == true).toList();
                  final shown = marked.isNotEmpty ? marked : docs;
                  if (shown.isEmpty) {
                    return const Center(child: Text('Abhi products available nahi hain.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final doc = shown[index];
                      final data = doc.data();
                      final name = (data['name'] ?? 'Product').toString();
                      final price = ((data['netRate'] ?? data['price']) as num?)?.toInt() ?? 0;
                      final imageUrl = (data['imageUrl'] ?? '').toString();
                      return Card(
                        child: ListTile(
                          leading: imageUrl.isEmpty
                            ? const Icon(Icons.medication, size: 42)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.medication, size: 42)),
                              ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Rs. $price'),
                          trailing: IconButton(
                            tooltip: 'Add to Cart',
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                            onPressed: () {
                              setState(() {
                                fnsCustomerCart[doc.id] = (fnsCustomerCart[doc.id] ?? 0) + 1;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$name cart mein add ho gaya.')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _choiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.green, size: 25),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }
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

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  void showCustomerBill(BuildContext context, Map<String, dynamic> order) {
    final items = (order['items'] as List?) ?? [];
    final total = ((order['total'] ?? 0) as num).toInt();
    final paid = ((order['paidAmount'] ?? 0) as num).toInt();
    final balance = ((order['balance'] ?? (total - paid)) as num).toInt();
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('FNS TRADERS - INVOICE'),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Image.asset('fns_logo.png', height: 65, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('FNS TRADERS', style: TextStyle(fontWeight: FontWeight.bold)))),
          const Center(child: Text('BABA FALAK NAZ & SONS TRADERS')),
          const Center(child: Text('Plot No. A-46, Sector 8/A, Bilal Colony, K.I.A Karachi', textAlign: TextAlign.center)),
          const Divider(),
          Text('Invoice No: ${order['invoiceNo'] ?? order['orderNo'] ?? '-'}'),
          Text('Date: ${(order['createdAt'] is Timestamp) ? (order['createdAt'] as Timestamp).toDate().toString().substring(0, 16) : '-'}'),
          const Divider(),
          const Text('S.No   Product / Item   Rate   Discount Rate   Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const Divider(),
          for (var i = 0; i < items.length; i++) Builder(builder: (_) {
            final item = Map<String, dynamic>.from(items[i] as Map);
            final rate = ((item['price'] ?? item['rate'] ?? 0) as num).toInt();
            final discountRate = ((item['discountRate'] ?? item['itemDiscount'] ?? 0) as num).toInt();
            final qty = ((item['quantity'] ?? item['qty'] ?? 0) as num).toInt();
            final amount = ((item['amount'] ?? ((rate - discountRate) * qty)) as num).toInt();
            return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ${item['name'] ?? 'Product'}'),
              Text('Rate: Rs. $rate   Discount Rate: Rs. $discountRate   Total: Rs. $amount', style: const TextStyle(fontSize: 11)),
            ]));
          }),
          const Divider(),
          Align(alignment: Alignment.centerRight, child: Text('Grand Total: Rs. $total', style: const TextStyle(fontWeight: FontWeight.bold))),
          Text('Payment: ${order['paymentStatus'] ?? (paid >= total ? 'Paid' : paid > 0 ? 'Partial Paid' : 'Unpaid')}'),
          Text('Paid: Rs. $paid'), Text('Balance: Rs. $balance'),
        ],
      ))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }
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
              final canCancel = status.toString().toLowerCase() == 'pending';

              return Card(
                margin: const EdgeInsets.all(10),
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Order / Invoice ${data['invoiceNo'] ?? data['orderNo'] ?? docs[index].id}'),
                    subtitle: Text(
                      'Status: $status\n'
                      'Items: ${items.length}\n'
                      'Total: Rs. ${data['total'] ?? 0}',
                    ),
                    isThreeLine: true,
                    trailing: canCancel ? TextButton(
                      onPressed: () async {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Order?'),
                          content: const Text('Kya aap ye order cancel karna chahte hain?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel')),
                          ],
                        ),
                      );
                      if (yes != true) return;
                      try {
                        await docs[index].reference.update({
                          'status': 'Cancelled',
                          'cancelledAt': FieldValue.serverTimestamp(),
                          'cancelledBy': 'customer',
                        });
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order cancel ho gaya.')),
                        );
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cancel nahi hua: $e')),
                        );
                      }
                    },
                      child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    ) : Text(status.toString()),
                  ),
                  Align(alignment: Alignment.centerRight, child: TextButton.icon(
                    onPressed: () => showCustomerBill(context, data),
                    icon: const Icon(Icons.receipt_long), label: const Text('View Bill'),
                  )),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}


class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final shopNameC = TextEditingController();
  final addressC = TextEditingController();
  final contactC = TextEditingController();
  bool loading = true;
  bool saving = false;
  String? error;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { loading = false; error = 'Please login again.'; });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers').doc(user.uid).get();
      final data = doc.data() ?? {};
      shopNameC.text = (data['shopName'] ?? '').toString();
      addressC.text = (data['address'] ?? '').toString();
      contactC.text = (data['contact'] ?? '').toString();
      loaded = true;
    } catch (e) {
      error = 'Profile load nahi ho saki: $e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (shopNameC.text.trim().isEmpty ||
        addressC.text.trim().isEmpty ||
        contactC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tamam fields fill karein.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('customers').doc(user.uid).set({
        'shopName': shopNameC.text.trim(),
        'address': addressC.text.trim(),
        'contact': contactC.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile successfully update ho gayi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile save nahi hui: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> changePassword() async {
    final currentC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: currentC, obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password')),
              const SizedBox(height: 10),
              TextField(controller: newC, obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password')),
              const SizedBox(height: 10),
              TextField(controller: confirmC, obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Update')),
        ],
      ),
    );
    if (confirmed == true) {
      final user = FirebaseAuth.instance.currentUser;
      try {
        if (user == null || user.email == null) throw Exception('Please login again.');
        if (newC.text.length < 6) throw Exception('New password kam az kam 6 characters ka ho.');
        if (newC.text != confirmC.text) throw Exception('New passwords match nahi karte.');
        final credential = EmailAuthProvider.credential(
          email: user.email!, password: currentC.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newC.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password successfully change ho gaya.')),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          final message = e.code == 'wrong-password' || e.code == 'invalid-credential'
              ? 'Current password ghalat hai.'
              : (e.message ?? 'Password update nahi ho saka.');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
    currentC.dispose();
    newC.dispose();
    confirmC.dispose();
  }

  @override
  void dispose() {
    shopNameC.dispose();
    addressC.dispose();
    contactC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('Please login to view your profile.'))
              : !loaded
                  ? Center(child: Text(error ?? 'Profile load nahi ho saki.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const CircleAvatar(
                          radius: 38,
                          child: Icon(Icons.person, size: 42),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: shopNameC,
                          decoration: const InputDecoration(
                            labelText: 'Shop Name',
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: contactC,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number (for orders)',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Note: Contact number update hoga; login number change nahi hoga.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: addressC,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Shop Address',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: saving ? null : saveProfile,
                          icon: const Icon(Icons.save),
                          label: Text(saving ? 'Saving...' : 'Save Profile'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: changePassword,
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Change Password'),
                        ),
                        const Divider(height: 30),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Logout'),
                          onTap: () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text('Kya aap logout karna chahte hain?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );
                            if (yes == true) await FirebaseAuth.instance.signOut();
                          },
                        ),
                      ],
                    ),
    );
  }
}
