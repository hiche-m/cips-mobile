import 'dart:convert';
import 'package:application/TransactionClass.dart';
import 'package:application/Widgets/dialogWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class History extends StatefulWidget {
  History({Key? key, required this.instance, required this.data})
      : super(key: key);

  FirebaseAuth instance;
  Map data;

  @override
  State<History> createState() => _HistoryState(instance: instance, data: data);
}

class TransProductObj {
  String label;
  double price;
  double quantity;
  bool isCountable;

  TransProductObj({
    required this.label,
    required this.price,
    required this.quantity,
    required this.isCountable,
  });
}

final searchController = TextEditingController();
late String query;
bool net = false;
Map<dynamic, dynamic>? map;
String? dataString;
List<TransactionObj> listOfTransactions = [];
List<TransactionObj> transactionsBackup = [];

class _HistoryState extends State<History>
    with AutomaticKeepAliveClientMixin<History> {
  FirebaseAuth instance;
  DatabaseReference? _dbref;
  Map data;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  bool fromFilter = false;
  bool toFilter = false;

  //late StreamSubscription disposeVar;

  _HistoryState({required this.instance, required this.data});

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    if (_dbref == null || data['ownerUID'].toString().isNotEmpty) {
      _dbref = FirebaseDatabase.instance
          .ref()
          .child("Users/${data['ownerUID']}/Transactions");
    } else if (_dbref == null && data['ownerUID'].toString().isEmpty) {
      _dbref = FirebaseDatabase.instance
          .ref()
          .child("Users/${instance.currentUser!.uid}/Transactions");
    }
    getTransactions();
    super.initState();
  }

  /* @override
  void dispose() {
    searchController.dispose();
    //disposeVar.cancel();
    super.dispose();
  } */

  getTransactions() {
    try {
      net = false;
      /* disposeVar =  */ _dbref!.orderByKey().onValue.listen((event) {
        listOfTransactions = [];
        transactionsBackup = [];
        if (event.snapshot.value != null) {
          dataString = jsonEncode(event.snapshot.value);
          map = jsonDecode(dataString!);
          listOfTransactions = [];
          transactionsBackup = [];

          map!.forEach((idKey, element) {
            String? dataStringP =
                jsonEncode(event.snapshot.child(idKey + "/products").value);
            Map<dynamic, dynamic>? maP = jsonDecode(dataStringP);
            List<TransProductObj> productList = [];
            maP!.forEach((key, value) {
              productList.add(TransProductObj(
                label: value["label"],
                price: value["price"].toDouble(),
                quantity: value["quantity"].toDouble(),
                isCountable: value["isCountable"],
              ));
            });

            listOfTransactions.add(
              TransactionObj(
                timeStamp: idKey,
                subtotal: element['subtotal'].toDouble(),
                productList: productList,
                clientId: element['clientId'],
              ),
            );
          });
          transactionsBackup = listOfTransactions;
          removeDuplicates();
          clearSearch();
          sortList();
          setState(() {});
        } else {
          listOfTransactions = [];
          transactionsBackup = [];
        }
      });
    } on Exception {
      setState(() {
        net = true;
      });
    }
  }

  buildEditDialog(TransactionObj transaction) {
    double subtotal = transaction.subtotal;
    String edit = DateFormat("yyyyMMddTkkmmss").format(DateTime.now());
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setSuper) {
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  //Dialog object
                  child: Dialog(
                    backgroundColor: Colors.grey[100],
                    //Dialog Size
                    child: SizedBox(
                      height: height / 2,
                      width: width / 1.2,
                      //Dialog content
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            //Dialog title
                            Flexible(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    "Edit transaction",
                                    style: TextStyle(
                                        fontFamily: 'Mukta',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[900]),
                                  ),
                                )),
                            //Transaction info
                            Flexible(
                              flex: 5,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  //Time Column
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(left: 15.0),
                                            child: Text(
                                              "Time:",
                                              style: TextStyle(
                                                fontFamily: 'Mukta',
                                              ),
                                            ),
                                          ),
                                          Text(
                                            DateFormat("EEEE  dd - MM - yyyy  kk:mm")
                                                    .format(DateTime.parse(
                                                        transaction
                                                            .timeStamp)) +
                                                " GMT+1",
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(left: 15.0),
                                            child: Text(
                                              "Edit time:",
                                              style: TextStyle(
                                                fontFamily: 'Mukta',
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            DateFormat("EEEE  dd - MM - yyyy  kk:mm")
                                                    .format(
                                                        DateTime.parse(edit)) +
                                                " GMT+1",
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  //Subtotals column
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setSuper(() {
                                                edit = DateFormat(
                                                        "yyyyMMddTkkmmss")
                                                    .format(DateTime.now());
                                              });
                                              setState(() {});
                                            },
                                            child: const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 15.0),
                                              child: Text(
                                                "Subtotal:",
                                                style: TextStyle(
                                                  fontFamily: 'Mukta',
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            transaction.subtotal
                                                    .toStringAsFixed(2) +
                                                " Da",
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(left: 15.0),
                                            child: Text(
                                              "New subtotal:",
                                              style: TextStyle(
                                                fontFamily: 'Mukta',
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            subtotal.toStringAsFixed(2) + " Da",
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  //Products Listview
                                  SingleChildScrollView(
                                    primary: true,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 250, 250, 250),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(15.0)),
                                        border: Border.all(
                                            width: 2.0,
                                            color: Colors.grey[200]!),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: SizedBox(
                                        height: height / 2 / 2.5,
                                        child: ListView.builder(
                                            primary: false,
                                            itemBuilder: ((context, index) {
                                              bool isLast = (index ==
                                                  transaction
                                                      .productList.length);
                                              TransProductObj product = index <
                                                      transaction
                                                          .productList.length
                                                  ? transaction
                                                      .productList[index]
                                                  : TransProductObj(
                                                      label: "",
                                                      price: 0,
                                                      isCountable: true,
                                                      quantity: 0);
                                              double newQuantity =
                                                  product.quantity;
                                              double newPrice =
                                                  product.price * newQuantity;

                                              if (!isLast) {
                                                return Card(
                                                  child: ListTile(
                                                    leading: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 8.0),
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            product.isCountable
                                                                ? "X" +
                                                                    (product.quantity)
                                                                        .toString()
                                                                : (product.quantity *
                                                                            1000)
                                                                        .toStringAsFixed(
                                                                            2) +
                                                                    " g",
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Bebas Neue',
                                                            ),
                                                          ),
                                                          newQuantity !=
                                                                  product
                                                                      .quantity
                                                              ? Text(
                                                                  product.isCountable
                                                                      ? "X" +
                                                                          (newQuantity)
                                                                              .toString()
                                                                      : (newQuantity * 1000)
                                                                              .toStringAsFixed(2) +
                                                                          " g",
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'Bebas Neue',
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                )
                                                              : SizedBox(),
                                                        ],
                                                      ),
                                                    ),
                                                    title: Text(
                                                      (product.label)
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                      ),
                                                    ),
                                                    subtitle: Row(
                                                      children: [
                                                        Text(
                                                          product.isCountable
                                                              ? "(" +
                                                                  (product.price)
                                                                      .toString() +
                                                                  ")"
                                                              : " (" +
                                                                  (product.price)
                                                                      .toStringAsFixed(
                                                                          2) +
                                                                  ")",
                                                          style: TextStyle(
                                                            fontFamily: 'Mukta',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          product.isCountable
                                                              ? " " +
                                                                  (product.price *
                                                                          product
                                                                              .quantity)
                                                                      .toString()
                                                              : " " +
                                                                  (product.price *
                                                                          product
                                                                              .quantity)
                                                                      .toStringAsFixed(
                                                                          2),
                                                          style: TextStyle(
                                                            fontFamily: 'Mukta',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        newQuantity !=
                                                                product.quantity
                                                            ? Text(
                                                                product.isCountable
                                                                    ? " " +
                                                                        (newPrice)
                                                                            .toString() +
                                                                        " Da"
                                                                    : " " +
                                                                        (newPrice)
                                                                            .toStringAsFixed(2) +
                                                                        " Da/Kg",
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'Mukta',
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              )
                                                            : Text(
                                                                product.isCountable
                                                                    ? " Da"
                                                                    : " Da/Kg",
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'Mukta',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                    trailing: Column(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            setSuper(() {
                                                              product.isCountable
                                                                  ? newQuantity +=
                                                                      1
                                                                  : newQuantity +=
                                                                      50 / 1000;
                                                            });
                                                            setState(() {});
                                                          },
                                                          child: Icon(
                                                            Icons
                                                                .arrow_drop_up_rounded,
                                                            color: Colors
                                                                .blueGrey[900],
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            product.isCountable
                                                                ? newQuantity >
                                                                        0
                                                                    ? {
                                                                        setSuper(
                                                                            () {
                                                                          newQuantity -=
                                                                              1;
                                                                          super.setState(
                                                                              () {
                                                                            transaction.subtotal -
                                                                                product.price;
                                                                          });
                                                                        }),
                                                                        setState(
                                                                            () {})
                                                                      }
                                                                    : null
                                                                : newQuantity >=
                                                                        50 /
                                                                            1000
                                                                    ? {
                                                                        setSuper(
                                                                            () {
                                                                          newQuantity -=
                                                                              50 / 1000;
                                                                        }),
                                                                        setState(
                                                                            () {})
                                                                      }
                                                                    : null;
                                                          },
                                                          child: Icon(
                                                            Icons
                                                                .arrow_drop_down_rounded,
                                                            color: Colors
                                                                .blueGrey[900],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Card(
                                                    child: Center(
                                                        child: Text(
                                                  "Add",
                                                  style: TextStyle(
                                                    fontFamily: 'Mukta',
                                                    color: Colors.grey[600],
                                                  ),
                                                )));
                                              }
                                            }),
                                            itemCount:
                                                transaction.productList.length +
                                                    1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            //Dialog Actions
                            Flexible(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context,
                                                rootNavigator: true)
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
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();
                                      },
                                      child: Text(
                                        "Update",
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          color: Colors.tealAccent[400],
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
                ),
              ],
            );
          });
        });
  }

  buildTransProductTile(
      bool isLast, TransProductObj product, TransactionObj transaction) {
    double newQuantity = product.quantity;
  }

  sortList() {
    listOfTransactions.sort(
      (a, b) {
        DateTime at = DateTime.parse(a.timeStamp);
        DateTime bt = DateTime.parse(b.timeStamp);
        return bt.compareTo(at);
      },
    );
  }

  late double scale;
  late double width;
  late double height;

  @override
  Widget build(BuildContext context) {
    scale = MediaQuery.of(context).textScaleFactor;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    _filterTransactions(fromDate, toDate);
    super.build(context);
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /*                                                                      Search bar*/
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //From
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Row(
                      children: [
                        Text(
                          "From: ",
                          style: TextStyle(
                            fontFamily: 'Mukta',
                          ),
                        ),
                        //From Button
                        GestureDetector(
                          onTap: () => _callFromDate(height),
                          child: SizedBox(
                            width: width / 3,
                            child: Container(
                              height: 40.0,
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
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: fromFilter
                                        ? Alignment.centerLeft
                                        : Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      child: Text(
                                        fromFilter
                                            ? DateFormat('dd/MM/yyyy kk:mm')
                                                .format(fromDate)
                                            : "Unset",
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                        ),
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                  ),
                                  fromFilter
                                      ? Align(
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                              onPressed: () => _disableFrom(),
                                              icon: const Icon(
                                                Icons.remove,
                                                color: Colors.red,
                                                size: 15,
                                              )))
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //To
                  Row(
                    children: [
                      Text(
                        "To: ",
                        style: TextStyle(
                          fontFamily: 'Mukta',
                        ),
                      ),
                      //To button
                      GestureDetector(
                        onTap: () => _callToDate(height),
                        child: SizedBox(
                          width: width / 3,
                          child: Container(
                            height: 40.0,
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
                            child: Stack(
                              children: [
                                Align(
                                  alignment: toFilter
                                      ? Alignment.centerLeft
                                      : Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0),
                                    child: Text(
                                      toFilter
                                          ? DateFormat('dd/MM/yyyy kk:mm')
                                              .format(toDate)
                                          : "Unset",
                                      style: TextStyle(
                                        fontFamily: 'Mukta',
                                      ),
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                ),
                                toFilter
                                    ? Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                            onPressed: () => _disableTo(),
                                            icon: const Icon(
                                              Icons.remove,
                                              color: Colors.red,
                                              size: 15,
                                            )))
                                    : const SizedBox(),
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
                            if (action == DialogAction.yes) {
                              setState(() {});
                            }
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
                ],
              ),
              /*                                                                      Listview*/
              listOfTransactions.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        primary: true,
                        itemCount: listOfTransactions.length,
                        itemBuilder: ((context, index) {
                          return buildTransTile(listOfTransactions[index]);
                        }),
                      ),
                    )
                  : Center(
                      child: Text(
                        "No transactions were found.",
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 15.0 * scale,
                        ),
                      ),
                    ),
              const SizedBox(),
            ],
          )),
    );
  }

  buildTransTile(TransactionObj transaction) {
    DateTime dateTime = DateTime.parse(transaction.timeStamp);
    bool isAdmin = data["isAdmin"];
    int role;
    if (!isAdmin) {
      if (data["post"] == "Manager") {
        //Manager: 2
        role = 2;
      } else if (data["post"] == "Seller") {
        //Seller: 3
        role = 3;
      } else {
        //Invalid Role: 0
        role = 0;
      }
    } else {
      //Admin: 1
      role = 1;
    }
    return Slidable(
      endActionPane: role != 3
          ? ActionPane(
              motion: const StretchMotion(),
              dragDismissible: true,
              children: [
                SlidableAction(
                  flex: 1,
                  onPressed: ((context) => buildEditDialog(transaction)),
                  backgroundColor: Colors.blueGrey[900]!,
                  foregroundColor: Colors.white,
                  icon: Icons.edit_note_rounded,
                ),
                SlidableAction(
                  flex: 2,
                  onPressed: ((context) {
                    _dbref!.child(transaction.timeStamp).remove();
                  }),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_forever,
                ),
              ],
            )
          : null,
      child: ListTile(
        title: SizedBox(
          height: 30.0,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false, physics: const BouncingScrollPhysics()),
            child: ListView.separated(
                itemCount: transaction.productList.length,
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) => const Text(", "),
                itemBuilder: (context, index) {
                  TransProductObj product = transaction.productList[index];
                  return Row(
                    children: [
                      Text(
                        product.label.toString(),
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(fontFamily: 'Mukta'),
                      ),
                      Text(
                        product.isCountable
                            ? " X" + product.quantity.toString()
                            : " " + (product.quantity * 1000).toString() + "g",
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          color: Colors.grey,
                          fontSize: 12.5 * scale,
                        ),
                      ),
                    ],
                  );
                }),
          ),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy – kk:mm').format(dateTime),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: const TextStyle(fontFamily: 'Mukta'),
        ),
        trailing: SizedBox(
          width: (MediaQuery.of(context).size.width) / 4,
          child: Row(
            children: [
              Flexible(
                child: PlatformText(
                  transaction.subtotal.toStringAsFixed(2) + " DA  ",
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 15.0,
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              role != 3
                  ? const Icon(
                      Icons.swipe_left_alt_rounded,
                      color: Colors.grey,
                      size: 15.0,
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  _callToDate(double height) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.tealAccent[400]!, // header background color
            onPrimary: Colors.white, // header text color
            onSurface: Colors.blueGrey[900]!, // body text color
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              primary: Colors.grey[500], // button text color
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: fromDate.hour, minute: fromDate.minute),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.tealAccent[400]!, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.blueGrey[900]!, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                primary: Colors.grey[500], // button text color
              ),
            ),
          ),
          child: child!,
        ),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _setToActive(pickedDateTime);
      }
    }
  }

  _callFromDate(double height) async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: fromDate,
        firstDate: DateTime(2022),
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.tealAccent[400]!, // header background color
                  onPrimary: Colors.white, // header text color
                  onSurface: Colors.blueGrey[900]!, // body text color
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    primary: Colors.grey[500], // button text color
                  ),
                ),
              ),
              child: child!,
            ));
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: fromDate.hour, minute: fromDate.minute),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.tealAccent[400]!, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.blueGrey[900]!, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                primary: Colors.grey[500], // button text color
              ),
            ),
          ),
          child: child!,
        ),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _setFromActive(pickedDateTime);
      }
    }
  }

  _disableFrom() {
    setState(() {
      listOfTransactions = transactionsBackup;
      fromFilter = false;
      fromDate = DateTime.now();
    });
  }

  _disableTo() {
    setState(() {
      listOfTransactions = transactionsBackup;
      toFilter = false;
      toDate = DateTime.now();
    });
  }

  _setFromActive(DateTime picked) {
    setState(() {
      fromFilter = true;
      fromDate = picked;
    });
  }

  _setToActive(DateTime picked) {
    setState(() {
      toFilter = true;
      toDate = picked;
    });
  }

  removeDuplicates() {
    listOfTransactions = listOfTransactions.toSet().toList();
    transactionsBackup = transactionsBackup.toSet().toList();
  }

  _filterTransactions(DateTime from, DateTime to) {
    if (fromFilter && toFilter) {
      listOfTransactions = [];
      for (var tile in transactionsBackup) {
        DateTime timeStamp = DateTime.parse(tile.timeStamp);
        if (timeStamp.compareTo(from) == 1 && timeStamp.compareTo(to) == -1) {
          listOfTransactions.add(tile);
        }
      }
    } else {
      if (fromFilter) {
        listOfTransactions = [];
        for (var tile in transactionsBackup) {
          DateTime timeStamp = DateTime.parse(tile.timeStamp);
          if (timeStamp.compareTo(from) == 1) {
            listOfTransactions.add(tile);
          }
        }
      }
      if (toFilter) {
        listOfTransactions = [];
        for (var tile in transactionsBackup) {
          DateTime timeStamp = DateTime.parse(tile.timeStamp);
          if (timeStamp.compareTo(to) == -1) {
            listOfTransactions.add(tile);
          }
        }
      }
    }
  }

  void clearSearch() {
    setState(() {
      query = "";
      searchController.clear();
      listOfTransactions = transactionsBackup;
    });
  }
}
