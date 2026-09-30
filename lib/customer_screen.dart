import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerScreen extends StatefulWidget {
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  String search = "";
  int currentIndex = 0;
  String selectedCat = "All";
  List<String> cats = ["All", "Syrup", "Tablet", "Surgical", "General Item", "BP Operator", "Glucometer", "Other"];
  Map<String, int> cart = {};
  Map<String, Map> cartData = {};

  int get totalAmount {
    int t = 0;
    cart.forEach((id, qty){ int price = int.tryParse(cartData[id]?['price']??'0')??0; t += price * qty; });
    return t;
  }

  void openWhatsApp() async {
    final Uri url = Uri.parse("https://wa.me/923343738405?text=Assalam o Alaikum FNS Traders, help chahiye");
    if(await canLaunchUrl(url)){ await launchUrl(url, mode: LaunchMode.externalApplication); }
  }

  void openAIChat(){
    TextEditingController aiCtrl = TextEditingController();
    List<Map> msgs = [{"isUser": false, "text": "السلام علیکم! میں FNS AI ہوں۔ BP Operator, Tablet, Syrup کے بارے میں پوچھیں؟"}];
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c){
      return StatefulBuilder(builder: (ctx, setS){
        return Container(height: MediaQuery.of(context).size.height*0.85, padding: EdgeInsets.all(12), child: Column(children: [
          Row(children: [Icon(Icons.smart_toy, color: Color(0xFF0D47A1)), SizedBox(width:8), Text("FNS AI Assistant", style: TextStyle(fontWeight: FontWeight.bold, fontSize:18)), Spacer(), IconButton(icon: Icon(Icons.close), onPressed: ()=> Navigator.pop(context))]),
          Divider(),
          Expanded(child: ListView.builder(itemCount: msgs.length, itemBuilder: (c,i){
            bool isUser = msgs[i]['isUser'];
            return Align(alignment: isUser? Alignment.centerRight: Alignment.centerLeft, child: Container(margin: EdgeInsets.symmetric(vertical:4), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: isUser? Color(0xFF0D47A1): Colors.grey[200], borderRadius: BorderRadius.circular(15)), child: Text(msgs[i]['text'], style: TextStyle(color: isUser? Colors.white: Colors.black))));
          })),
          Row(children: [
            Expanded(child: TextField(controller: aiCtrl, decoration: InputDecoration(hintText: "سوال لکھیں...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))))),
            SizedBox(width:8),
            FloatingActionButton(mini: true, backgroundColor: Color(0xFF0D47A1), onPressed: (){
              if(aiCtrl.text.isEmpty) return;
              String q = aiCtrl.text.toLowerCase();
              String ans = "اس کے لیے براہ کرم واٹس ایپ پر رابطہ کریں 0334-3738405";
              if(q.contains("bp")) ans = "BP Operator کیٹیگری میں BP مشینیں ہیں۔ Category میں BP Operator select کریں۔";
              else if(q.contains("bukhar") || q.contains("fever")) ans = "بخار کے لیے Panadol, Brufen استعمال ہوتی ہے۔ ڈاکٹر سے مشورہ کریں۔";
              setS((){ msgs.add({"isUser": true, "text": aiCtrl.text}); msgs.add({"isUser": false, "text": ans}); aiCtrl.clear(); });
            }, child: Icon(Icons.send, color: Colors.white))
          ])
        ]));
      });
    });
  }

  Widget buildHome(){
    return Column(children: [
      Container(width: double.infinity, color: Color(0xFF0D47A1), height: 35, child: Center(child: Text(" WELCOME TO FNS TRADERS | بابا فلک ناز | 0334-3738405 ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      Container(color: Colors.white, width: double.infinity, padding: EdgeInsets.all(8), child: Column(children: [Image.asset('fns_logo.png', height: 70, errorBuilder: (c,e,s)=> Icon(Icons.store, size: 40, color: Color(0xFF0D47A1))), Text("بابا فلک ناز اینڈ سنز ٹریڈرز", style: TextStyle(fontWeight: FontWeight.bold))])),
      Container(width: double.infinity, color: Colors.green[700], padding: EdgeInsets.all(6), child: Text("مَا شَاءَ اللهُ لَا قُوَّةَ إِلَّا بِاللَّهِ", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      Padding(padding: EdgeInsets.all(8), child: TextField(onChanged: (v)=> setState(()=> search=v.toLowerCase()), decoration: InputDecoration(hintText: "Search... تلاش کریں", prefixIcon: Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
      Container(height: 45, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: cats.length, itemBuilder: (c,i)=> Padding(padding: EdgeInsets.symmetric(horizontal:4), child: ChoiceChip(label: Text(cats[i]), selected: selectedCat==cats[i], onSelected: (v)=> setState(()=> selectedCat=cats[i]), selectedColor: Color(0xFF0D47A1), labelStyle: TextStyle(color: selectedCat==cats[i]?Colors.white:Colors.black))))),
      Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(), builder: (context, snap){
        if(!snap.hasData) return Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs.where((d){ var data=d.data() as Map; var cat=(data['category']??'').toString(); var name=(data['name']??'').toString().toLowerCase(); return (selectedCat=="All"||cat==selectedCat) && (search.isEmpty||name.contains(search)); }).toList();
        if(docs.isEmpty) return Center(child: Text("کوئی پروڈکٹ نہیں"));
        return GridView.builder(padding: EdgeInsets.all(8), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: docs.length, itemBuilder: (c,i){
          var data=docs[i].data() as Map; String id=docs[i].id;
          return Card(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Column(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(12)), child: (data['image']??'').toString().isNotEmpty? Image.network(data['image'], width: double.infinity, fit: BoxFit.cover): Icon(Icons.medical_services, size: 40))),
            Padding(padding: EdgeInsets.all(6), child: Column(children: [
              Text(data['name']??'', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(data['category']??'', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("Rs.${data['price']}", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
              SizedBox(height: 4),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){ setState((){ cart[id] = (cart[id]??0)+1; cartData[id]=data; }); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: EdgeInsets.symmetric(vertical: 4)), child: Text("Add to Cart", style: TextStyle(color: Colors.white, fontSize: 11))))
            ]))
          ]));
        });
      }))
    ]);
  }

  Widget buildCart(){
    if(cart.isEmpty) return Center(child: Text("Cart Empty - کارٹ خالی ہے"));
    return Column(children: [
      AppBar(title: Text("My Cart - Rs.$totalAmount"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      Expanded(child: ListView(children: cart.entries.map((e){
        var id=e.key; var qty=e.value; var data=cartData[id]!;
        return Card(child: ListTile(leading: (data['image']??'').toString().isNotEmpty? Image.network(data['image'], width: 50): Icon(Icons.medical_services), title: Text(data['name']??''), subtitle: Text("Rs.${data['price']} x $qty = Rs.${int.parse(data['price'])*qty}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(Icons.remove), onPressed: (){ setState((){ if(qty>1) cart[id]=qty-1; else { cart.remove(id); cartData.remove(id);} }); }), Text(qty.toString()), IconButton(icon: Icon(Icons.add), onPressed: (){ setState(()=> cart[id]=qty+1); })])));
      }).toList())),
      Padding(padding: EdgeInsets.all(12), child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { await FirebaseFirestore.instance.collection('orders').add({"items": cart.entries.map((e)=> {"name": cartData[e.key]!['name'], "qty": e.value, "price": cartData[e.key]!['price']}).toList(), "total": totalAmount, "createdAt": FieldValue.serverTimestamp()}); setState((){ cart.clear(); cartData.clear(); }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order Placed!"))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: EdgeInsets.symmetric(vertical: 16)), child: Text("Slide For Processing - Rs.$totalAmount", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
      SizedBox(height: 10),
    ]);
  }

  Widget buildAccount(){
    TextEditingController nameCtrl = TextEditingController(text: "FNS Customer");
    TextEditingController phoneCtrl = TextEditingController(text: "0334-3738405");
    return SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      CircleAvatar(radius: 45, backgroundColor: Color(0xFF0D47A1), child: Icon(Icons.person, size: 45, color: Colors.white)),
      SizedBox(height: 12),
      Text("میرا اکاؤنٹ - My Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 20),
      Container(width: double.infinity, padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]), child: Column(children: [
        ListTile(leading: Icon(Icons.badge, color: Color(0xFF0D47A1)), title: Text("Customer ID"), subtitle: Text("FNS-${DateTime.now().year}-001", style: TextStyle(fontWeight: FontWeight.bold)), trailing: Icon(Icons.copy)),
        Divider(),
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "نام / Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        SizedBox(height: 12),
        TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: "فون نمبر / Phone ID", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile Updated - ID آگے پیچھے ہو گئی"))); }, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1)), child: Text("Update - اپڈیٹ کریں", style: TextStyle(color: Colors.white)))),
      ])),
      SizedBox(height: 20),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: openWhatsApp, icon: Icon(Icons.chat, color: Colors.white), label: Text("WhatsApp", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: EdgeInsets.symmetric(vertical: 15)))),
        SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(onPressed: openAIChat, icon: Icon(Icons.smart_toy, color: Colors.white), label: Text("AI Help", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), padding: EdgeInsets.symmetric(vertical: 15)))),
      ])
    ]));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [buildHome(), buildCart(), buildAccount()];
    return Scaffold(
      body: SafeArea(child: pages[currentIndex]),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(heroTag: "ai", backgroundColor: Color(0xFF0D47A1), onPressed: openAIChat, child: Icon(Icons.smart_toy, color: Colors.white)),
        SizedBox(height: 10),
        FloatingActionButton(heroTag: "wa", backgroundColor: Colors.green[700], onPressed: openWhatsApp, child: Icon(Icons.chat, color: Colors.white)),
      ]),
      bottomNavigationBar: BottomNavigationBar(currentIndex: currentIndex, onTap: (i)=> setState(()=> currentIndex=i), selectedItemColor: Color(0xFF0D47A1), items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
      ]),
    );
  }
}
