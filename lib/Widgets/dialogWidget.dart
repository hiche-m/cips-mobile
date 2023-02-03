import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

enum DialogAction { yes, cancel }

class DialogWidget {
  static Future<DialogAction> yesCancelDialog(
      BuildContext context, String title, String body, Color? color) async {
    final action = await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return PlatformAlertDialog(
            material: (_, __) => MaterialAlertDialogData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
            ),
            title: Text(
              title,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mukta'),
            ),
            content: Text(
              body,
              style: const TextStyle(fontFamily: 'Mukta'),
            ),
            actions: <Widget>[
              FlatButton(
                  onPressed: () =>
                      Navigator.of(context).pop(DialogAction.cancel),
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontFamily: 'Mukta'),
                  )),
              RaisedButton(
                onPressed: () => Navigator.of(context).pop(DialogAction.yes),
                color: color,
                child: Text(
                  "Yes",
                  style: TextStyle(color: Colors.white, fontFamily: 'Mukta'),
                ),
              ),
            ],
          );
        });
    return (action != null) ? action : DialogAction.cancel;
  }
}
