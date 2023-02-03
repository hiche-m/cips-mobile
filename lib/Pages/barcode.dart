import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class Barcode extends StatefulWidget {
  const Barcode({Key? key}) : super(key: key);

  @override
  State<Barcode> createState() => _BarcodeState();
}

class _BarcodeState extends State<Barcode> {
  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        backgroundColor: Colors.transparent,
        material: (_, __) => MaterialAppBarData(
          elevation: 0,
        ),
        leading: PlatformIconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          material: (_, __) => MaterialIconButtonData(
            splashRadius: 0.5,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.blueGrey[900],
        ),
      ),
      body: Text("Scan Barcode"),
    );
  }
}
