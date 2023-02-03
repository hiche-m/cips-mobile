class ProductObj {
  int id;
  String title;
  double price;
  double quantity;
  String picture;
  double selection;
  double minQuantity;
  bool isCountable;

  ProductObj(
      {required this.id,
      required this.title,
      required this.price,
      required this.quantity,
      required this.isCountable,
      this.picture = "None.jpg",
      this.selection = 0,
      this.minQuantity = 0});
}
