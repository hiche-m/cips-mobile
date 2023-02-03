import 'package:cloud_firestore/cloud_firestore.dart';

class userDatabase {
  final userID;
  userDatabase({required this.userID});

  Future updateUserData(String firstName, String lastName, String company,
      String picture, bool isAdmin, String email, String post) async {
    final userCollection =
        FirebaseFirestore.instance.collection('users').doc(userID);

    final json = {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'companyName': company.isEmpty ? "CIPS Mobile" : company,
      'profilePicture': picture,
      'isAdmin': isAdmin,
      'ownerEmail': "",
      'post': post.isEmpty ? "Seller" : post,
    };

    await userCollection.set(json);
  }
}
