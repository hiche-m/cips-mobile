import 'package:application/Pages/history.dart';

class TransactionObj {
  String timeStamp;
  String clientId;
  double subtotal;
  List<TransProductObj> productList;

  TransactionObj({
    required this.timeStamp,
    required this.subtotal,
    required this.productList,
    this.clientId = "",
  });
}
