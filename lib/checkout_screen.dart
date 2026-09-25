import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'print_service.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  var nameCtrl = TextEditingController();
  var storeCtrl = TextEditingController();
  var mobileCtrl = TextEditingController();
  var addressCtrl = TextEditingController();
  String deliveryTime = "Same Day";
  String orderStatus = "Pending";

  void submit(String type){
    if(_formKey.currentState!.validate()){
      var data = {
        'orderNo': "FNS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
        'customerName': nameCtrl.text,
        'storeName': storeCtrl.text,
        'mobile': mobileCtrl.text,
        'address': addressCtrl.text,
        'deliveryTime': deliveryTime,
        'status': orderStatus,
        'date': DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
      };
      if(type=="A4") PrintService.printA4Bill(data);
      else PrintService.printThermalBill(context, data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("کسٹمر کی تفصیل"), backgroundColor: Color(0xFF0D47A1), foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(controller: nameCtrl, decoration: InputDecoration(labelText: "Customer Name *", border: OutlineInputBorder()), validator: (v)=> v!.isEmpty? "ضروری ہے":null),
            SizedBox(height: 10),
            TextFormField(controller: storeCtrl, decoration: InputDecoration(labelText: "Store Name *", border: OutlineInputBorder()), validator: (v)=> v!.isEmpty? "ضروری ہے":null),
            SizedBox(height: 10),
            TextFormField(controller: mobileCtrl, decoration: InputDecoration(labelText: "Phone Number *", border: OutlineInputBorder()), validator: (v)=> v!.isEmpty? "ضروری ہے":null),
            SizedBox(height: 10),
            TextFormField(controller: addressCtrl, maxLines: 3, decoration: InputDecoration(labelText: "Full Address *", border: OutlineInputBorder()), validator: (v)=> v!.isEmpty? "ضروری ہے":null),
            SizedBox(height: 20),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 55)), onPressed: ()=> submit("A4"), child: Text("A4 پرنٹ", style: TextStyle(color: Colors.white))),
            SizedBox(height: 10),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0D47A1), minimumSize: Size(double.infinity, 55)), onPressed: ()=> submit("Thermal"), child: Text("Thermal پرنٹ", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
