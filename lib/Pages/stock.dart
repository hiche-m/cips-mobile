import 'dart:io';
import 'package:application/Pages/menu.dart';
import 'package:application/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:application/Pages/loading.dart';
import 'package:application/Pages/management.dart';
import 'package:application/TextFormulations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:image_picker/image_picker.dart';

class Stock extends StatefulWidget {
  const Stock({Key? key}) : super(key: key);

  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late double defaultTextScaleFactor;
  var addlabelController = TextEditingController();
  var priceController = TextEditingController();
  var quantityController = TextEditingController();
  var quantityMinController = TextEditingController();
  final GlobalKey<FormState> addProductKey = GlobalKey<FormState>();
  String? label;
  int? price;
  int? quantity;
  int quantityMin = 0;
  String barcode = "";
  double? frameHeight;
  double? frameWidth;
  DatabaseReference? _dbref;
  bool countable = true;

  /* @override
  void iniState() {

    super.initState();
  } */

  @override
  void dispose() {
    addlabelController.dispose();
    priceController.dispose();
    quantityController.dispose();
    quantityMinController.dispose();
    super.dispose();
  }

  Widget _buildLabel() {
    return Container(
      height: (frameHeight! / 2) / 6 >= 75 ? (frameHeight! / 2) / 6 : 75,
      width: (frameWidth! / 1.25) / 3,
      decoration: BoxDecoration(
          //border: Border.all(),
          borderRadius: BorderRadius.circular(15.0)),
      child: Center(
        child: TextFormField(
          controller: addlabelController,
          maxLines: 1,
          style: const TextStyle(
              fontFamily: 'Titillium Web', height: 1.2, color: Colors.black87),
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: 'Label',
            hintStyle:
                TextStyle(fontFamily: 'Titillium Web', color: Colors.black38),
            prefixIcon: Icon(
              Icons.label_outline,
              color: Colors.black38,
              size: 13.0,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(
                color: Colors.black38,
              ),
            ),
          ),
          validator: (String? value) {
            return (value as String).isEmpty ? 'Label Missing!' : null;
          },
          onSaved: (String? value) {
            label = value;
          },
        ),
      ),
    );
  }

  Widget _buildPrice() {
    return Container(
      height: (frameHeight! / 2) / 6 >= 85 ? (frameHeight! / 2) / 6 : 85,
      width: (frameWidth! / 1.25) / 3,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
      child: Center(
        child: TextFormField(
          controller: priceController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          maxLines: 1,
          style: const TextStyle(
              fontFamily: 'Titillium Web', height: 1.2, color: Colors.black87),
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: countable ? 'Price (DA)' : 'Price (DA/KG)',
            hintStyle: const TextStyle(
                fontFamily: 'Titillium Web', color: Colors.black38),
            prefixIcon: const Icon(
              Icons.money,
              color: Colors.black38,
              size: 13.0,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: const BorderSide(
                color: Colors.black38,
              ),
            ),
          ),
          validator: (String? value) {
            return (value as String).isEmpty ? 'Price Missing!' : null;
          },
          onSaved: (String? value) {
            price = int.parse(value.toString());
          },
        ),
      ),
    );
  }

  Widget _buildQuantity() {
    return SafeArea(
      child: Container(
        height: (frameHeight! / 2) / 6 >= 85 ? (frameHeight! / 2) / 6 : 85,
        width: (frameWidth! / 1.25) / 3,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
        child: Center(
          child: TextFormField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            maxLines: 1,
            style: const TextStyle(
                fontFamily: 'Titillium Web',
                height: 1.2,
                color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: countable ? 'Quantity' : 'Quantity (Kg)',
              hintStyle: const TextStyle(
                  fontFamily: 'Titillium Web', color: Colors.black38),
              prefixIcon: const Icon(
                Icons.collections_bookmark_outlined,
                color: Colors.black38,
                size: 13.0,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: const BorderSide(
                  color: Colors.black38,
                ),
              ),
            ),
            validator: (String? value) {
              return (value as String).isEmpty ? 'Quantity Missing!' : null;
            },
            onSaved: (String? value) {
              quantity = int.parse(value.toString());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityMin() {
    return SafeArea(
      child: Container(
        height: (frameHeight! / 2) / 6 >= 85 ? (frameHeight! / 2) / 6 : 85,
        width: (frameWidth! / 1.25) / 3,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
        child: Center(
          child: TextFormField(
            controller: quantityMinController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            maxLines: 1,
            style: const TextStyle(
                fontFamily: 'Titillium Web',
                height: 1.2,
                color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: countable ? 'Min Quantity' : 'Min Quantity (Kg)',
              hintStyle: const TextStyle(
                  fontFamily: 'Titillium Web', color: Colors.black38),
              prefixIcon: const Icon(
                Icons.notification_important_outlined,
                color: Colors.black38,
                size: 13.0,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: const BorderSide(
                  color: Colors.black38,
                ),
              ),
            ),
            onSaved: (String? value) {
              quantityMin = int.parse(value.toString());
            },
          ),
        ),
      ),
    );
  }

  _scan() async {
    await FlutterBarcodeScanner.scanBarcode(
            "#FF0000", "Cancel", true, ScanMode.BARCODE)
        .then((value) => setState(() {
              barcode = value;
            }));
  }

  File? _profilePicture;

  @override
  Widget build(BuildContext context) {
    FirebaseAuth instance = FirebaseAuth.instance;

    if (_dbref == null) {
      _dbref = FirebaseDatabase.instance
          .ref()
          .child("Users/${instance.currentUser!.uid}/Products");
    }

    frameHeight = MediaQuery.of(context).size.height;
    frameWidth = MediaQuery.of(context).size.width;
    defaultTextScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      key: _scaffoldKey,
      body: StreamBuilder<User?>(
          stream: instance.authStateChanges(),
          builder: (context, snapshot) {
            if (!mounted) {
              Center(
                child: SpinKitCubeGrid(
                  color: Colors.white,
                  size: 35.0,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SpinKitCubeGrid(
                  color: Colors.white,
                  size: 35.0,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "An error has been ocurred, please check your internet connection",
                  style: TextStyle(fontFamily: 'Mukta'),
                ),
              );
            } else {
              return Manage(instance: instance, scaffoldKey: _scaffoldKey);
            }
          }),
      floatingActionButton: RawMaterialButton(
        elevation: 2.0,
        fillColor: Colors.tealAccent[400],
        child: const Icon(
          Icons.add_business_rounded,
          size: 35.0,
          color: Colors.white,
        ),
        padding: EdgeInsets.all(15.0),
        shape: CircleBorder(),
        onPressed: () {
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(builder: (context, setState) {
                  return CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Dialog(
                          backgroundColor: Colors.grey[100],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: frameHeight! / 2,
                              width: frameWidth! / 1.25,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Scrollbar(
                                          scrollbarOrientation:
                                              ScrollbarOrientation.left,
                                          interactive: true,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                Stack(
                                                  children: [
                                                    /*                                                Image*/
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10.0),
                                                      child: CircleAvatar(
                                                        backgroundColor:
                                                            Colors.white,
                                                        radius: 50,
                                                        child: CircleAvatar(
                                                          radius: 48,
                                                          backgroundColor:
                                                              Colors.grey[200],
                                                          backgroundImage:
                                                              _profilePicture ==
                                                                      null
                                                                  ? AssetImage(
                                                                      "assets/products/None.jpg")
                                                                  : Image.file(
                                                                          _profilePicture!)
                                                                      .image,
                                                        ),
                                                      ),
                                                    ),
                                                    /*                                                      Edit button*/
                                                    !kIsWeb
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 70.0,
                                                                    left: 45.0),
                                                            child: RaisedButton(
                                                              onPressed:
                                                                  () async {
                                                                final source =
                                                                    await showOptionsMenu(
                                                                        context);
                                                                source != null
                                                                    ? await getImage(
                                                                        source)
                                                                    : ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                            SnackBar(
                                                                        backgroundColor:
                                                                            Colors.blueGrey[900],
                                                                        dismissDirection:
                                                                            DismissDirection.up,
                                                                        content:
                                                                            Text("WARNING: No image was picked."),
                                                                      ));
                                                                setState(() {});
                                                              },
                                                              shape:
                                                                  const CircleBorder(),
                                                              elevation: 1.0,
                                                              child: Icon(
                                                                Icons
                                                                    .edit_outlined,
                                                                size: 12.5,
                                                                color:
                                                                    Colors.teal,
                                                              ),
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )
                                                        : SizedBox(),
                                                  ],
                                                ),
                                                !kIsWeb
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            "Scan Barcode",
                                                            maxLines: 1,
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'Mukta',
                                                                fontSize: 10.0 *
                                                                    defaultTextScaleFactor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          PlatformIconButton(
                                                            onPressed:
                                                                () async {
                                                              await FlutterBarcodeScanner.scanBarcode(
                                                                      "#FF0000",
                                                                      "Cancel",
                                                                      true,
                                                                      ScanMode
                                                                          .BARCODE)
                                                                  .then((value) =>
                                                                      setState(
                                                                          () {
                                                                        barcode =
                                                                            value;
                                                                      }));
                                                            },
                                                            icon: Icon(
                                                                Icons
                                                                    .document_scanner_rounded,
                                                                size: 25.0 *
                                                                    defaultTextScaleFactor,
                                                                color: barcode
                                                                            .isNotEmpty &&
                                                                        barcode !=
                                                                            "-1"
                                                                    ? Colors.teal[
                                                                        400]
                                                                    : Colors.grey[
                                                                        700]),
                                                            material: (_, __) =>
                                                                MaterialIconButtonData(
                                                              splashRadius:
                                                                  25.0,
                                                              splashColor: Colors
                                                                  .transparent,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                            ),
                                                          ),
                                                          SizedBox(),
                                                          Text(
                                                            "Code:",
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Mukta',
                                                              fontSize: 13.75 *
                                                                  defaultTextScaleFactor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            barcode != "-1"
                                                                ? barcode
                                                                    .toString()
                                                                : "",
                                                            overflow:
                                                                TextOverflow
                                                                    .fade,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Mukta',
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: 10.0,
                                                            child:
                                                                PlatformIconButton(
                                                                    onPressed: barcode.isNotEmpty &&
                                                                            barcode !=
                                                                                "-1"
                                                                        ? () {
                                                                            setState(() {
                                                                              barcode = "";
                                                                            });
                                                                          }
                                                                        : null,
                                                                    icon: barcode.isNotEmpty &&
                                                                            barcode !=
                                                                                "-1"
                                                                        ? Icon(
                                                                            Icons.close_rounded,
                                                                          )
                                                                        : Icon(
                                                                            null),
                                                                    material: (_,
                                                                            __) =>
                                                                        MaterialIconButtonData(
                                                                          splashColor:
                                                                              Colors.transparent,
                                                                          hoverColor:
                                                                              Colors.transparent,
                                                                        )),
                                                          ),
                                                        ],
                                                      )
                                                    : SizedBox(),
                                                const SizedBox(
                                                  height: 25.0,
                                                ),
                                                GestureDetector(
                                                  onTap: () => setState(() {
                                                    countable = !countable;
                                                  }),
                                                  child: Row(
                                                    children: [
                                                      const Text(
                                                        "Countable  ",
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Mukta'),
                                                      ),
                                                      Icon(
                                                        countable
                                                            ? Icons
                                                                .check_box_rounded
                                                            : Icons
                                                                .check_box_outline_blank_rounded,
                                                        color: Colors
                                                            .tealAccent[400],
                                                      ),
                                                      Icon(
                                                        countable
                                                            ? Icons.plus_one
                                                            : Icons.one_k_plus,
                                                        color: Colors.grey[350],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        /*                                                Form*/
                                        Form(
                                          key: addProductKey,
                                          child: Scrollbar(
                                            scrollbarOrientation:
                                                ScrollbarOrientation.right,
                                            interactive: true,
                                            child: SingleChildScrollView(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 10.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    _buildLabel(),
                                                    _buildPrice(),
                                                    _buildQuantity(),
                                                    _buildQuantityMin(),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5.0, 5.0, 15.0, 5.0),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontSize:
                                                  16.5 * defaultTextScaleFactor,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        style: ButtonStyle(
                                          overlayColor:
                                              MaterialStateProperty.all(
                                                  Colors.grey.withOpacity(0.1)),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final isValid = addProductKey
                                              .currentState!
                                              .validate();
                                          if (isValid) {
                                            addProductKey.currentState!.save();
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              backgroundColor:
                                                  Colors.blueGrey[900],
                                              dismissDirection:
                                                  DismissDirection.up,
                                              content: Text(
                                                  "Adding product to the stock..."),
                                            ));
                                            String id;
                                            barcode.isEmpty
                                                ? id = idGenerator()
                                                : id = barcode;
                                            Map<String, dynamic> productInfo = {
                                              "id": id.toString(),
                                              "label": label,
                                              "price": price,
                                              "quantity": quantity,
                                              "quantityMin": quantityMin,
                                              "isCountable": countable,
                                            };
                                            await addProduct(productInfo);
                                            await uploadProductToStorage(
                                                FirebaseAuth
                                                    .instance.currentUser!,
                                                productInfo);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15.0, 5.0, 15.0, 5.0),
                                          child: Text(
                                            "Add",
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontSize:
                                                  16.5 * defaultTextScaleFactor,
                                            ),
                                          ),
                                        ),
                                        style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          18.0),
                                                  side: BorderSide(
                                                      color:
                                                          Colors.transparent))),
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Colors.tealAccent[400]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                });
              });
        },
      ),
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

  clearInputs() {
    addlabelController.clear();
    priceController.clear();
    quantityController.clear();
    quantityMinController.clear();
    _profilePicture = null;
    barcode = "";
  }

  Future getImage(ImageSource source) async {
    var image = await ImagePicker().pickImage(source: source);

    if (image != null) {
      _profilePicture = await compressImg(image: File(image.path));
    }
  }

  Future<File> compressImg(
      {required File image, quality = 90, percentage = 10}) async {
    var path = FlutterNativeImage.compressImage(image.absolute.path,
        quality: quality, percentage: percentage);
    return path;
  }

  Future uploadProductToStorage(User user, Map info) async {
    final userID = user.uid;
    final String path = "$userID/Products/${info["id"]}";

    await FirebaseStorage.instance
        .refFromURL("gs://cips-mobile.appspot.com/")
        .child("Profiles")
        .child(path)
        .putFile(_profilePicture!);

    await _dbref!.child(info["id"]).update({
      "Img": path,
    }).catchError((onError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.blueGrey[900],
        dismissDirection: DismissDirection.up,
        content:
            Text("Error! Something went wrong, reason: " + onError.toString()),
      ));
    });
  }

  addProduct(Map info) {
    print(info["label"]);
    for (var product in listOfProducts) {
      if (product.id.toString() == info["id"] ||
          product.title == info["label"]) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.blueGrey[900],
          dismissDirection: DismissDirection.up,
          content: const Text(
              "A product with this id or name already exists, try modifying it or changing the name/id."),
        ));
        return;
      }
    }
    _dbref!.child(info["id"]).set({
      "Img": "",
      "Name": capFix(info["label"]),
      "Price": info["price"],
      "Quantity": info["quantity"],
      "minQuantity": info["quantityMin"],
      "isCountable": info["isCountable"],
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.blueGrey[900],
        dismissDirection: DismissDirection.up,
        content: const Text("Product added successfully"),
      ));
      clearInputs();
    }).catchError((onError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.blueGrey[900],
        dismissDirection: DismissDirection.up,
        content: Text("Couldn't add the product into the database, reason: " +
            onError.toString()),
      ));
    });
  }

  String idGenerator() {
    final now = DateTime.now();
    return now.microsecondsSinceEpoch.toString();
  }
}
