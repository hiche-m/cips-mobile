import 'package:application/Pages/barcode.dart';
import 'package:application/Pages/resetPassword.dart';
import 'package:application/Pages/settings.dart';
import 'package:application/Pages/stock.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:application/Pages/loading.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'Pages/auth.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  kIsWeb
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "${{ secrets.FIREBASE_API }}",
            appId: "${{ secrets.FIREBASE_APPID }}",
            messagingSenderId: "${{ secrets.FIREBASE_MESSAGING_SENDERID }}",
            projectId: "${{ secrets.PROJECT_ID }}",
            storageBucket: "${{ secrets.FIREBASE_STORAGE_BUCKET }}",
            databaseURL:
                "${{ secrets.FIREBASE_DATABASE_URL }}",
          ),
        )
      : await Firebase.initializeApp(
          name: "CIPS Mobile",
          options: const FirebaseOptions(
            apiKey: "${{ secrets.FIREBASE_API }}",
            appId: "${{ secrets.FIREBASE_APPID }}",
            messagingSenderId: "${{ secrets.FIREBASE_MESSAGING_SENDERID }}",
            projectId: "${{ secrets.PROJECT_ID }}",
            storageBucket: "${{ secrets.FIREBASE_STORAGE_BUCKET }}",
            databaseURL:
                "${{ secrets.FIREBASE_DATABASE_URL }}",
          ),
        );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom]);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(PlatformApp(
    title: "CIPS Mobile",
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes: {
      '/': (context) => const Loading(),
      '/auth': (context) => const Auth(),
      '/pass': (context) => const Reset(),
      '/settings': (context) => const Settings(),
      '/barcode': (context) => const Barcode(),
      '/stock': (context) => const Stock(),
    },
  ));
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}
