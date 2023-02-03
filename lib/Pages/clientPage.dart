import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../client.dart';

class ClientPage extends StatefulWidget {
  final Client? client;
  ClientPage({Key? key, this.client}) : super(key: key);

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  late final Client? client = widget.client;
  late String profileImage = client!.picture;

  @override
  Widget build(BuildContext context) {
    final widthScale = 410 / MediaQuery.of(context).size.width;
    final heightScale = 865 / MediaQuery.of(context).size.height;

    return SafeArea(
      child: PlatformScaffold(
        material: (_, __) => MaterialScaffoldData(
          extendBodyBehindAppBar: true,
        ),
        appBar: PlatformAppBar(
          material: (_, __) => MaterialAppBarData(
            elevation: 0,
          ),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            splashRadius: 25.0,
          ),
        ),
        body: CustomPaint(
          painter: TealLine(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /*                                                                    Top container*/
                  SizedBox(
                    height: 160,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(profileImage),
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                        ClipRect(
                          child: SizedBox(
                            height: 160,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 10,
                                sigmaY: 10,
                              ),
                              child: Container(
                                  color: Colors.black.withOpacity(0.1)),
                            ),
                          ),
                        ),
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[50],
                                radius: 53.5,
                                child: CircleAvatar(
                                  radius: 50.0,
                                  backgroundImage: AssetImage(profileImage),
                                  backgroundColor: Colors.grey[100],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 70.0, left: 55.0),
                                child: RaisedButton(
                                  onPressed: () {},
                                  shape: const CircleBorder(),
                                  elevation: 1.0,
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 12.5,
                                    color: Colors.teal,
                                  ),
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  /*                                                                    First Row*/
                  Row(
                    children: [
                      Flexible(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8.0, right: 8.0),
                          child: Card(
                            elevation: 8.0,
                            child: Center(
                              child: SizedBox(
                                height: 160 / heightScale,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outlined,
                                          size: 32.5 / widthScale),
                                      Text(
                                        "   " + client!.name,
                                        softWrap: true,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          fontSize: 25.0 / widthScale,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8.0, left: 8.0),
                          child: Card(
                            elevation: 8.0,
                            child: SizedBox(
                              height: 160 / heightScale,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.attach_money_rounded,
                                          size: 32.5 / widthScale),
                                      Text(
                                        "   " +
                                            client!.income.toString() +
                                            ".00 DA",
                                        softWrap: true,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          fontSize: 25.0 / widthScale,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  /*                                                                    Second Row*/
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8.0, right: 8.0),
                          child: Card(
                            elevation: 8.0,
                            child: InkWell(
                              onLongPress: () {
                                launch('tel: 0${client!.number.toString()}');
                              },
                              child: Center(
                                child: SizedBox(
                                  height: 160 / heightScale,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.call_outlined,
                                            size: 27.5 / widthScale),
                                        Text(
                                          "   0" + client!.number.toString(),
                                          softWrap: true,
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            fontSize: 25.0 / widthScale,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8.0, left: 8.0),
                          child: Card(
                            elevation: 8.0,
                            child: SizedBox(
                              height: 160 / heightScale,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.money,
                                            size: 32.5 / widthScale),
                                        Text(
                                          "   " +
                                              client!.tab.toString() +
                                              ".00 DA",
                                          softWrap: true,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            fontSize: 25.0 / widthScale,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Next expected payment: " +
                                          DateFormat('yyyy-MM-dd')
                                              .format((client!.tabDate!)),
                                      style: TextStyle(
                                        fontFamily: 'Mukta',
                                        fontSize: 12.0 / widthScale,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 40.0 / heightScale),
                    child: Center(
                      child: Text(
                        "Client since XX/XX/XXXX",
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[700],
                          fontSize: 15.0 / widthScale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 50.0, right: 50.0, bottom: 25.0),
                  child: Container(
                    height: 55.0,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(),
                          Text(
                            "Edit",
                            style: TextStyle(
                              fontFamily: 'Titillium Web',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(),
                        ],
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.blueGrey[900]!),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            //side: BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBlur({
    required Widget child,
    BorderRadius? borderRadius,
    double sigmaX = 10,
    double sigmaY = 10,
  }) =>
      ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: child,
        ),
      );
}

class TealLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    Paint paint = Paint();

    Path mainBackground = Path();
    mainBackground.addRect(Rect.fromLTRB(0, 0, width, height));
    paint.color = Colors.grey.shade50; //Colors.tealAccent[700]!;
    canvas.drawPath(mainBackground, paint);

    Path line = Path();
    //Path Start
    line.moveTo(0, height * 0.70);
    line.quadraticBezierTo(width * 0.7, height * 0.675, width, height * 0.40);
    line.lineTo(width, height);
    line.lineTo(0, height);
    paint.color = Colors.tealAccent[700]!.withOpacity(0.3);
    canvas.drawPath(line, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
