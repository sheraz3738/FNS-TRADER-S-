Future<bool> checkLimit(int total) async {
  var doc = await FirebaseFirestore.instance.collection('settings').doc('order_limit').get();
  int limit = doc.data()?['amount'] ?? 0;
  if (limit == 0) return true;
  if (total < limit) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Admin ne $limit Rs ka limit lagaya hai. Apka bill $total Rs hai.")));
    return false;
  }
  return true;
}
