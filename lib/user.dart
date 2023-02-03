class UserClass {
  String firstName;
  String lastName;
  String company;
  String profilePicture;

  UserClass(
      {required this.firstName,
      required this.lastName,
      required this.company,
      this.profilePicture = "assets/icons/Default_PP.png"});

  static UserClass fromJson(Map<String, dynamic> json) => UserClass(
        firstName: json['firstName'],
        lastName: json['lastName'],
        company: json['company'],
        profilePicture: json['profilePicture'],
      );
}
