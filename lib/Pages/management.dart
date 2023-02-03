import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:application/TextFormulations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:application/FirebaseCloudFunctions.dart';
import 'package:application/ProductClass.dart';
import 'package:application/Widgets/dialogWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Manage extends StatefulWidget {
  Manage({Key? key, required this.instance, required this.scaffoldKey})
      : super(key: key);

  GlobalKey scaffoldKey;
  FirebaseAuth instance;

  @override
  State<Manage> createState() =>
      _ManageState(instance: instance, scaffoldKey: scaffoldKey);
}

class _ManageState extends State<Manage> {
  _ManageState({required this.instance, required this.scaffoldKey});

  FirebaseAuth instance;
  GlobalKey scaffoldKey;
  DatabaseReference? _dbref;
  final searchController = TextEditingController();
  late String query;
  bool net = false;
  Map<dynamic, dynamic>? map;
  String? dataString;
  List<ProductObj> listOfProducts = [];
  List<ProductObj> productsBackup = [];

/*                                                                              Search Controller Method*/
  void searchFilter(String query) {
    List<ProductObj> instance = [];

    for (var item in listOfProducts) {
      if (item.title.toLowerCase().contains(query.toLowerCase())) {
        instance.add(item);
      }
    }

    setState(() {
      if (query.isNotEmpty) {
        listOfProducts = instance;
        if (this.query.length > query.length) {
          instance.clear();
          listOfProducts = productsBackup;
          for (var item in listOfProducts) {
            if (item.title.toLowerCase().contains(query.toLowerCase())) {
              instance.add(item);
            }
          }
          listOfProducts = instance;
        }
      } else {
        listOfProducts = productsBackup;
      }
      this.query = query;
    });
  }

  @override /*                                                                  Init State*/
  void initState() {
    if (_dbref == null) {
      _dbref = FirebaseDatabase.instance
          .ref()
          .child("Users/${instance.currentUser!.uid}/Products");
    }
    getProducts();

    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    disposeVar.cancel();
    super.dispose();
  }

  late StreamSubscription disposeVar;
  /*                                                                            Get Products*/
  getProducts() {
    try {
      net = false;
      disposeVar = _dbref!.onValue.listen((event) {
        if (event.snapshot.value != null) {
          dataString = jsonEncode(event.snapshot.value);
          map = jsonDecode(dataString!);
          listOfProducts = [];
          productsBackup = [];

          map!.forEach((idKey, element) {
            if (element['Img'].toString().isEmpty &&
                element['minQuantity'] == null) {
              listOfProducts.add(
                ProductObj(
                  id: int.parse(idKey),
                  title: element['Name'],
                  price: element['Price'].toDouble(),
                  quantity: element['Quantity'].toDouble(),
                  isCountable: element['isCountable'],
                ),
              );
            } else if (element['Img'].toString().isNotEmpty &&
                element['minQuantity'] == null) {
              listOfProducts.add(ProductObj(
                id: int.parse(idKey),
                title: element['Name'],
                price: element['Price'].toDouble(),
                picture: element['Img'],
                quantity: element['Quantity'].toDouble(),
                isCountable: element['isCountable'],
              ));
            } else if (element['Img'].toString().isEmpty &&
                element['minQuantity'] != null) {
              listOfProducts.add(
                ProductObj(
                  id: int.parse(idKey),
                  title: element['Name'],
                  price: element['Price'].toDouble(),
                  quantity: element['Quantity'].toDouble(),
                  minQuantity: element['minQuantity'].toDouble(),
                  isCountable: element['isCountable'],
                ),
              );
            } else {
              listOfProducts.add(ProductObj(
                id: int.parse(idKey),
                title: element['Name'],
                price: element['Price'].toDouble(),
                picture: element['Img'],
                quantity: element['Quantity'].toDouble(),
                minQuantity: element['minQuantity'].toDouble(),
                isCountable: element['isCountable'],
              ));
            }
          });
          productsBackup = listOfProducts;
          removeDuplicates();
          clearSearch();
          setState(() {});
        } else {
          listOfProducts = [];
          productsBackup = [];
        }
      });
    } on Exception {
      setState(() {
        net = true;
      });
    }
  }

