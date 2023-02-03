import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({Key? key}) : super(key: key);

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.blueGrey[900],
          ),
          splashRadius: 25.0,
        ),
        title: Text("App Settings",
            style: TextStyle(
              fontFamily: 'Mukta',
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            )),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "No app settings for the moment.",
          style: TextStyle(fontFamily: 'Mukta'),
        ),
      ),
    );
  }
}
