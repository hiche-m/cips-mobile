class Product {
  String id;
  String title;
  int quantity;
  double price;
  String? imgUrl;

  Product({
    required this.id,
    required this.title,
    required this.quantity,
    required this.price,
    this.imgUrl = "None.jpg",
  });
}
