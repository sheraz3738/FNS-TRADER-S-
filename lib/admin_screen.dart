import 'package:flutter/material.dart';
import 'main.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _addProductDialog(){
    var nameCtrl = TextEditingController();
    var priceCtrl = TextEditingController();
    var stockCtrl = TextEditingController();
    var imageCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx)=> AlertDialog(
      title: Text("نیا پروڈکٹ Add کریں"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "پروڈکٹ کا نام")),
        TextField(controller: priceCtrl, decoration: InputDecoration(labelText: "قیمت"), keyboardType: TextInputType.number),
        TextField(controller: stockCtrl, decoration: InputDecoration(labelText: "اسٹاک تعداد"), keyboardType: TextInputType.number),
        TextField(controller: imageCtrl, decoration: InputDecoration(labelText: "تصویر کا لنک (Image URL) - خالی بھی چھوڑ سکتے ہیں", hintText: "https://...")),
        SizedBox(height: 10),
        Text("نوٹ: موبائل سے تصویر لگانی ہے تو URL پیسٹ کریں یا گیلری سے بعد میں لگا سکتے ہیں", style: TextStyle(fontSize: 11, color: Colors.grey)),
      ])),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: Text("Cancel")),
        ElevatedButton(onPressed: (){
          setState(() {
            allProducts.add({
              "name": nameCtrl.text,
              "price": int.tryParse(priceCtrl.text)?? 0,
              "stock": int.tryParse(stockCtrl.text)?? 0,
              "isAvailable": true,
              "image": imageCtrl.text,
            });
          });
          Navigator.pop(ctx);
        }, child: Text("Add کریں")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FNS Admin Panel"),
        backgroundColor: Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        bottom: TabBar(controller: _tabController, tabs: [
          Tab(text: "پروڈکٹس / Products", icon: Icon(Icons.inventory)),
          Tab(text: "آرڈرز / Orders", icon: Icon(Icons.receipt_long)),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // پہلا ٹیب: پروڈکٹس
          Column(
            children: [
              Padding(padding: EdgeInsets.all(10), child: ElevatedButton.icon(icon: Icon(Icons.add), label: Text("نیا پروڈکٹ Add کریں + تصویر"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 50)), onPressed: _addProductDialog)),
              Expanded(child: ListView.builder(
                itemCount: allProducts.length,
                itemBuilder: (context, i){
                  var p = allProducts[i];
                  return Card(margin: EdgeInsets.all(8), child: ListTile(
                    leading: p['image']!=""? Image.network(p['image'], width: 50, errorBuilder: (c,e,s)=> Icon(Icons.broken_image)) : Icon(Icons.image, size: 40),
                    title: Text(p['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Price: ${p['price']} | Stock: ${p['stock']}"),
                      Row(children: [
                        Text("اسٹاک: "),
                        Switch(value: p['isAvailable'], onChanged: (val){
                          setState(()=> allProducts[i]['isAvailable']=val);
                        }),
                        Text(p['isAvailable']? "ON":"OFF", style: TextStyle(color: p['isAvailable']? Colors.green: Colors.red, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: (){
                        var stockCtrl = TextEditingController(text: p['stock'].toString());
                        showDialog(context: context, builder: (ctx)=> AlertDialog(title: Text("اسٹاک Add کریں"), content: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "نیا اسٹاک")), actions: [ElevatedButton(onPressed: (){ setState(()=> allProducts[i]['stock']= int.tryParse(stockCtrl.text)?? p['stock']); Navigator.pop(ctx); }, child: Text("Save"))]));
                      }),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: ()=> setState(()=> allProducts.removeAt(i))),
                    ]),
                  ));
                },
              )),
            ],
          ),
          // دوسرا ٹیب: آرڈرز
          Center(child: Text("آرڈرز یہاں نظر آئیں گے\nجب کسٹمر آرڈر کرے گا تو یہاں لسٹ آئے گی", textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
