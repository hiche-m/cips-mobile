import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  void loadScreen(context) async {
    Navigator.pushReplacementNamed(context, '/auth',
        arguments: {"instance": _auth});
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  late StreamSubscription subscription;

  firebaseUser() {
    subscription = _auth.userChanges().listen((User? userState) {
      if (userState == null) {
        user = null;
      } else {
        user = userState;
      }
      loadScreen(context);
    });
    return user;
  }

  @override
  void initState() {
    super.initState();

    user = firebaseUser();
  }

  /* @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  } */

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final platform = Theme.of(context).platform;
    return PlatformScaffold(
      backgroundColor: Colors.tealAccent[200],
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: (width / 2) / 2,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: (width / 2.5) / 2 - 15,
                backgroundColor: Colors.tealAccent[200],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: ((width / 2.5) / 2 - 15) * 2),
              child: Container(
                height: ((width / 2.5) / 2 - 30) / 3,
                width: (width / 2.5) / 2 - 50,
                color: Colors.tealAccent[200],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
