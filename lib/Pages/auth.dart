import 'package:application/Pages/home.dart';
import 'package:application/Pages/sign_in.dart';
import 'package:application/Pages/sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class Auth extends StatefulWidget {
  const Auth({Key? key}) : super(key: key);
  toggleSignIn() {
    signInBool = !signInBool!;
  }

  @override
  State<Auth> createState() => _AuthState();
}

bool? signInBool = true;

FirebaseAuth instance = FirebaseAuth.instance;

class _AuthState extends State<Auth> {
  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: StreamBuilder<User?>(
          stream: instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SpinKitCubeGrid(
                  color: Colors.white,
                  size: 35.0,
                ),
              );
            } else if (snapshot.hasData && mounted) {
              return SafeArea(child: Home(instance: instance));
            } else if (snapshot.hasError && signInBool!) {
              return SafeArea(child: SignIn(error: true));
            } else if (!snapshot.hasError && signInBool!) {
              return SafeArea(child: SignIn(error: false));
            } else if (snapshot.hasError && !signInBool!) {
              return SafeArea(child: SignUp(showEror: true));
            } else {
              return SafeArea(child: SignUp(showEror: false));
            }
          }),
    );
  }
}
