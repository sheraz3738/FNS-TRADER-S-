import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> allProducts = []; // FIXED

  var nameCtrl = TextEditingController();
  var priceCtrl = TextEditingController();
  var stockCtrl = TextEditingController();

  void addProduct() {
    if (nameCtrl.text.isNotEmpty) {
      setState(() {
        allProducts.add({
          'name': nameCtrl.text,
          'price': priceCtrl.text,
          'stock': int.tryParse(stockCtrl.text)?? 10,
          'isAvailable': true,
        });
      });
      nameCtrl.clear();
      priceCtrl.clear();
      stockCtrl.clear();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ایڈمن پینل"), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF0D47A1),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showDialog(context: context, builder: (ctx) => AlertDialog(
            title: Text("نیا پروڈکٹ"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: priceCtrl, decoration: InputDecoration(labelText: "Price")),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Stock")),
            ]),
            actions: [ElevatedButton(onPressed: addProduct, child: Text("Add"))],
          ));
        },
      ),
      body: ListView.builder(
        itemCount: allProducts.length,
        itemBuilder: (c, i) {
          var p = allProducts[i];
          return Card(
            child: ListTile(
              title: Text(p['name']),
              subtitle: Text("Price: ${p['price']} | Stock: ${p['stock']}"),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(value: p['isAvailable'], onChanged: (val) {
                  setState(()=> allProducts[i]['isAvailable']=val);
                }),
                IconButton(icon: Icon(Icons.edit), onPressed: (){
                  var stockCtrl2 = TextEditingController();
                  showDialog(context: context, builder: (ctx)=> AlertDialog(title: Text("اسٹاک Add کریں"), content: TextField(controller: stockCtrl2, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "نیا اسٹاک")), actions: [ElevatedButton(onPressed: (){ setState(()=> allProducts[i]['stock']= int.tryParse(stockCtrl2.text)?? p['stock']); Navigator.pop(ctx); }, child: Text("Save"))]));
                }),
                IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: ()=> setState(()=> allProducts.removeAt(i))),
              ]),
            ),
          );
        },
      ),
    );
  }
}
