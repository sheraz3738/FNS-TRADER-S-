import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'admin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(const FnsAdminApp());
  } catch (e) {
    runApp(AdminStartupError(error: e.toString()));
  }
}

class AdminStartupError extends StatelessWidget {
  final String error;
  const AdminStartupError({super.key, required this.error});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('FNS TRADERS Admin')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 56),
              const Text('App startup error', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Firebase start nahi ho saka. Neeche error likha hai:'),
              const SizedBox(height: 12),
              SelectableText(error),
            ],
          ),
        ),
      ),
    ),
  );
}

class FnsAdminApp extends StatelessWidget {
  const FnsAdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FNS TRADERS Admin',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
    home: const AdminAuthGate(),
  );
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasData) return AdminScreen();
      return const AdminLoginScreen();
    },
  );
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String error = '';

  Future<void> login() async {
    setState(() { loading = true; error = ''; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.code == 'invalid-credential'
        ? 'Email ya password durust nahi.' : (e.message ?? 'Login nahi ho saka.'));
    } catch (_) {
      if (mounted) setState(() => error = 'Login nahi ho saka. Dobara koshish karein.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('FNS TRADERS — Admin')),
    body: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.admin_panel_settings, size: 76),
          const Text('ADMIN LOGIN', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            onSubmitted: (_) { if (!loading) login(); }),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12), Text(error, style: const TextStyle(color: Colors.red))],
          const SizedBox(height: 16),
          FilledButton(onPressed: loading ? null : login,
            child: loading ? const CircularProgressIndicator() : const Text('LOGIN')),
        ]),
      ),
    )),
  );
}
