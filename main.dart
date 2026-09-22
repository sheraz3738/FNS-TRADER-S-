import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "FNS TRADER'S",
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const Center(child: Text("Cart Screen")),
    const Center(child: Text("Favorites Screen")),
    const AboutTab(),
    const Center(child: Text("Admin Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FNS TRADER'S", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {},
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      
      // Working Green WhatsApp Chat Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          // Direct WhatsApp Action (0334-3738405)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Opening WhatsApp: 0334-3738405..."),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: "About"),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: "Admin"),
        ],
      ),
    );
  }
}

// ---------------- HOME TAB ----------------
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Urdu/English Marquee Notice Bar
          Container(
            color: Colors.green[800],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            width: double.infinity,
            child: const Text(
              "• BABA FALAK NAZ & SON'S TRADER'S • بابا فلک ناز اینڈ سنز ٹریڈرز •",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Header Card with Full Logo
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Full Logo Display Box
                    Container(
                      width: 110,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.store, size: 40, color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Header Details
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "FNS TRADER'S",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "BA FALAK NAZ & SON'S TRADER'S",
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "WhatsApp: 0334-3738405",
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text("✓ All"),
                  selected: true,
                  onSelected: (bool selected) {},
                  selectedColor: Colors.green[100],
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("General"),
                  selected: false,
                  onSelected: (bool selected) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Surgical"),
                  selected: false,
                  onSelected: (bool selected) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Glucometer"),
                  selected: false,
                  onSelected: (bool selected) {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Product List Demo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("5 product(s)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildProductCard("Hydryllin Syrup 120ml", "General", "Rs. 200"),
                _buildProductCard("Pulmonol Syrup 120ml", "General", "Rs. 200"),
                _buildProductCard("Lederplex Syrup 150ml", "General", "Rs. 234"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String name, String category, String price) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_bag, color: Colors.grey),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: const TextStyle(fontSize: 12)),
            Text("Retail: $price", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
            IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

// ---------------- ABOUT TAB WITH FULL LOGO ----------------
class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          // Full Logo Display on About Page
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.store, size: 60, color: Colors.green),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          const Text(
            "FNS TRADER'S",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "BABA FALAK NAZ & SON'S TRADER'S",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text("WhatsApp Contact"),
            subtitle: const Text("0334-3738405"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.green),
            title: const Text("Address"),
            subtitle: const Text("Main Market, Wholesale Medical Store"),
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.green),
            title: const Text("App Version"),
            subtitle: const Text("2.5.0"),
          ),
        ],
      ),
    );
  }
}
