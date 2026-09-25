import 'package:flutter/material.dart';

void main() => runApp(const FNSApp());

class FNSApp extends StatelessWidget {
  const FNSApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FNS TRADERS',
      theme: ThemeData(primaryColor: const Color(0xFF0D47A1), scaffoldBackgroundColor: const Color(0xFFF5F7FB)),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final pages = [const ShopPage(), const AdminPanelPage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: const Color(0xFF0D47A1),
        onTap: (i)=> setState(()=> _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin Panel'),
        ],
      ),
    );
  }
}

// ============ SHOP PAGE - PURANA WALA ============
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}
class _ShopPageState extends State<ShopPage> {
  String selectedCat = 'All';
  final categories = ['All', 'General', 'Syrup', 'Tablet', 'Glucometer', 'Surgical', 'General Items'];
  final products = [
    {'name':'Hydryllin Syrup','cat':'Syrup','price':'185'},
    {'name':'Pulmonol Syrup','cat':'Syrup','price':'195'},
    {'name':'Gravinate','cat':'Tablet','price':'120'},
    {'name':'Arinac Forte','cat':'Tablet','price':'250'},
    {'name':'Glucometer','cat':'Glucometer','price':'2500'},
    {'name':'Surgical Gloves','cat':'Surgical','price':'400'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCat=='All'? products : products.where((p)=>p['cat']==selectedCat).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(backgroundColor: const Color(0xFF0D47A1), centerTitle: true, title: const Text('FNS TRADERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _topCard('General Order','12 Items', Icons.shopping_cart, Colors.orange)),
                const SizedBox(width:10),
                Expanded(child: _topCard('Status','Pending: 2', Icons.pending_actions, Colors.green)),
              ],
            ),
          ),
          SizedBox(height:45, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:12), itemCount: categories.length, itemBuilder: (c,i){
            final cat = categories[i];
            final sel = selectedCat==cat;
            return GestureDetector(onTap: ()=>setState(()=>selectedCat=cat), child: Container(margin: const EdgeInsets.only(right:8), padding: const EdgeInsets.symmetric(horizontal:18, vertical:10), decoration: BoxDecoration(color: sel? const Color(0xFF0D47A1):Colors.white, borderRadius: BorderRadius.circular(20)), child: Text(cat, style: TextStyle(color: sel?Colors.white:Colors.black87, fontWeight: FontWeight.bold, fontSize:12))));
          })),
          Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: filtered.length, itemBuilder: (c,i){
            final p = filtered[i];
            return Container(margin: const EdgeInsets.only(bottom:10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.medication, color: Color(0xFF0D47A1))), title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:14)), subtitle: Text(p['cat']!, style: const TextStyle(fontSize:11)), trailing: Text('Rs. ${p['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)))));
          })),
        ],
      ),
    );
  }
  Widget _topCard(String t, String s, IconData ic, Color col){
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(ic, color: col, size:20)), const SizedBox(width:10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12)), Text(s, style: const TextStyle(fontSize:11, color: Colors.grey))])]));
  }
}

// ============ ADMIN PANEL - JO AAPKO CHAHIYE ============
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(backgroundColor: const Color(0xFF0D47A1), title: const Text('Admin Panel - FNS TRADERS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Admin Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _adminTile(Icons.add_box, 'Add New Product', 'Syrup, Tablet add karein', Colors.blue),
          _adminTile(Icons.list_alt, 'General Orders', 'Saare orders dekhein', Colors.orange),
          _adminTile(Icons.inventory, 'General Items', 'General items manage karein', Colors.green),
          _adminTile(Icons.category, 'Manage Categories', 'Syrup, Tablet, Glucometer categories', Colors.purple),
          _adminTile(Icons.medication_liquid, 'Syrup Stock', 'Syrup ka stock check', Colors.teal),
          _adminTile(Icons.medication, 'Tablet Stock', 'Tablet ka stock check', Colors.indigo),
          _adminTile(Icons.bloodtype, 'Glucometer Items', 'Glucometer aur strips', Colors.red),
          _adminTile(Icons.local_shipping, 'Order Status', 'Pending / Delivered status', Colors.brown),
          _adminTile(Icons.settings, 'Settings', 'Admin settings', Colors.grey),
          const SizedBox(height: 20),
          SizedBox(height: 50, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: (){}, icon: const Icon(Icons.logout, color: Colors.white), label: const Text('Logout Admin', style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }
  static Widget _adminTile(IconData icon, String title, String sub, Color col){
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)]),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: col)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}
