import 'dart:io';
import 'package:application/Pages/Notifications.dart';
import 'package:application/Pages/admin.dart';
import 'package:application/Pages/appSettings.dart';
import 'package:application/Pages/loading.dart';
import 'package:application/Pages/stock.dart';
import 'package:application/TextFormulations.dart';
import 'package:application/clearSession.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:application/FirebaseCloudFunctions.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:image_picker/image_picker.dart';

class More extends StatefulWidget {
  More({Key? key, required this.instance, required this.data})
      : super(key: key);

  FirebaseAuth instance;
  Map data;

  @override
  State<More> createState() => _MoreState(instance: instance, data: data);
}

class SettingsItem {
  String title;
  String body;
  IconData icon;
  Widget action;

  SettingsItem(
      {required this.title,
      required this.body,
      required this.icon,
      required this.action});
}

class _MoreState extends State<More> with AutomaticKeepAliveClientMixin<More> {
  _MoreState({required this.instance, required this.data});

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    routes = [
      Administration(data: data),
      const Stock(),
      const AppSettings(),
      const Notif()
    ];
    super.initState();
  }

  late List routes;
  /*                                                                            State Widget (Variable declaration)*/
  FirebaseAuth instance;
  CollectionReference user = FirebaseFirestore.instance.collection("users");

  late var settings = <SettingsItem>[
    SettingsItem(
        title: data["isAdmin"] ? "Account Management" : "Account Settings",
        body: "${instance.currentUser!.email}",
        icon: Icons.person_outlined,
        action: Container()),
    SettingsItem(
        title: "Stock Management",
        body: !data["isAdmin"] ? data['post'] : "Administrator",
        icon: Icons.account_balance_outlined,
        action: Container()),
    SettingsItem(
        title: "App Settings",
        body: "CIPS Mobile 1.0",
        icon: Icons.app_settings_alt_outlined,
        action: Container()),
    SettingsItem(
        title: "Notification Settings",
        body: "Notifications On",
        icon: Icons.edit_notifications_outlined,
        action: Container()),
  ];
  File? _profilePicture;
  Map data;

  late double height;
  late double width;

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> dataStream = user.snapshots();
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    final scale = MediaQuery.of(context).textScaleFactor;
    bool isAdmin = data["isAdmin"];
    int role;
    if (!isAdmin) {
      if (data["post"] == "Manager") {
        role = 2;
      } else if (data["post"] == "Seller") {
        role = 3;
      } else {
        role = 0;
      }
    } else {
      role = 1;
    }
    super.build(context);
    return StreamBuilder(
      stream: dataStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            data.isEmpty) {
          return Center(
            child: PlatformCircularProgressIndicator(
              material: (_, __) => MaterialProgressIndicatorData(
                  color: Colors.tealAccent[400], strokeWidth: 1.0),
            ),
          );
        } else if (snapshot.hasError || role == 0) {
          return Align(
            alignment: Alignment.center,
            child: Text(
              "An error has occured, please check your internet connection.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.0 * scale,
                fontFamily: 'Mukta',
              ),
            ),
          );
        }
        final List userData = [];
        snapshot.data!.docs.map((DocumentSnapshot document) {
          Map e = document.data() as Map<String, dynamic>;
          if (document.id == instance.currentUser!.uid) {
            userData.add(e);
          }
          e['id'] = document.id;
        }).toList();

        late final userDataInstance = userData[0];

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch(
              accentColor: Colors.grey,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[50]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /*                                                                Background Color*/
                      Container(
                        height: (height / 7) * 1.5 >= 140
                            ? (height / 7) * 1.5
                            : 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal[400]!, Colors.teal[700]!],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            /*                                                          Profile Picture*/
                            GestureDetector(
                              onTap: !kIsWeb
                                  ? () async {
                                      final source =
                                          await showOptionsMenu(context);
                                      source != null
                                          ? await getImage(source)
                                          : ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                              backgroundColor:
                                                  Colors.blueGrey[900],
                                              dismissDirection:
                                                  DismissDirection.up,
                                              content: const Text(
                                                  "WARNING: No image was picked."),
                                            ));
                                      await uploadProfileToStorage(
                                          instance.currentUser!, context);
                                      print(_profilePicture);
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 22.5),
                                child: Stack(
                                  children: [
                                    /*                                                      Image*/
                                    StreamBuilder<String>(
                                      stream: getUrl(userDataInstance[
                                              'profilePicture'])
                                          .asStream(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: SizedBox(
                                              height: 20.0 / height,
                                              width: 20.0 / height,
                                              child:
                                                  PlatformCircularProgressIndicator(
                                                material: (_, __) =>
                                                    MaterialProgressIndicatorData(
                                                        color: Colors.grey[600],
                                                        strokeWidth: 1.0),
                                              ),
                                            ),
                                          );
                                        } else if (snapshot.hasError) {
                                          print("Error");
                                        }

                                        return CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 50,
                                          child: CircleAvatar(
                                            radius: 48,
                                            backgroundColor: Colors.grey[200],
                                            backgroundImage: Image.network(
                                                    snapshot.data.toString())
                                                .image,
                                          ),
                                        );
                                      },
                                    ),
                                    /*                                                      Edit button*/
                                    !kIsWeb
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                top: 70.0, left: 45.0),
                                            child: RaisedButton(
                                              onPressed: () async {
                                                final source =
                                                    await showOptionsMenu(
                                                        context);
                                                source != null
                                                    ? await getImage(source)
                                                    : ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                        backgroundColor: Colors
                                                            .blueGrey[900],
                                                        dismissDirection:
                                                            DismissDirection.up,
                                                        content: const Text(
                                                            "WARNING: No image was picked."),
                                                      ));
                                                await uploadProfileToStorage(
                                                    instance.currentUser!,
                                                    context);
                                                print(_profilePicture);
                                              },
                                              shape: const CircleBorder(),
                                              elevation: 1.0,
                                              child: Icon(
                                                Icons.edit_outlined,
                                                size: 12.5 * scale,
                                                color: Colors.teal,
                                              ),
                                              color: Colors.white,
                                            ),
                                          )
                                        : SizedBox(
                                            height: 12.5 * scale,
                                            width: 12.5 * scale,
                                          ),
                                  ],
                                ),
                              ),
                            ),
                            /*                                                      Welcome name,*/
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Welcome " +
                                          firstWordWithNoSpaces(
                                              userDataInstance['firstName']) +
                                          ",",
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Mukta',
                                          fontSize: 22.5 * scale,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    /*                                                Company Name*/
                                    Text(
                                      userDataInstance['companyName'],
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Mukta',
                                        fontSize: 17.5 * scale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      /*                                                            Settings*/
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            height: height / 7 >= 90 ? height / 7 : 90,
                            child: Card(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15.0),
                                child: ListTile(
                                  onTap: index == 1
                                      ? role == 1 ||
                                              role == 2 &&
                                                  data["ownerEmail"]
                                                      .toString()
                                                      .isNotEmpty
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        routes[index]),
                                              );
                                            }
                                          : null
                                      : () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      routes[index]));
                                        },
                                  title: Text(
                                    "  " + settings[index].title,
                                    style: TextStyle(
                                        fontFamily: 'Mukta',
                                        fontSize: 15.0,
                                        color: Colors.grey),
                                  ),
                                  leading: Icon(
                                    settings[index].icon,
                                    color: index == 1
                                        ? role != 3
                                            ? Colors.grey[900]
                                            : Colors.grey
                                        : Colors.grey[900],
                                    size: 35.0 * scale,
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 17.5,
                                    color: Colors.grey,
                                  ),
                                  subtitle: Text(
                                    "  " + settings[index].body,
                                    softWrap: false,
                                    overflow: TextOverflow.fade,
                                    style: TextStyle(
                                        fontFamily: 'Titillium Web',
                                        fontSize: 17.5 * scale,
                                        fontWeight: FontWeight.bold,
                                        color: index == 1
                                            ? role != 3
                                                ? Colors.grey[800]
                                                : Colors.grey
                                            : Colors.grey[800]),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50.0),
                        child: Container(
                          height: 55.0,
                          child: ElevatedButton(
                            onPressed: () async {
                              /* 
                              newSession();
                              await user.doc(instance.currentUser!.uid).update({
                                'token': "",
                              }); */
                              logOutFromAccount();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Disconnect",
                                  style: TextStyle(
                                    fontFamily: 'Titillium Web',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.blueGrey[900]!),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  //side: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.0),
                      /*                                                                Log out button*/
                      Text("Disconnect from your account",
                          style: TextStyle(
                              fontFamily: 'Titillium Web',
                              fontSize: 12.5 * scale,
                              color: Colors.red)),
                      SizedBox(height: (height / 7) - 10),
                    ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<ImageSource?> showOptionsMenu(BuildContext context) async {
    if (Platform.isIOS) {
      return showCupertinoModalPopup<ImageSource>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: const Text(
                "Camera",
                style: TextStyle(fontFamily: 'Mukta'),
              ),
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            CupertinoActionSheetAction(
              child: const Text(
                "Gallery",
                style: TextStyle(fontFamily: 'Mukta'),
              ),
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      );
    } else if (Platform.isAndroid) {
      return showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text(
                "Camera",
                style: TextStyle(fontFamily: 'Mukta'),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text(
                "Gallery",
                style: TextStyle(fontFamily: 'Mukta'),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.blueGrey[900],
        dismissDirection: DismissDirection.up,
        content: const Text("This function is not supported in Web."),
      ));
    }
  }

  Future getImage(ImageSource source) async {
    var image = await ImagePicker().pickImage(source: source);

    if (image != null) {
      _profilePicture = await compressImg(image: File(image.path));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Uploading file...')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image failed to upload')));
    }
  }

  Future<File> compressImg(
      {required File image, quality = 100, percentage = 25}) async {
    var path = FlutterNativeImage.compressImage(image.absolute.path,
        quality: quality, percentage: percentage);
    return path;
  }

  Future uploadProfileToStorage(User user, context) async {
    final userID = user.uid;
    final String path = "$userID/profile_picture";

    await FirebaseStorage.instance
        .refFromURL("gs://cips-mobile.appspot.com/")
        .child("Profiles")
        .child(path)
        .putFile(_profilePicture!);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .update({'profilePicture': path});

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image will change in an instant.')));
  }

  Future logOutFromAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SpinKitCubeGrid(
        color: Colors.white,
        size: 35.0,
      ),
    );
    try {
      await instance.signOut();
    } on FirebaseAuthException catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message!),
      ));
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacementNamed("/auth");
    }
  }
}
