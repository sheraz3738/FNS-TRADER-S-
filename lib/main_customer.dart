import 'package:flutter/material.dart';
import 'customer_screen.dart';

void main() {
  runApp(const MyAppCustomer());
}

class MyAppCustomer extends StatelessWidget {
  const MyAppCustomer({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FNS Customer',
      home: CustomerScreen(),
    );
  }
}
