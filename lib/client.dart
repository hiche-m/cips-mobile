import 'package:flutter/widgets.dart';

class Client {
  final String name;
  double income;
  double tab;
  String picture;
  DateTime? date;
  DateTime? tabDate;
  int number;

  Client(
    this.name, {
    this.income = 0,
    this.picture = 'assets/icons/Default_PP.png',
    this.tab = 0,
    this.date,
    this.tabDate,
    this.number = 0784397078,
  });
}
