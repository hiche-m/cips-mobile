import 'dart:async';
import 'package:application/Pages/home.dart';
import 'package:application/client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:application/FirebaseCloudFunctions.dart';
import 'package:application/ProductClass.dart';
import 'package:application/Widgets/dialogWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class Menu extends StatefulWidget {
  Menu({Key? key, required this.instance, required this.data})
      : super(key: key);

  FirebaseAuth instance;
  Map data;

  @override
  State<Menu> createState() => _MenuState(instance: instance, data: data);
}

String query = "";
var selected = 0;
List<ProductObj> cart = [];
bool arranged = false;
bool arrangedT = false;
bool arrangedP = false;
bool arrangedQ = false;
bool asc = true;
double? textScale;
var imagesMap = new Map();
List<ProductObj> listOfProducts = [];
List<ProductObj> productsBackup = [];
bool net = false;

/*                                                                              State Class*/
class _MenuState extends State<Menu> with AutomaticKeepAliveClientMixin<Menu> {
  int imageBox = 90;
  String? dataString;
  DatabaseReference? _dbref;
  Map<dynamic, dynamic>? map;
  List<ProductObj> products = listOfProducts;
  FirebaseAuth instance;
  String? oldBarcode;
  Map data;
  double defaultCustomQuantity = 50;
  late TextEditingController customQuantityController;

  _MenuState({required this.instance, required this.data});

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    if (_dbref == null || data['ownerUID'].toString().isNotEmpty) {
      _dbref =
          FirebaseDatabase.instance.ref().child("Users/${data['ownerUID']}");
    }
    getProducts();

