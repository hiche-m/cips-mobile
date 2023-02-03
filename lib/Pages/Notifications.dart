import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class Notif extends StatefulWidget {
  const Notif({Key? key}) : super(key: key);

  @override
  State<Notif> createState() => _NotifState();
}

class _NotifState extends State<Notif> {
  bool active = true;

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
        title: Text("Notification Settings",
            style: TextStyle(
              fontFamily: 'Mukta',
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            )),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(
              "Notify me when a product is about to end ",
              style: TextStyle(fontFamily: 'Mukta'),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  active = !active;
                });
              },
              child: Icon(
                active ? Icons.check_box : Icons.check_box_outline_blank,
                color: active ? Colors.greenAccent : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
