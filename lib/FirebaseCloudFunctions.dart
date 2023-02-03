import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

Future<String> getUrl(String url) {
  const String _default = "Default_PP.png";

  return url.isEmpty
      ? firebase_storage.FirebaseStorage.instance
          .refFromURL("gs://cips-mobile.appspot.com/")
          .child("Profiles")
          .child(_default)
          .getDownloadURL()
      : firebase_storage.FirebaseStorage.instance
          .refFromURL("gs://cips-mobile.appspot.com/")
          .child("Profiles")
          .child(url)
          .getDownloadURL();
}

Future<String> getProductUrl(String url) {
  return firebase_storage.FirebaseStorage.instance
      .refFromURL("gs://cips-mobile.appspot.com/")
      .child("Profiles")
      .child(url)
      .getDownloadURL();
}