    super.initState();
  }

  getProducts() {
    var images = {};
    try {
      net = false;
      _dbref!.child("Products").onValue.listen((event) {
        if (event.snapshot.value != null) {
          dataString = jsonEncode(event.snapshot.value);
          map = jsonDecode(dataString!);
          listOfProducts = [];
          productsBackup = [];
          map!.forEach((idKey, element) async {
            if (element['Img'].toString().isEmpty &&
                element['minQuantity'] == null) {
              listOfProducts.add(
                ProductObj(
                  id: int.parse(idKey),
                  title: element['Name'],
                  price: element['Price'].toDouble(),
                  picture: element['Img'],
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

            if (!listOfProducts.last.isCountable) {
              listOfProducts.last.quantity =
                  listOfProducts.last.quantity * 1000;
              listOfProducts.last.minQuantity =
                  listOfProducts.last.minQuantity * 1000;
            }
            images[listOfProducts.last] =
                await getProductUrl(listOfProducts.last.picture);
            setState(() {});
          });
          productsBackup = listOfProducts;
          clearSelected();
          clearSearch();
          setState(() {});
        } else {
          listOfProducts = [];
          productsBackup = [];
          images.clear();
        }
        imagesMap = images;
      });

      ProductObj? object;
      barcodeStream.listen((barcodeEvent) {
        listOfProducts.forEach((product) {
          if (product.id.toString() == barcodeEvent) {
            object = product;
          }
        });

        listOfProducts.isNotEmpty
            ? object != null
                ? setState(() {
                    addQuantityToProduct(object!);
                  })
                : null
            : print("List Empty");
      });
    } on Exception {
      setState(() {
        net = true;
      });
    }
  }

  int gramDefault = 50;
  late bool available;
  final searchController = TextEditingController();
  Client? client;

  addQuantityToProduct(ProductObj productObj) async {
    bool countable = productObj.isCountable;
    dynamic selectedQuantity = await showSelectionDialog(productObj);
    if (selectedQuantity == null) return;

    selectedQuantity = double.parse(selectedQuantity);
    countable ? null : selectedQuantity = selectedQuantity / 50;
    selectedQuantity != 0
        ? productObj.selection == 0
            ? setState(() {
                clearSearch();
                searchController.clear();
                select(
                    object: productObj,
                    array: listOfProducts,
                    selected: selected);
                selected++;
                productObj.selection = selectedQuantity;
                removeDuplicates();
                arranged = false;
                arrangedQ = false;
                arrangedT = false;
                arrangedP = false;
              })
            : setState(() {
                clearSearch();
                searchController.clear();
                productObj.selection = selectedQuantity;
              })
        : setState(() {
            productObj.selection = 0;
            clearSearch();
            searchController.clear();
            unselect(
                object: productObj, array: listOfProducts, selected: selected);
            selected--;
            arranged = false;
            arrangedQ = false;
            arrangedT = false;
            arrangedP = false;
          });
  }

  /*                                                                            Product Template*/
  Widget productTemplate(ProductObj productObj) {
    available = true;
    bool countable = productObj.isCountable;
    double productTotal = productObj.price * productObj.selection;
    double selectionTotal = productObj.selection;

    if (!countable) {
      selectionTotal = productObj.selection * gramDefault;
      productTotal = selectionTotal * productObj.price / 1000;
    }
    /*                                                                          Product Template*/
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10.0 / heightScale!,
        ),
        Expanded(
          child: Column(
            children: [
              ClipPath(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    /*                                                          Title Container*/
                    InkWell(
                      onDoubleTap: available
                          ? () {
                              setState(() {
                                !arranged || !arrangedT
                                    ? arrangeByTitle(
                                        dataP: listOfProducts,
                                        ascending: asc,
                                        selectedNum: selected)
                                    : null;
                                arranged = true;
                                arrangedQ = false;
                                arrangedT = true;
                                arrangedP = false;
                              });
                            }
                          : null,
                      onTap: available
                          ? () {
                              productObj.selection == 0
                                  ? setState(() {
                                      clearSearch();
                                      searchController.clear();
                                      select(
                                          object: productObj,
                                          array: listOfProducts,
                                          selected: selected);
                                      selected++;
                                      listOfProducts[selected - 1].selection +=
                                          1;
                                      removeDuplicates();
                                      arranged = false;
                                      arrangedQ = false;
                                      arrangedT = false;
                                      arrangedP = false;
                                    })
                                  : null;
                            }
                          : null,
                      child: Container(
                        color:
                            available ? Colors.blueGrey[900] : Colors.grey[400],
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              productObj.minQuantity >= productObj.quantity
                                  ? Icon(
                                      Icons.warning_rounded,
                                      size: 15.0,
                                      color: Colors.red,
                                    )
                                  : SizedBox(),
                              SizedBox(width: 2.0),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      height: 1.0 / heightScale!,
                                      width: 1.0 * widthScale!,
                                    ),
                                    Flexible(
                                      child: Text(
                                        productObj.title,
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          fontSize: 15.0,
                                          color: available
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 1.0 / heightScale!,
                                      width: 1.0 * widthScale!,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    /*                                                          Image Container*/
                    GestureDetector(
                      onTap: available
                          ? () {
                              productObj.selection == 0
                                  ? setState(() {
                                      clearSearch();
                                      searchController.clear();
                                      select(
                                          object: productObj,
                                          array: listOfProducts,
                                          selected: selected);
                                      selected++;
                                      listOfProducts[selected - 1].selection +=
                                          1;
                                      removeDuplicates();
                                      arranged = false;
                                      arrangedQ = false;
                                      arrangedT = false;
                                      arrangedP = false;
                                    })
                                  : null;
                            }
                          : null,
                      onLongPress: () {
                        addQuantityToProduct(productObj);
                      },
                      child: Stack(
                        children: [
                          SafeArea(
                            child: Container(
                              height: imageBox / heightScale!,
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                image: imagesMap[productObj] != null
                                    ? Image.network(imagesMap[productObj]).image
                                    : AssetImage("assets/products/None.jpg"),
                                fit: BoxFit.cover,
                              )),
                              foregroundDecoration: !available
                                  ? BoxDecoration(
                                      color: Colors.grey,
                                      backgroundBlendMode: BlendMode.saturation,
                                    )
                                  : null,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: SizedBox(
                                  height: imageBox / heightScale!,
                                ),
                              ),
                              /*                                                Minus button*/
                              Flexible(
                                child: FlatButton(
                                  onPressed: productObj.selection > 0
                                      ? () {
                                          setState(() {
                                            productObj.selection == 1
                                                ? setState(() {
                                                    productObj.selection = 0;
                                                    clearSearch();
                                                    searchController.clear();
                                                    unselect(
                                                        object: productObj,
                                                        array: listOfProducts,
                                                        selected: selected);
                                                    selected--;
                                                    arranged = false;
                                                    arrangedQ = false;
                                                    arrangedT = false;
                                                    arrangedP =
                                                        false; /* 
                                                    subtotal -= productTotal;
                                                    subtotal +=
                                                        productTotal; */
                                                  })
                                                : {
                                                    (productObj.selection -= 1),
                                                  };
                                          });
                                        }
                                      : null,
                                  color: Colors.red,
                                  shape: const CircleBorder(),
                                  child: Text(
                                    productObj.selection > 0
                                        ? countable
                                            ? "-"
                                            : "-"
                                        : "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  minWidth: 40.0 / widthScale!,
                                  height: 40.0 / heightScale!,
                                ),
                              ),
                              /*                                                Plus button*/
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      2.0, 0.0, 0.0, 0.0),
                                  child: FlatButton(
                                    onPressed: productObj.selection > 0
                                        ? () {
                                            setState(() {
                                              productObj.selection += 1;
                                            });
                                          }
                                        : null,
                                    color: productObj.selection > 0
                                        ? productObj.quantity >
                                                productObj.selection
                                            ? Colors.blueGrey[900]
                                            : Colors.red[700]
                                        : Colors.transparent,
                                    shape: const CircleBorder(),
                                    minWidth: 40.0 / widthScale!,
                                    height: 40.0 / heightScale!,
                                    child: Text(
                                      productObj.selection > 0
                                          ? countable
                                              ? "+"
                                              : "+"
                                          : "",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    /*                                                          Price Container*/
                    InkWell(
                      onDoubleTap: available
                          ? () {
                              setState(() {
                                !arranged || !arrangedP
                                    ? arrangeByPrice(
                                        dataP: listOfProducts,
                                        ascending: asc,
                                        selectedNum: selected)
                                    : null;
                                arranged = true;
                                arrangedP = true;
                                arrangedQ = false;
                                arrangedT = false;
                              });
                            }
                          : null,
                      onTap: available
                          ? () {
                              productObj.selection == 0
                                  ? setState(() {
                                      clearSearch();
                                      searchController.clear();
                                      select(
                                          object: productObj,
                                          array: listOfProducts,
                                          selected: selected);
                                      removeDuplicates();
                                      selected++;
                                      listOfProducts[selected - 1].selection +=
                                          1;
                                      removeDuplicates();
                                      arranged = false;
                                      arrangedQ = false;
                                      arrangedT = false;
                                      arrangedP = false;
                                    })
                                  : null;
                            }
                          : null,
                      child: Container(
                        color: available
                            ? productObj.selection > 0
                                ? Colors.tealAccent[400]
                                : Colors.blueGrey[900]
                            : Colors.grey[400],
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              countable
                                  ? productObj.selection >= 1
                                      ? "${productTotal.toStringAsFixed(2)} DA"
                                      : "${productObj.price.toStringAsFixed(2)} DA"
                                  : productObj.selection >= 1
                                      ? "${productTotal.toStringAsFixed(2)} DA/KG"
                                      : "${productObj.price.toStringAsFixed(2)} DA/KG",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    available ? Colors.white : Colors.grey[600],
                              ),
                              softWrap: false,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                clipper: const ShapeBorderClipper(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.0),
                        bottomRight: Radius.circular(10.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
        /*                                                                      Right Side*/
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*                                                                  Delete Button*/
            InkWell(
              onTap: productObj.selection > 0
                  ? () {
                      setState(() {
                        productObj.selection = 0;
                        clearSearch();
                        searchController.clear();
                        unselect(
                            object: productObj,
                            array: listOfProducts,
                            selected: selected);
                        selected--;
                        arranged = false;
                        arrangedQ = false;
                        arrangedT = false;
                        arrangedP = false;
                      });
                    }
                  : null,
              radius: 17.5,
              child: CircleAvatar(
                radius: 6.5,
                backgroundColor: productObj.selection > 0
                    ? Colors.grey[300]
                    : Colors.transparent,
                child: CircleAvatar(
                  radius: 5.5,
                  backgroundColor: productObj.selection > 0
                      ? Colors.red
                      : Colors.transparent,
                  child: Text(
                    "-",
                    style: TextStyle(
                        color: productObj.selection > 0
                            ? Colors.white
                            : Colors.transparent,
                        fontSize: 10.0),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SizedBox(
                height: (imageBox + gramDefault) / heightScale!,
              ),
            ),
            /*                                                                  Number of selected*/
            Text(
              productObj.selection > 0
                  ? countable
                      ? 'X${selectionTotal.toStringAsFixed(0)}'
                      : '${selectionTotal}g'
                  : "",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15.0,
                fontFamily: 'Bebas Neue',
              ),
              overflow: TextOverflow.fade,
            ),
          ],
        ),
      ],
    );
  }

/*                                                                              Search Controller Method*/
  void searchFilter(String queryNew) {
    List<ProductObj> dataL = [];
    List<ProductObj> instance =
        listOfProducts.sublist(selected, listOfProducts.length);
    List<ProductObj> instance2 = listOfProducts.sublist(0, selected);

    for (var item in instance) {
      if (item.title.toLowerCase().contains(queryNew.toLowerCase())) {
        dataL.add(item);
      }
    }
    setState(() {
      if (queryNew.isNotEmpty) {
        listOfProducts = [instance2 + dataL].expand((x) => x).toList();
        if (queryNew.length < query.length) {
          resetList();
          dataL = [];
          instance = listOfProducts.sublist(selected, listOfProducts.length);
          for (var item in instance) {
            if (item.title.toLowerCase().contains(queryNew.toLowerCase())) {
              dataL.add(item);
            }
          }
          listOfProducts = [instance2 + dataL].expand((x) => x).toList();
        }
      }
      queryNew.isEmpty ? resetList() : null;
      query = queryNew;
    });
  }

  barcodeAddProduct(context, setState, String barcode) {
    ProductObj productObj;
    for (var product in listOfProducts) {
      if (product.id.toString() == barcode) {
        productObj = product;
        productObj.quantity > 0
            ? () {
                productObj.selection == 0
                    ? setState(() {
                        select(
                            object: productObj,
                            array: listOfProducts,
                            selected: selected);
                        selected++;
                        listOfProducts[selected - 1].selection += 1;
                        removeDuplicates();
                        arranged = false;
                        arrangedQ = false;
                        arrangedT = false;
                        arrangedP = false;
                      })
                    : null;
              }
            : () {
                setState(() {
                  productObj.selection += 1;
                });
              };
        break;
      }
    }
  }

/*                                                                              Search Reset*/

  double? widthScale;
  double? heightScale;
  void clearSearch() {
    query = "";
    searchController.clear();
    resetList();
  }

  double? height;
  double? width;
/*                                                                              Build Method*/
  @override
  Widget build(BuildContext context) {
    String arrange;
    if (arranged && arrangedT) {
      arrange = "Label ";
    } else if (arranged && arrangedP) {
      arrange = "Price ";
    } else if (arranged && arrangedQ) {
      arrange = "Quantity ";
    } else {
      arrange = "None ";
    }
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    widthScale = 410 / MediaQuery.of(context).size.width;
    heightScale = 790 / MediaQuery.of(context).size.height;
    textScale = MediaQuery.of(context).textScaleFactor;
    double subtotal = 0;
    for (var product in listOfProducts) {
      product.isCountable
          ? subtotal += product.price * product.selection
          : subtotal += product.selection * gramDefault * product.price / 1000;
    }
    super.build(context);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSwatch(
          accentColor: Colors.grey,
        ),
      ),
      child: SafeArea(
          child: !net
              ? GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: Stack(
                    children: [
                      listOfProducts.isNotEmpty
                          ? Container(
                              margin: selected > 0
                                  ? const EdgeInsets.only(top: 100.0)
                                  : null,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 55.0, 20.0, 10.0),
                                      /*                                      Drop down arrange menu*/
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Arrange by:   ",
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          PopupMenuButton(
                                            child: Row(
                                              children: [
                                                Text("$arrange"),
                                                Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    size: 15.0),
                                              ],
                                            ),
                                            onSelected: (item) {
                                              if (item == 1) {
                                                setState(() {
                                                  !arranged || !arrangedT
                                                      ? arrangeByTitle(
                                                          dataP: listOfProducts,
                                                          ascending: asc,
                                                          selectedNum: selected)
                                                      : null;
                                                  arranged = true;
                                                  arrangedQ = false;
                                                  arrangedT = true;
                                                  arrangedP = false;
                                                });
                                              } else if (item == 2) {
                                                setState(() {
                                                  !arranged || !arrangedP
                                                      ? arrangeByPrice(
                                                          dataP: listOfProducts,
                                                          ascending: asc,
                                                          selectedNum: selected)
                                                      : null;
                                                  arranged = true;
                                                  arrangedP = true;
                                                  arrangedQ = false;
                                                  arrangedT = false;
                                                });
                                              } else {
                                                setState(() {
                                                  !arranged || !arrangedQ
                                                      ? arrangeByQuantity(
                                                          dataP: listOfProducts,
                                                          ascending: asc,
                                                          selectedNum: selected)
                                                      : null;
                                                  arranged = true;
                                                  arrangedP = false;
                                                  arrangedQ = true;
                                                  arrangedT = false;
                                                });
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                height: 30.0,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Label",
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        color: Colors.grey[900],
                                                      ),
                                                    ),
                                                    arranged && arrangedT
                                                        ? Icon(
                                                            Icons.check_rounded,
                                                            size: 15.0)
                                                        : SizedBox(),
                                                  ],
                                                ),
                                                value: 1,
                                              ),
                                              PopupMenuItem(
                                                height: 30.0,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Price",
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        color: Colors.grey[900],
                                                      ),
                                                    ),
                                                    arranged && arrangedP
                                                        ? Icon(
                                                            Icons.check_rounded,
                                                            size: 15.0)
                                                        : SizedBox(),
                                                  ],
                                                ),
                                                value: 2,
                                              ),
                                              PopupMenuItem(
                                                height: 30.0,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Quantity",
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        color: Colors.grey[900],
                                                      ),
                                                    ),
                                                    arranged && arrangedQ
                                                        ? Icon(
                                                            Icons.check_rounded,
                                                            size: 15.0)
                                                        : SizedBox(),
                                                  ],
                                                ),
                                                value: 3,
                                              ),
                                            ],
                                          ),
                                          InkWell(
                                            onTap: arranged
                                                ? () {
                                                    setState(() {
                                                      asc = !asc;
                                                      if (arrangedT) {
                                                        arrangeByTitle(
                                                            dataP:
                                                                listOfProducts,
                                                            ascending: asc,
                                                            selectedNum:
                                                                selected);
                                                      } else if (arrangedP) {
                                                        arrangeByPrice(
                                                            dataP:
                                                                listOfProducts,
                                                            ascending: asc,
                                                            selectedNum:
                                                                selected);
                                                      } else if (arrangedQ) {
                                                        arrangeByQuantity(
                                                            dataP:
                                                                listOfProducts,
                                                            ascending: asc,
                                                            selectedNum:
                                                                selected);
                                                      }
                                                    });
                                                  }
                                                : null,
                                            child: Icon(
                                              asc
                                                  ? Icons
                                                      .text_rotation_down_rounded
                                                  : Icons
                                                      .text_rotate_up_rounded,
                                              size: 20.0,
                                              color: arranged
                                                  ? Colors.black
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    /*                                                  Grid View*/
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          8, 0, 8, 20),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        primary: false,
                                        itemCount: listOfProducts.length,
                                        itemBuilder: ((context, index) =>
                                            productTemplate(
                                                listOfProducts[index])),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          childAspectRatio: 3 / 4,
                                          crossAxisSpacing: 5.0 * widthScale!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 120,
                                        width: 90,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage(
                                                    "assets/products/NoItems.png"),
                                                fit: BoxFit.fitWidth)),
                                      ),
                                      Text(
                                        "No products.",
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 50.0),
                                    child: TextButton(
                                      onPressed: () {
                                        pageController.animateToPage(3,
                                            duration: const Duration(
                                                milliseconds: 75),
                                            curve: Curves.ease);
                                      },
                                      child: Text(
                                        data['isAdmin']
                                            ? "Add a new item"
                                            : "Go to settings",
                                        style: TextStyle(
                                            color: Colors.tealAccent[400]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      /*                                                        Floating Menu*/
                      selected > 0
                          ? GestureDetector(
                              onTap: () {
                                /*                                              Calling showModalBottomSheet*/
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return buildSheet();
                                  },
                                  isDismissible: true,
                                  enableDrag: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 45.0),
                                child: PhysicalModel(
                                  color: Colors.black,
                                  elevation: 8.0,
                                  child: Container(
                                    height: 85.0,
                                    color: Colors.grey[50],
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 15.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Total:  ",
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontFamily: 'Mukta',
                                                  ),
                                                ),
                                                Text(
                                                  "$subtotal.00 DA",
                                                  style: const TextStyle(
                                                      fontSize: 15.0,
                                                      fontFamily: 'Mukta',
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 5.0, right: 12.0),
                                                child: SizedBox(
                                                  height: 45.0,
                                                  child: PlatformIconButton(
                                                    onPressed: () async {
                                                      final action =
                                                          await DialogWidget
                                                              .yesCancelDialog(
                                                                  context,
                                                                  "Empty cart?",
                                                                  "This will empty your cart from any selected products.",
                                                                  Colors.red);
                                                      if (action ==
                                                          DialogAction.yes) {
                                                        setState(() {
                                                          arranged = false;
                                                          arrangedQ = false;
                                                          arrangedT = false;
                                                          arrangedP = false;
                                                          clearSelected();
                                                        });
                                                      }
                                                    },
                                                    icon: const FaIcon(
                                                      FontAwesomeIcons.trashCan,
                                                      size: 25.0,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 25.0),
                                                child: SizedBox(
                                                  height: 50.0,
                                                  child: RaisedButton(
                                                    onPressed: () async {
                                                      final action = await DialogWidget
                                                          .yesCancelDialog(
                                                              context,
                                                              "Validate purchase?",
                                                              "This will validate this purchase transaction.",
                                                              Colors.tealAccent[
                                                                  400]);
                                                      if (action ==
                                                          DialogAction.yes) {
                                                        setState(() {
                                                          String clientId = client !=
                                                                  null
                                                              ? "C" +
                                                                  DateFormat(
                                                                          "yyyyMMddTkkmmss")
                                                                      .format(client!
                                                                          .date!) +
                                                                  "00"
                                                              : "";
                                                          validatePurchase(
                                                              subtotal,
                                                              clientId);
                                                          arranged = false;
                                                          arrangedQ = false;
                                                          arrangedT = false;
                                                          arrangedP = false;
                                                          clearSelected();
                                                        });
                                                      }
                                                    },
                                                    color:
                                                        Colors.tealAccent[400],
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18.0),
                                                      side: BorderSide(
                                                          color:
                                                              Colors.tealAccent[
                                                                  400]!),
                                                    ),
                                                    child: Row(
                                                      children: const [
                                                        Padding(
                                                          padding: EdgeInsets
                                                              .fromLTRB(7.5, 0,
                                                                  10.0, 0),
                                                          child: Text(
                                                            "Checkout",
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'Mukta',
                                                                fontSize: 17.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  right: 3.0),
                                                          child: FaIcon(
                                                            FontAwesomeIcons
                                                                .check,
                                                            color: Colors.white,
                                                            size: 20.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
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
                            )
                          : Container(),
                      /*                                                                      Search Bar*/
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(1.0, 2.0, 5.0, 0),
                              child: Container(
                                height: 40.0,
                                child: PlatformTextField(
                                  autofocus: false,
                                  controller: searchController,
                                  material: (_, __) => MaterialTextFieldData(
                                    decoration: InputDecoration(
                                      hintText: 'Search for a product',
                                      contentPadding:
                                          const EdgeInsets.only(left: 15.0),
                                      border: const OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon:
                                          const Icon(Icons.search_rounded),
                                      suffixIcon: searchController
                                              .text.isNotEmpty
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
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  style: TextStyle(
                                      fontSize: 15.0, color: Colors.grey[600]),
                                  onChanged: searchFilter,
                                ),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 250, 250, 250),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(15.0)),
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
                            radius: (25.0 * widthScale!) / 2,
                            backgroundColor: Colors.white,
                            child: InkWell(
                              onTap: () async {
                                final action =
                                    await DialogWidget.yesCancelDialog(
                                        context,
                                        "Refresh List?",
                                        "This will empty your cart.",
                                        Colors.blueGrey[700]);
                                if (action == DialogAction.yes) {
                                  setState(() {
                                    clearSelected();
                                  });
                                  super.setState(() {});
                                }
                              },
                              child: Icon(
                                Icons.replay_circle_filled_rounded,
                                size: 25.0 * widthScale!,
                                color: Colors.blueGrey[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: width! / 4,
                      width: width! / 4,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/icons/No_net.png"),
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Text("Something went wrong, please try again later.",
                        style: TextStyle(
                            fontFamily: 'Mukta', color: Colors.grey[700])),
                  ],
                ))),
    );
  }

  DraggableScrollableController? _controller;

  validatePurchase(double subtotal, String clientId) {
    _dbref!
        .child("Transactions")
        .child(DateFormat("yyyyMMddTHHmmss").format(DateTime.now()))
        .set({
          "clientId": clientId,
          "subtotal": subtotal,
        })
        .then((value) {})
        .catchError((onError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.blueGrey[900],
            dismissDirection: DismissDirection.up,
            content: Text("Couldn't proceed with the transaction, reason: " +
                onError.toString()),
          ));
        });

    cart.forEach((cartItem) async {
      ProductObj unCountObj;
      if (cartItem.isCountable) {
        unCountObj = cartItem;
      } else {
        unCountObj = ProductObj(
          id: cartItem.id,
          isCountable: cartItem.isCountable,
          price: cartItem.price,
          quantity: cartItem.quantity / 1000,
          title: cartItem.title,
          minQuantity: cartItem.minQuantity / 1000,
          picture: cartItem.picture,
          selection: cartItem.selection * 50 / 1000,
        );
      }
      double selected = unCountObj.selection;
      int id = cartItem.id;
      _dbref!
          .child("Transactions")
          .child(DateFormat("yyyyMMddTHHmmss").format(DateTime.now()))
          .child("products")
          .child(cartItem.id.toString())
          .set({
        "label": cartItem.title,
        "price": unCountObj.price,
        "quantity": unCountObj.selection,
        "isCountable": cartItem.isCountable,
      });

      _dbref!.child("Products").get().then((snapshot) {
        Map<dynamic, dynamic>? mapS;
        String? dataStringS;

        if (snapshot.value != null) {
          dataStringS = jsonEncode(snapshot.value);
          mapS = jsonDecode(dataStringS);
          mapS!.forEach((key, value) {
            double newQuantity = value["Quantity"] - selected;
            if (key.toString() == id.toString()) {
              _dbref!.child("Products").child(id.toString()).update({
                "Quantity": newQuantity,
              }).catchError((onError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.blueGrey[900],
                  dismissDirection: DismissDirection.up,
                  content: Text(
                      "Something went wrong, Error: " + onError.toString()),
                ));
              });
            }
          });
        }
      }).catchError((e) => print("Error"));
    });
  }

  /* updateClient(double subtotal, String id) {
    _dbref!
        .child("Clients")
        .child(id)
        .update({
          "clientId": "",
          "subtotal": subtotal,
        })
        .then((value) {})
        .catchError((onError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.blueGrey[900],
            dismissDirection: DismissDirection.up,
            content: Text("Couldn't proceed with the transaction, reason: " +
                onError.toString()),
          ));
        });

    cart.forEach((cartItem) async {
      ProductObj unCountObj;
      if (cartItem.isCountable) {
        unCountObj = cartItem;
      } else {
        unCountObj = ProductObj(
          id: cartItem.id,
          isCountable: cartItem.isCountable,
          price: cartItem.price,
          quantity: cartItem.quantity / 1000,
          title: cartItem.title,
          minQuantity: cartItem.minQuantity / 1000,
          picture: cartItem.picture,
          selection: cartItem.selection * 50 / 1000,
        );
      }
      double selected = unCountObj.selection;
      int id = cartItem.id;
      _dbref!
          .child("Transactions")
          .child(DateFormat("yyyyMMddTHHmmss").format(DateTime.now()))
          .child("products")
          .child(cartItem.id.toString())
          .set({
        "label": cartItem.title,
        "price": unCountObj.price,
        "quantity": unCountObj.selection,
        "isCountable": cartItem.isCountable,
      });

      _dbref!.child("Products").get().then((snapshot) {
        Map<dynamic, dynamic>? mapS;
        String? dataStringS;

        if (snapshot.value != null) {
          dataStringS = jsonEncode(snapshot.value);
          mapS = jsonDecode(dataStringS);
          mapS!.forEach((key, value) {
            double newQuantity = value["Quantity"] - selected;
            if (key.toString() == id.toString()) {
              _dbref!.child("Products").child(id.toString()).update({
                "Quantity": newQuantity,
              }).catchError((onError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.blueGrey[900],
                  dismissDirection: DismissDirection.up,
                  content: Text(
                      "Something went wrong, Error: " + onError.toString()),
                ));
              });
            }
          });
        }
      }).catchError((e) => print("Error"));
    });
  }
 */

  List<Client> clientList = [];

  getClients() async {
    await _dbref!.child('Clients').get().then((docs) {
      clientList = [];
      Map docsMap = docs.value as Map;
      docsMap.forEach((idKey, element) {
        clientList.add(
          Client(
            element['name'],
            date: DateTime.parse(
                idKey.toString().substring(1, idKey.toString().length - 2)),
            income: element['income'],
            number: element['number'],
            picture: element['imgUrl'].toString().isNotEmpty
                ? element['imgUrl']
                : 'assets/icons/Default_PP.png',
            tab: element['tab'],
            tabDate: element['nextPayment'].toString().isNotEmpty
                ? DateTime.parse(element['nextPayment'].toString())
                : DateTime.now(),
          ),
        );
      });
    });
  }

/*                                                                              Build Sheet Function*/
  buildSheet() {
    return DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: 0.5,
        expand: false,
        controller: _controller,
        builder: (_, controller) => StatefulBuilder(
              builder: (context, setState) {
                selected == 0 ? Navigator.of(context).pop() : null;
                double subtotal = 0;
                for (var product in listOfProducts) {
                  product.isCountable
                      ? subtotal += product.price * product.selection
                      : subtotal += product.selection *
                          gramDefault *
                          product.price /
                          1000;
                }
                return Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15.0),
                    ),
                    color: Colors.white,
                  ),
                  //Child
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
                    child: ListView(
                      controller: controller,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: selected,
                          primary: false,
                          itemBuilder: (context, index) {
                            ProductObj productObj = cart[index];
                            bool countable = productObj.isCountable;
                            double productTotal =
                                productObj.price * productObj.selection;
                            double selectionTotal = productObj.selection;
                            if (!countable) {
                              selectionTotal =
                                  productObj.selection * gramDefault;
                              productTotal =
                                  selectionTotal * productObj.price / 1000;
                            }
                            return Slidable(
                              endActionPane: ActionPane(
                                motion: const StretchMotion(),
                                dragDismissible: true,
                                children: [
                                  SlidableAction(
                                    flex: 1,
                                    onPressed: productObj.selection > 0
                                        ? (context) {
                                            setState(() {
                                              productObj.selection += 1;
                                            });
                                            this.setState(() {});
                                            super.setState(() {});
                                          }
                                        : addWhenZero(productObj),
                                    backgroundColor: Colors.blueGrey[900]!,
                                    foregroundColor: Colors.white,
                                    icon: Icons.add_outlined,
                                  ),
                                  SlidableAction(
                                    flex: 1,
                                    onPressed: ((context) {
                                      setState(() {
                                        removeOne(productObj);
                                      });
                                      this.setState(() {});
                                      super.setState(() {});
                                    }),
                                    backgroundColor: Colors.blueGrey[800]!,
                                    foregroundColor: Colors.white,
                                    icon: Icons.remove_rounded,
                                  ),
                                  SlidableAction(
                                    flex: 2,
                                    onPressed: ((context) {
                                      cart.remove(productObj);
                                      setState(() {
                                        deleteAll(productObj);
                                      });
                                      this.setState(() {});
                                    }),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_forever,
                                  ),
                                ],
                              ),
                              child: Builder(builder: (context) {
                                if (cart.isEmpty) {
                                  Navigator.of(context).pop();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            productObj.title,
                                            style: const TextStyle(
                                                fontFamily: 'Mukta'),
                                            overflow: TextOverflow.fade,
                                          ),
                                          Text(
                                            countable
                                                ? "  X" +
                                                    productObj.selection
                                                        .toString()
                                                : "  " +
                                                    selectionTotal.toString() +
                                                    "g",
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontFamily: 'Mukta'),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            countable
                                                ? productObj.price.toString() +
                                                    ".00 DA   "
                                                : productObj.price.toString() +
                                                    ".00 DA/KG   ",
                                            style: const TextStyle(
                                                fontFamily: 'Mukta'),
                                          ),
                                          Text(
                                            countable
                                                ? productTotal.toString() +
                                                    ".00 DA "
                                                : productTotal.toString() +
                                                    ".00 DA/KG ",
                                            style: const TextStyle(
                                                fontFamily: 'Mukta',
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(
                                            width: 5.0,
                                          ),
                                          Icon(
                                            Icons.swipe_left_alt_rounded,
                                            color: Colors.grey,
                                            size: 15.0 * textScale!,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await getClients();
                                    client = await showClientsList();
                                    setState(() {});
                                    client != null ? print(client!.name) : null;
                                  },
                                  child: CircleAvatar(
                                    radius: 15.0 * textScale!,
                                    backgroundColor: Colors.grey,
                                    backgroundImage: client != null
                                        ? const AssetImage(
                                            "assets/icons/Default_PP.png")
                                        : null,
                                  ),
                                ),
                                client != null
                                    ? IconButton(
                                        onPressed: () {
                                          setState(() {
                                            client = null;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.remove_rounded,
                                          color: Colors.red,
                                        ))
                                    : const SizedBox(),
                              ],
                            ),
                            Text(
                              "Subtotal:   " + subtotal.toString() + ".00 DA",
                              style: const TextStyle(
                                fontFamily: 'Mukta',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Dismiss",
                              style: TextStyle(
                                color: Colors.teal,
                                fontFamily: 'Mukta',
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ));
  }

  Future<Client?> showClientsList() {
    return showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: Container(
              height: height! / 2,
              width: width! / 1.2,
              color: Colors.grey.shade50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: height! / 2 / 1.2,
                        width: width! / 1.2,
                        child: ListView.separated(
                          itemCount: clientList.length,
                          separatorBuilder: (context, index) => const Divider(
                              thickness: 1.0, indent: 0.0, endIndent: 0.0),
                          itemBuilder: (context, index) {
                            Client client = clientList[index];
                            return Material(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop(client);
                                },
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.grey,
                                  ),
                                  title: Text(client.name),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            child: const Text(
                              "Add on tab",
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                color: Colors.grey,
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
          );
        });
  }

  deleteAll(ProductObj productObj) {
    productObj.selection = 0;
    clearSearch();
    searchController.clear();
    unselect(object: productObj, array: listOfProducts, selected: selected);
    selected--;
    arranged = false;
    arrangedQ = false;
    arrangedT = false;
    arrangedP = false;
  }

  addWhenZero(ProductObj productObj) {
    clearSearch();
    searchController.clear();
    select(object: productObj, array: listOfProducts, selected: selected);
    selected++;
    listOfProducts[selected - 1].selection += 1;
    removeDuplicates();
    arranged = false;
    arrangedQ = false;
    arrangedT = false;
    arrangedP = false;
  }

  removeOne(ProductObj productObj) {
    productObj.selection == 1
        ? this.setState(() {
            productObj.selection = 0;
            clearSearch();
            searchController.clear();
            unselect(
                object: productObj, array: listOfProducts, selected: selected);
            selected--;
            arranged = false;
            arrangedQ = false;
            arrangedT = false;
            arrangedP = false;
            cart.remove(productObj);
          })
        : productObj.selection -= 1;
  }

  removeDuplicates() {
    listOfProducts = listOfProducts.toSet().toList();
    productsBackup = productsBackup.toSet().toList();
  }

  void resetList() {
    listOfProducts = productsBackup;
  }

  clearSelected() {
    selected = 0;
    cart = [];
    resetselection();
    removeDuplicates();
  }

  resetselection() {
    listOfProducts.forEach((element) {
      element.selection = 0;
    });
    productsBackup.forEach((element) {
      element.selection = 0;
    });
  }

  /*                                                                              Arrange by Price Method*/
  arrangeByPrice(
      {required List dataP, required bool ascending, required selectedNum}) {
    List instance = dataP.sublist(selectedNum, dataP.length);
    dataP.removeRange(selectedNum, dataP.length);
    instance.sort((a, b) => a.income.compareTo(b.income));
    dataP.addAll(instance);
    if (!ascending) {
      var dataIns = dataP.sublist(selectedNum, dataP.length);
      dataP.removeRange(selectedNum, dataP.length);
      for (int i = 0; i < dataIns.length / 2; i++) {
        var c = dataIns[i];
        dataIns[i] = dataIns[dataIns.length - 1 - i];
        dataIns[dataIns.length - 1 - i] = c;
      }
      dataP.addAll(dataIns);
    }
  }

/*                                                                              Arrange by title Method*/
  arrangeByTitle(
      {required List dataP, required bool ascending, required selectedNum}) {
    List instance = dataP.sublist(selectedNum, dataP.length);
    dataP.removeRange(selectedNum, dataP.length);
    instance.sort((a, b) => a.title.compareTo(b.title));
    dataP.addAll(instance);
    if (!ascending) {
      var dataIns = dataP.sublist(selectedNum, dataP.length);
      dataP.removeRange(selectedNum, dataP.length);
      for (int i = 0; i < dataIns.length / 2; i++) {
        var c = dataIns[i];
        dataIns[i] = dataIns[dataIns.length - 1 - i];
        dataIns[dataIns.length - 1 - i] = c;
      }
      dataP.addAll(dataIns);
    }
  }

/*                                                                              Arrange by quantity*/
  arrangeByQuantity(
      {required List dataP, required bool ascending, required selectedNum}) {
    List instance = dataP.sublist(selectedNum, dataP.length);
    dataP.removeRange(selectedNum, dataP.length);
    instance.sort((a, b) => a.number.compareTo(b.number));
    dataP.addAll(instance);
    if (!ascending) {
      var dataIns = dataP.sublist(selectedNum, dataP.length);
      dataP.removeRange(selectedNum, dataP.length);
      for (int i = 0; i < dataIns.length / 2; i++) {
        var c = dataIns[i];
        dataIns[i] = dataIns[dataIns.length - 1 - i];
        dataIns[dataIns.length - 1 - i] = c;
      }
      dataP.addAll(dataIns);
    }
  }

/*Select method: Place object at the beginning when selected*/
  select(
      {required ProductObj object,
      required List<ProductObj> array,
      required selected}) {
    array.removeAt(array.indexOf(object));
    array.insert(selected, object);
    cart.add(object);
  }

  Future<String?> showSelectionDialog(ProductObj productObj) {
    customQuantityController = TextEditingController(text: '1');
    customQuantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: customQuantityController.value.text.length);
    return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text(
                "Select Quantity",
                style:
                    TextStyle(fontFamily: 'Mukta', fontWeight: FontWeight.bold),
              ),
              content: Theme(
                data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                        selectionColor: Colors.teal[100])),
                child: SizedBox(
                  height: height! / 3 / 3 >= 65 ? height! / 3 / 3 : 65,
                  child: TextField(
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: height! / 3 / 3 / 2 >= 65
                          ? height! / 3 / 3 / 2
                          : 65 / 2,
                    ),
                    autofocus: true,
                    maxLines: 1,
                    controller: customQuantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 0.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.tealAccent[400]!, width: 1.0),
                      ),
                      hintText: 'Quantity',
                      prefix: productObj.isCountable
                          ? Text(
                              "X",
                              style: TextStyle(
                                fontFamily: 'Bebas Neue',
                                fontSize: height! / 3 / 7 / 2 >= 50
                                    ? height! / 3 / 7 / 2
                                    : 50 / 2,
                              ),
                            )
                          : null,
                      suffix: !productObj.isCountable
                          ? Text(
                              "g",
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: height! / 3 / 7 / 2 >= 50
                                    ? height! / 3 / 7 / 2
                                    : 50 / 2,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: cancelCustom,
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        color: Colors.grey[400],
                      ),
                    )),
                TextButton(
                    onPressed: submit,
                    child: Text(
                      "Set",
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        color: Colors.tealAccent[400],
                      ),
                    )),
              ],
            ));
  }

  submit() {
    Navigator.of(context, rootNavigator: true)
        .pop(customQuantityController.text);
    customQuantityController.dispose();
  }

  cancelCustom() {
    Navigator.of(context, rootNavigator: true).pop();
  }

/*Unselect method: Places unselected object where the selected objects end*/
  unselect(
      {required ProductObj object, required List array, required selected}) {
    array.removeAt(array.indexOf(object));
    array.insert(selected - 1, object);
  }
}
