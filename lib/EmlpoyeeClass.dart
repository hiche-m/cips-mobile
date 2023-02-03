class Employee {
  String addTime;
  String fullName;
  String post;
  String email;
  Employee(
      {required this.addTime,
      required this.post,
      required this.email,
      this.fullName = ""});
}