  removeDuplicates() {
    listOfProducts = listOfProducts.toSet().toList();
    productsBackup = productsBackup.toSet().toList();
  }

/*                                                                              Clear Search*/
  void clearSearch() {
    setState(() {
      query = "";
      searchController.clear();
      listOfProducts = productsBackup;
    });
  }

  Map<ProductObj, String> imageList = {};
  bool isValid = true;

  Future<File> _fileFromImageUrl(String src) async {
    final response = await http.get(Uri(path: src));

    final documentDirectory = await getApplicationDocumentsDirectory();

    final file = File(path.join(documentDirectory.path,
        DateFormat('yyyyMMddHHmmssSS').format(DateTime.now())));

    file.writeAsBytesSync(response.bodyBytes);

    return file;
  }

  @override
  Widget build(BuildContext context) {
    scale = MediaQuery.of(context).textScaleFactor;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    imageList = {};
    /*                                                                          The build method*/
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSwatch(
          accentColor: Colors.grey, // but now it should be declared like this
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            clearSearch();
          });
        },
        color: Colors.tealAccent[200],
        child: listOfProducts.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*                                                                      Search bar*/
                  Row(
                    children: [
                      Center(
                        child: PlatformIconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 17.5,
                            )),
                      ),
                      /*Search Bar                                                    */
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(1.0, 2.0, 5.0, 0),
                          child: Container(
                            height: 40.0,
                            child: PlatformTextField(
                              controller: searchController,
                              onChanged: searchFilter,
                              material: (_, __) => MaterialTextFieldData(
                                decoration: InputDecoration(
                                  hintText: 'Search for a product',
                                  contentPadding:
                                      const EdgeInsets.only(left: 15.0),
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: searchController.text.isNotEmpty
                                      ? PlatformIconButton(
                                          onPressed: () {
                                            clearSearch();
                                            searchController.clear();
                                          },
                                          icon: const Icon(Icons.close),
                                          material: (_, __) =>
                                              MaterialIconButtonData(
                                                iconSize: 18.0,
                                                splashColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                              ))
                                      : null,
                                ),
                              ),
                              style: TextStyle(
                                  fontSize: 15.0, color: Colors.grey[600]),
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 250, 250, 250),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15.0)),
                              border: Border.all(
                                  width: 2.0, color: Colors.grey.shade50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 25.0,
                        backgroundColor: Colors.white,
                        child: InkWell(
                          onTap: () async {
                            final action = await DialogWidget.yesCancelDialog(
                                context,
                                "Refresh List?",
                                "This will empty your cart.",
                                Colors.blueGrey[700]);
                            if (action == DialogAction.yes) {}
                          },
                          child: Icon(
                            Icons.replay_circle_filled_rounded,
                            size: 25.0,
                            color: Colors.blueGrey[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  /*                                                                  Listview*/
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      itemCount: listOfProducts.length,
                      itemBuilder: ((context, index) {
                        ProductObj product = listOfProducts[index];
                        return InkWell(
                          onLongPress: () {
                            buildEditDialog(
                                scaffoldKey.currentContext!, product);
                          },
                          child: ListTile(
                            leading: StreamBuilder<String>(
                              stream: product.picture.toString().isEmpty
                                  ? getProductUrl("None.jpg").asStream()
                                  : getProductUrl(product.picture).asStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircleAvatar(
                                      backgroundColor: index < 255
                                          ? Color.fromARGB(
                                              255,
                                              255 - (index * 10),
                                              255 - (index * 10),
                                              255 - (index * 10))
                                          : Colors.grey[900]);
                                } else if (snapshot.hasError) {
                                  return CircleAvatar(
                                      backgroundColor: Colors.red[300]);
                                }

                                imageList[product] = snapshot.data.toString();
                                return CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  backgroundImage:
                                      Image.network(snapshot.data.toString())
                                          .image,
                                );
                              },
                            ),
                            title: Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(fontFamily: 'Mukta'),
                            ),
                            subtitle: Text(
                              "X" + product.quantity.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(fontFamily: 'Mukta'),
                            ),
                            trailing: PlatformText(
                              product.isCountable
                                  ? product.price.toStringAsFixed(2) + " DA"
                                  : product.price.toStringAsFixed(2) + " DA/KG",
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 15.0,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  )
                ],
              )
            : const Center(
                child: Text(
                  "It looks like you have no products...",
                  style: TextStyle(fontFamily: 'Mukta'),
                ),
              ),
      ),
    );
  }

  late double scale;
  late double width;
  late double height;

  final GlobalKey<FormState> updateProductKey = GlobalKey<FormState>();
  String? label;
  double? price;
  double? quantity;
  double quantityMin = 0;

  buildEditDialog(BuildContext context, ProductObj productObj) {
    bool isCountable = productObj.isCountable;
    TextEditingController labelController =
        TextEditingController(text: productObj.title);
    TextEditingController priceController = TextEditingController(
      text: productObj.price.toStringAsFixed(2),
    );
    TextEditingController quantityController = TextEditingController(
      text: isCountable
          ? productObj.quantity.toStringAsFixed(0)
          : productObj.quantity.toStringAsFixed(2),
    );
    TextEditingController quantityMinController = TextEditingController(
      text: isCountable || productObj.minQuantity == 0
          ? productObj.minQuantity.toStringAsFixed(0)
          : productObj.minQuantity.toStringAsFixed(2),
    );
    double inputHeight = height / 2 / 8;
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Dialog(
                    backgroundColor: Colors.grey[100],
                    child: SizedBox(
                      height: height / 2,
                      width: width / 1.2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            flex: 4,
                            child: Align(
                              alignment: Alignment.center,
                              child: Scrollbar(
                                scrollbarOrientation:
                                    ScrollbarOrientation.right,
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0),
                                    child: Form(
                                      key: updateProductKey,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            height: inputHeight * 2.5 > 125
                                                ? inputHeight * 2.5
                                                : 125,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(
                                                            10.0),
                                                    child: Stack(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: (width /
                                                              (1.2 * 5)),
                                                          backgroundColor:
                                                              Colors.grey,
                                                          child: CircleAvatar(
                                                            radius: (width /
                                                                    (1.2 * 5)) -
                                                                30,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child: ClipOval(
                                                              child:
                                                                  GestureDetector(
                                                                onTap: !kIsWeb
                                                                    ? () async {
                                                                        final source =
                                                                            await showOptionsMenu(context);
                                                                        source !=
                                                                                null
                                                                            ? {
                                                                                await getImage(source),
                                                                                imageList[productObj] = _profilePicture!.path
                                                                              }
                                                                            : ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                                backgroundColor: Colors.blueGrey[900],
                                                                                dismissDirection: DismissDirection.up,
                                                                                content: Text("WARNING: No image was picked."),
                                                                              ));
                                                                        setState(
                                                                            () {});
                                                                      }
                                                                    : null,
                                                                child: Image.network(
                                                                    imageList[
                                                                        productObj]!),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Align(
                                                          alignment: Alignment
                                                              .bottomRight,
                                                          child:
                                                              GestureDetector(
                                                            onTap: !kIsWeb
                                                                ? () async {
                                                                    final source =
                                                                        await showOptionsMenu(
                                                                            context);
                                                                    source !=
                                                                            null
                                                                        ? await getImage(
                                                                            source)
                                                                        : ScaffoldMessenger.of(context)
                                                                            .showSnackBar(SnackBar(
                                                                            backgroundColor:
                                                                                Colors.blueGrey[900],
                                                                            dismissDirection:
                                                                                DismissDirection.up,
                                                                            content:
                                                                                Text("WARNING: No image was picked."),
                                                                          ));
                                                                    setState(
                                                                        () {});
                                                                  }
                                                                : null,
                                                            child: !kIsWeb
                                                                ? Icon(
                                                                    Icons
                                                                        .change_circle_rounded,
                                                                    color: Colors
                                                                            .blueGrey[
                                                                        700],
                                                                  )
                                                                : const SizedBox(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  flex: 3,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "ID: ",
                                                        style: TextStyle(
                                                            fontFamily: 'Mukta',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .blueGrey[900]),
                                                      ),
                                                      Text(
                                                        productObj.id
                                                            .toString(),
                                                        softWrap: false,
                                                        overflow:
                                                            TextOverflow.fade,
                                                        style: TextStyle(
                                                            fontFamily: 'Mukta',
                                                            color: Colors
                                                                .blueGrey[900]),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10.0),
                                                child: Text(
                                                  "Label:",
                                                  style: TextStyle(
                                                    fontFamily: 'Mukta',
                                                    fontSize: 17.5 * scale,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueGrey[900],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: inputHeight > 50
                                                    ? inputHeight
                                                    : 50,
                                                width: width / 1.2 / 1.5,
                                                child: Container(
                                                  color: Colors.grey[300],
                                                  child: Theme(
                                                    data: Theme.of(context).copyWith(
                                                        textSelectionTheme:
                                                            TextSelectionThemeData(
                                                                selectionColor:
                                                                    Colors.teal[
                                                                        100],
                                                                cursorColor:
                                                                    Colors.grey[
                                                                        600])),
                                                    child: TextFormField(
                                                      controller:
                                                          labelController,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        fontSize: 20 * scale,
                                                      ),
                                                      textInputAction:
                                                          TextInputAction.done,
                                                      decoration:
                                                          const InputDecoration(
                                                        hintText:
                                                            'Product label.',
                                                        errorStyle: TextStyle(
                                                            fontSize: 0.01),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        enabledBorder:
                                                            const OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        hintStyle: TextStyle(
                                                          fontFamily: 'Mukta',
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      validator:
                                                          (String? value) {
                                                        return (value as String)
                                                                .isEmpty
                                                            ? 'Label Missing!'
                                                            : null;
                                                      },
                                                      onSaved: (String? value) {
                                                        label = value;
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5.0),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10.0),
                                                child: Text(
                                                  "Price:",
                                                  style: TextStyle(
                                                    fontFamily: 'Mukta',
                                                    fontSize: 17.5 * scale,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueGrey[900],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: inputHeight > 50
                                                    ? inputHeight
                                                    : 50,
                                                width: width / 1.2 / 1.5,
                                                child: Container(
                                                  color: Colors.grey[300],
                                                  child: Theme(
                                                    data: Theme.of(context).copyWith(
                                                        textSelectionTheme:
                                                            TextSelectionThemeData(
                                                                selectionColor:
                                                                    Colors.teal[
                                                                        100],
                                                                cursorColor:
                                                                    Colors.grey[
                                                                        600])),
                                                    child: TextFormField(
                                                      controller:
                                                          priceController,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        fontSize: 20 * scale,
                                                      ),
                                                      textInputAction:
                                                          TextInputAction.done,
                                                      decoration:
                                                          InputDecoration(
                                                        errorStyle: TextStyle(
                                                            fontSize: 0.01),
                                                        hintText: isCountable
                                                            ? 'Product price (DA)'
                                                            : 'Product price (DA/KG)',
                                                        focusedBorder:
                                                            const OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        enabledBorder:
                                                            const OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        hintStyle: TextStyle(
                                                          fontFamily: 'Mukta',
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      validator:
                                                          (String? value) {
                                                        return (value as String)
                                                                .isEmpty
                                                            ? 'Price Missing!'
                                                            : null;
                                                      },
                                                      onSaved: (String? value) {
                                                        price = double.parse(
                                                            value!);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5.0),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10.0),
                                                child: Text(
                                                  "Quantity:",
                                                  style: TextStyle(
                                                    fontFamily: 'Mukta',
                                                    fontSize: 17.5 * scale,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueGrey[900],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: inputHeight > 50
                                                    ? inputHeight
                                                    : 50,
                                                width: width / 1.2 / 1.5,
                                                child: Container(
                                                  color: Colors.grey[300],
                                                  child: Theme(
                                                    data: Theme.of(context).copyWith(
                                                        textSelectionTheme:
                                                            TextSelectionThemeData(
                                                                selectionColor:
                                                                    Colors.teal[
                                                                        100],
                                                                cursorColor:
                                                                    Colors.grey[
                                                                        600])),
                                                    child: TextFormField(
                                                      validator:
                                                          (String? value) {
                                                        return (value as String)
                                                                .isEmpty
                                                            ? 'Quantity Missing!'
                                                            : null;
                                                      },
                                                      onSaved: (String? value) {
                                                        quantity = double.parse(
                                                            value!);
                                                      },
                                                      controller:
                                                          quantityController,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        fontSize: 20 * scale,
                                                      ),
                                                      textInputAction:
                                                          TextInputAction.done,
                                                      decoration:
                                                          InputDecoration(
                                                        errorStyle: TextStyle(
                                                            fontSize: 0.01),
                                                        hintText: isCountable
                                                            ? 'Quantity available.'
                                                            : 'Quantity available (KG)',
                                                        focusedBorder:
                                                            const OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        enabledBorder:
                                                            const OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        hintStyle: TextStyle(
                                                          fontFamily: 'Mukta',
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5.0),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10.0),
                                                child: Text(
                                                  "Min Quantity:",
                                                  style: TextStyle(
                                                    fontFamily: 'Mukta',
                                                    fontSize: 17.5 * scale,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueGrey[900],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: inputHeight > 50
                                                    ? inputHeight
                                                    : 50,
                                                width: width / 1.2 / 1.5,
                                                child: Container(
                                                  color: Colors.grey[300],
                                                  child: Theme(
                                                    data: Theme.of(context).copyWith(
                                                        textSelectionTheme:
                                                            TextSelectionThemeData(
                                                                selectionColor:
                                                                    Colors.teal[
                                                                        100],
                                                                cursorColor:
                                                                    Colors.grey[
                                                                        600])),
                                                    child: TextFormField(
                                                      controller:
                                                          quantityMinController,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        fontSize: 20 * scale,
                                                      ),
                                                      textInputAction:
                                                          TextInputAction.done,
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: isCountable
                                                            ? 'Minimum Quantity.'
                                                            : 'Minimum Quantity (KG)',
                                                        focusedBorder:
                                                            const OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        errorStyle: TextStyle(
                                                            fontSize: 0.01),
                                                        enabledBorder:
                                                            const OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        hintStyle: TextStyle(
                                                          fontFamily: 'Mukta',
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      onSaved: (String? value) {
                                                        value != null &&
                                                                value.isNotEmpty
                                                            ? quantityMin =
                                                                double.parse(
                                                                    value)
                                                            : null;
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 15.0),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                isCountable = !isCountable;
                                              });
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  isCountable
                                                      ? "Is this countable? (X1) "
                                                      : "Is this countable? (Kg) ",
                                                  style: TextStyle(
                                                    fontFamily: 'Mukta',
                                                    fontSize: 20 * scale,
                                                  ),
                                                ),
                                                Icon(
                                                  isCountable
                                                      ? Icons.check_box_rounded
                                                      : Icons
                                                          .check_box_outline_blank_rounded,
                                                  color: isCountable
                                                      ? Colors.tealAccent[400]
                                                      : Colors.grey[500],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 5.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                    },
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        fontFamily: 'Mukta',
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      isValid = updateProductKey.currentState!
                                          .validate();
                                      print("Processing");
                                      if (isValid) {
                                        updateProductKey.currentState!.save();
                                        File? image = !kIsWeb
                                            ? await _fileFromImageUrl(
                                                imageList[productObj]!)
                                            : null;
                                        if (!kIsWeb &&
                                            (productObj.title != label ||
                                                productObj.price != price ||
                                                productObj.quantity !=
                                                    quantity ||
                                                productObj.minQuantity !=
                                                    quantityMin ||
                                                productObj.isCountable !=
                                                    isCountable ||
                                                image != _profilePicture)) {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            backgroundColor:
                                                Colors.blueGrey[900],
                                            dismissDirection:
                                                DismissDirection.up,
                                            content: const Text(
                                              "Trying to modify the product in stock...",
                                              style: TextStyle(
                                                  fontFamily: 'Mukta'),
                                            ),
                                          ));
                                          Map<String, dynamic> productInfo = {
                                            "id": productObj.id.toString(),
                                            "label": label,
                                            "price": price,
                                            "quantity": quantity,
                                            "quantityMin": quantityMin,
                                            "isCountable": isCountable,
                                          };
                                          await editProduct(productInfo);
                                          await uploadProductToStorage(
                                              FirebaseAuth
                                                  .instance.currentUser!,
                                              productInfo);
                                        } else if (kIsWeb &&
                                            (productObj.title != label ||
                                                productObj.price != price ||
                                                productObj.quantity !=
                                                    quantity ||
                                                productObj.minQuantity !=
                                                    quantityMin ||
                                                productObj.isCountable !=
                                                    isCountable)) {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            backgroundColor:
                                                Colors.blueGrey[900],
                                            dismissDirection:
                                                DismissDirection.up,
                                            content: const Text(
                                              "Trying to modify the product in stock...",
                                              style: TextStyle(
                                                  fontFamily: 'Mukta'),
                                            ),
                                          ));
                                          Map<String, dynamic> productInfo = {
                                            "id": productObj.id.toString(),
                                            "label": label,
                                            "price": price,
                                            "quantity": quantity,
                                            "quantityMin": quantityMin,
                                            "isCountable": isCountable,
                                          };
                                          await editProduct(productInfo);
                                        } else {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            backgroundColor:
                                                Colors.blueGrey[900],
                                            dismissDirection:
                                                DismissDirection.up,
                                            content: const Text(
                                              "No changes were made to the product.",
                                              style: TextStyle(
                                                  fontFamily: 'Mukta'),
                                            ),
                                          ));
                                        }
                                      }
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.tealAccent[400]!),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                        ),
                                      ),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          15.0, 8.0, 15.0, 8.0),
                                      child: Text(
                                        "Update",
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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

  File? _profilePicture;

  editProduct(Map info) {
    bool checked = false;
    for (var product in listOfProducts) {
      if (product.id.toString() == info["id"]) {
        checked = true;
      }
      if (product.id.toString() != info["id"] &&
          product.title == info["label"]) {
        checked = false;
      }
    }
    checked
        ? _dbref!.child(info["id"]).update({
            "Name": capFix(info["label"]),
            "Price": info["price"],
            "Quantity": info["quantity"],
            "minQuantity": info["quantityMin"],
            "isCountable": info["isCountable"],
          }).then((value) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.blueGrey[900],
              dismissDirection: DismissDirection.up,
              content: const Text(
                "Product modified successfully.",
                style: TextStyle(fontFamily: 'Mukta'),
              ),
            ));
          }).catchError((onError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              dismissDirection: DismissDirection.up,
              content: Text(
                "Couldn't modify the product, reason: " + onError.toString(),
                style: const TextStyle(fontFamily: 'Mukta'),
              ),
            ));
          })
        : ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            dismissDirection: DismissDirection.up,
            content: Text(
              "There's another product with this name!",
              style: TextStyle(fontFamily: 'Mukta'),
            ),
          ));
  }

  Future<ImageSource?> showOptionsMenu(BuildContext context) async {
    if (Platform.isIOS && !kIsWeb) {
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
    } else if (Platform.isAndroid && !kIsWeb) {
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
        content: const Text(
          "This function is not supported in Web.",
          style: TextStyle(fontFamily: 'Mukta'),
        ),
      ));
    }
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
}
