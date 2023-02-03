import 'dart:async';
import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:application/Pages/clients.dart';
import 'package:application/Pages/history.dart';
import 'package:application/Pages/loading.dart';
import 'package:application/Pages/menu.dart';
import 'package:application/Pages/more.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class Home extends StatefulWidget {
  Home({Key? key, required this.instance}) : super(key: key);
  FirebaseAuth instance;
  @override
  State<Home> createState() => _HomeState(instance: instance);
}

var pageController;
StreamController<String> barcodeStreamController =
    StreamController<String>.broadcast();
Stream<String> get barcodeStream => barcodeStreamController.stream;
Future<void> closeStream() => barcodeStreamController.close();

int defaultPage = 0;

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  int _currentIndex = defaultPage;
  bool? isAdmin;
  Map data = {};
  late AndroidNotificationChannel channel;
  late double scale;
  late double width;
  late double height;

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  final CollectionReference user =
      FirebaseFirestore.instance.collection("users");
  _HomeState({required this.instance});
  FirebaseAuth instance;
  String? deviceToken;
  late FirebaseMessaging messaging;

  scanBarcode(String barcode) {
    _currentIndex != 0
        ? pageController.animateToPage(0,
            duration: const Duration(milliseconds: 75), curve: Curves.ease)
        : null;
    barcodeStreamController.sink.add(barcode);
  }

  Future<void> getPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  @override
  initState() {
    getData();

    super.initState();

    getPermission();

    loadFCM();

    listenFCM();

    //FirebaseMessaging.instance.subscribeToTopic("EmployeeRequests");
  }

  void setToken(String token, String uid) async {
    String finalToken;
    if (kIsWeb) {
      finalToken = "1" + token;
    } else {
      finalToken = "0" + token;
    }
    await user.doc(uid).update({
      'token': finalToken,
    });
  }

  getData() {
    messaging = FirebaseMessaging.instance;
    user.snapshots().listen((snapshot) {
      snapshot.docs.map((DocumentSnapshot document) async {
        Map userInfo = document.data() as Map<String, dynamic>;

        if (document.id == instance.currentUser!.uid) {
          isAdmin = userInfo['isAdmin'];
          data['firstName'] = userInfo['firstName'];
          data['lastName'] = userInfo['lastName'];
          data['companyName'] = userInfo['companyName'];
          if (!isAdmin!) {
            data['isAdmin'] = userInfo['isAdmin'];
            data['ownerEmail'] = userInfo['ownerEmail'];
            data['post'] = userInfo['post'];
            data['email'] = userInfo['email'];
          } else {
            data['isAdmin'] = userInfo['isAdmin'];
            data['ownerUID'] = document.id;
            data['ownerEmail'] = userInfo['email'];
          }

          data['token'] = userInfo['token'];

          data['uid'] = document.id;
          await FirebaseMessaging.instance
              .getToken()
              .then((token) => deviceToken = token)
              .whenComplete(() {
            String tokenPlatform = data['token'];
            if (deviceToken != null) {
              if (tokenPlatform.isEmpty ||
                  deviceToken != tokenPlatform.substring(1)) {
                setToken(deviceToken!, document.id);
              }
            }
          });
        }

        if (mounted) setState(() {});
      }).toList();
    });
    user.get().then((snapshot) {
      snapshot.docs.map((DocumentSnapshot document) {
        Map userInfo = document.data() as Map<String, dynamic>;
        if (data['ownerEmail'] == userInfo['email']) {
          data['ownerUID'] = document.id;
        }
      }).toList();
    });
  }

  void listenFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      print("Notification: " + notification.toString());
      print("Android: " + android.toString());
      if (notification != null && android != null && !kIsWeb) {
        Map<String, dynamic> messageData = message.data;
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              // TODO add a proper drawable resource to android, for now using
              //      one that already exists in example app.
              icon: 'launch_background',
            ),
          ),
        );
        print(messageData['uid'] + " wants you as a " + messageData['role']);
        if (messageData['role'] == "Seller" ||
            messageData['role'] == "Manager") {
          buildAddEmployeeNotifDialog(
              messageData['uid'], messageData['role'], messageData['id']);
        }
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Map<String, dynamic> messageData = message.data;
      print(messageData['uid'] + " wants you as a " + messageData['role']);
      if (messageData['role'] == "Seller" || messageData['role'] == "Manager") {
        buildAddEmployeeNotifDialog(
            messageData['uid'], messageData['role'], messageData['id']);
      }
    });
  }

  void loadFCM() async {
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        importance: Importance.high,
        enableVibration: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      /// Create an Android Notification Channel.
      ///
      /// We use this channel in the `AndroidManifest.xml` file to override the
      /// default FCM channel to enable heads up notifications.
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      /// Update the iOS foreground notification presentation options to allow
      /// heads up notifications.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  buildAddEmployeeNotifDialog(String uid, String role, String timeStamp) async {
    Map info = {};
    await user.doc(uid).get().then((value) => info = value.data() as Map);
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  //Dialog object
                  child: Dialog(
                    backgroundColor: Colors.grey[100],
                    //Dialog Size
                    child: SizedBox(
                      height: height / 5,
                      width: width / 1.2,
                      //Dialog content
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: info["firstName"],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                        text:
                                            ' wants to add you to their employement list.'),
                                  ],
                                  style: TextStyle(fontFamily: 'Mukta'),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                    },
                                    style: ButtonStyle(
                                      overlayColor:
                                          MaterialStateColor.resolveWith(
                                              (states) =>
                                                  Colors.grey.withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                          fontFamily: 'Mukta',
                                          color: Colors.grey[600]),
                                    )),
                                ElevatedButton(
                                    onPressed: () async {
                                      await user
                                          .doc(uid)
                                          .collection("employees")
                                          .doc(data['email'])
                                          .set({
                                        'addDate': timeStamp,
                                        'fullName': data['firstName'] +
                                            " " +
                                            data['lastName'],
                                        'post': role
                                      }).onError((error, stackTrace) {
                                        print(error);

                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();
                                        return;
                                      });

                                      user.doc(uid).get().then((document) {
                                        Map userInfo = document.data()
                                            as Map<String, dynamic>;
                                        user.doc(data['uid']).update({
                                          'ownerEmail': userInfo['email'],
                                          'post': role
                                        });
                                      }).whenComplete(() {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          backgroundColor: Colors.blueGrey[900],
                                          dismissDirection: DismissDirection.up,
                                          content: const Text(
                                              "Your account has been added successfully! Restart your app to see changes."),
                                        ));

                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();
                                      });
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.tealAccent[400]!),
                                    ),
                                    child: Text(
                                      "Accept",
                                      style: TextStyle(fontFamily: 'Mukta'),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "If this takes too long, check your internet connection.",
              style: TextStyle(fontFamily: 'Mukta'),
            ),
            const SizedBox(height: 10.0),
            PlatformCircularProgressIndicator(
              material: (_, __) => MaterialProgressIndicatorData(
                  color: Colors.tealAccent[400], strokeWidth: 1.0),
            ),
          ],
        ),
      );
    }
    scale = MediaQuery.of(context).textScaleFactor;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    pageController = PageController(initialPage: defaultPage);
    try {
      return SafeArea(
        child: Scaffold(
          extendBody: true,
          body: mounted
              ? PageView(
                  controller: pageController,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    Menu(instance: instance, data: data),
                    History(instance: instance, data: data),
                    Clients(instance: instance, data: data),
                    More(instance: instance, data: data),
                  ],
                )
              : Container(
                  child: Center(
                      child:
                          Text("Something went wrong, a restart is needed.")),
                ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: !kIsWeb
              ? FloatingActionButton(
                  heroTag: "Scan",
                  backgroundColor: Colors.tealAccent[400],
                  onPressed: () async {
                    scanBarcode(await _scan());
                  },
                  child: Icon(
                    FontAwesomeIcons.expand,
                  ),
                )
              : null,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            color: Colors.grey[50],
            child: IconTheme(
              data: IconThemeData(color: Colors.tealAccent[400]),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        pageController.animateToPage(0,
                            duration: const Duration(milliseconds: 75),
                            curve: Curves.ease);
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                      child: Icon(
                          _currentIndex != 0
                              ? Icons.shopping_basket_outlined
                              : Icons.shopping_basket,
                          color: Colors.tealAccent[400]),
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.resolveWith((states) {
                          return 0;
                        }),
                        backgroundColor:
                            MaterialStateProperty.resolveWith((states) {
                          return _currentIndex == 0
                              ? Color.fromARGB(20, 29, 233, 182)
                              : Colors.transparent;
                        }),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        pageController.animateToPage(1,
                            duration: const Duration(milliseconds: 75),
                            curve: Curves.ease);
                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                      child: Icon(
                        _currentIndex != 1
                            ? Icons.receipt_outlined
                            : Icons.receipt,
                        color: Colors.tealAccent[400],
                      ),
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.resolveWith((states) {
                          return 0;
                        }),
                        backgroundColor:
                            MaterialStateProperty.resolveWith((states) {
                          return _currentIndex == 1
                              ? Color.fromARGB(20, 29, 233, 182)
                              : Colors.transparent;
                        }),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 24.0),
                    ElevatedButton(
                      onPressed: () {
                        pageController.animateToPage(2,
                            duration: const Duration(milliseconds: 75),
                            curve: Curves.ease);
                        setState(() {
                          _currentIndex = 2;
                        });
                      },
                      child: Icon(
                        _currentIndex != 2
                            ? Icons.perm_contact_cal_outlined
                            : Icons.perm_contact_cal,
                        color: Colors.tealAccent[400],
                      ),
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.resolveWith((states) {
                          return 0;
                        }),
                        backgroundColor:
                            MaterialStateProperty.resolveWith((states) {
                          return _currentIndex == 2
                              ? Color.fromARGB(20, 29, 233, 182)
                              : Colors.transparent;
                        }),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        pageController.animateToPage(3,
                            duration: const Duration(milliseconds: 75),
                            curve: Curves.ease);
                        setState(() {
                          _currentIndex = 3;
                        });
                      },
                      child: Icon(
                        _currentIndex != 3
                            ? Icons.settings_outlined
                            : Icons.settings,
                        color: Colors.tealAccent[400],
                      ),
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.resolveWith((states) {
                          return 0;
                        }),
                        backgroundColor:
                            MaterialStateProperty.resolveWith((states) {
                          return _currentIndex == 3
                              ? Color.fromARGB(20, 29, 233, 182)
                              : Colors.transparent;
                        }),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Text("Something went wrong"),
      );
    }
  }

  Future<String> _scan() async {
    return await FlutterBarcodeScanner.scanBarcode(
        "#FF0000", "Cancel", true, ScanMode.BARCODE);
  }
}
