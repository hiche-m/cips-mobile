import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:application/client.dart';
import 'package:application/Pages/clientPage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class Clients extends StatefulWidget {
  Clients({Key? key, required this.instance, required this.data})
      : super(key: key);

  Map data;
  FirebaseAuth instance;
  @override
  State<Clients> createState() => _ClientsState(instance: instance, data: data);
}

class _ClientsState extends State<Clients>
    with AutomaticKeepAliveClientMixin<Clients> {
  _ClientsState({required this.instance, required this.data});

  var searchController = TextEditingController();
  DatabaseReference? _dbref;
  FirebaseAuth instance;
  Map data;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  @override
  void initState() {
    if (_dbref == null || data['ownerUID'].toString().isNotEmpty) {
      _dbref = FirebaseDatabase.instance
          .ref()
          .child("Users/${data['ownerUID']}/Clients");
    } else if (_dbref == null && data['ownerUID'].toString().isEmpty) {
      _dbref = FirebaseDatabase.instance
          .ref()
          .child("Users/${instance.currentUser!.uid}/Clients");
    }
    getClients();
    super.initState();
  }

  arrangeByName(List<Client> instance) {
    instance.sort((a, b) => a.name.compareTo(b.name));
  }

  arrangeByIncome(List<Client> instance) {
    instance.sort((a, b) => a.income.compareTo(b.income));
  }

  arrangeByTab(List<Client> instance) {
    instance.sort((a, b) => a.tab.compareTo(b.tab));
  }

  arrangeByDate(List<Client> instance) {
    instance.sort((a, b) => a.date!.compareTo(b.date!));
  }

  late double defaultTextScaleFactor;
  @override
  Widget build(BuildContext context) {
    frameHeight = MediaQuery.of(context).size.height;
    frameWidth = MediaQuery.of(context).size.width;
    defaultTextScaleFactor = MediaQuery.of(context).textScaleFactor;
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Clients",
                style: TextStyle(
                  fontSize: 40.0,
                  fontFamily: 'Mukta',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      buildClientAdd();
                    },
                    icon: Icon(
                      Icons.add,
                      color: Colors.blueGrey[900],
                    ),
                    splashRadius: 10.0 * defaultTextScaleFactor,
                  ),
                  PlatformPopupMenu(
                    icon: PlatformWidget(
                      material: (_, __) {
                        return const Icon(Icons.more_vert);
                      },
                      cupertino: (_, __) {
                        return const Icon(CupertinoIcons.ellipsis);
                      },
                    ),
                    options: [
                      PopupMenuOption(
                        label: "Name",
                        onTap: (_) {
                          arrangeByName(listOfClients);
                          setState(() {});
                        },
                      ),
                      PopupMenuOption(
                        label: "Income",
                        onTap: (_) {
                          arrangeByIncome(listOfClients);
                          setState(() {});
                        },
                      ),
                      PopupMenuOption(
                        label: "Tab",
                        onTap: (_) {
                          arrangeByTab(listOfClients);
                          setState(() {});
                        },
                      ),
                      PopupMenuOption(
                        label: "Date",
                        onTap: (_) {
                          arrangeByDate(listOfClients);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const Text(
                    " Arrange",
                    style: TextStyle(fontFamily: 'Mukta'),
                  ),
                ],
              ),
            ],
          ),
        ),
        /*                                                                      Search Bar*/
        Padding(
          padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
          child: Container(
            height: 40.0,
            child: PlatformTextField(
              controller: searchController,
              material: (_, __) => MaterialTextFieldData(
                decoration: InputDecoration(
                  hintText: 'Search for a client',
                  contentPadding: const EdgeInsets.only(left: 15.0),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchController.text.isNotEmpty
                      ? PlatformIconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() => listOfClients = clientsBackup);
                          },
                          materialIcon: Icon(
                            Icons.close,
                            size: 18.0,
                          ),
                          material: (_, __) => MaterialIconButtonData(
                            splashRadius: 0.1,
                          ),
                        )
                      : null,
                ),
              ),
              style: TextStyle(fontSize: 15.0, color: Colors.grey[600]),
              onChanged: searchClient,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(15.0)),
              border: Border.all(width: 2.0, color: Colors.grey.shade50),
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
        /*                                                                      Client List*/
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch(
              accentColor:
                  Colors.grey, // but now it should be declared like this
            ),
          ),
          child: listOfClients.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                    itemCount: listOfClients.length,
                    itemBuilder: (context, index) {
                      final client = listOfClients[index];

                      return Card(
                        child: ListTile(
                          leading: Image(
                            image: AssetImage(client.picture),
                            fit: BoxFit.cover,
                            height: 35.0,
                            width: 35.0,
                          ),
                          title: Text(
                            client.name,
                            style: TextStyle(fontFamily: 'Mukta'),
                          ),
                          subtitle: Text(
                            "Income: ${client.income}",
                            style: TextStyle(fontFamily: 'Mukta'),
                          ),
                          trailing: Icon(Icons.keyboard_arrow_right_rounded),
                          onTap: () => Navigator.push(
                              context,
                              platformPageRoute(
                                  context: context,
                                  builder: ((context) =>
                                      ClientPage(client: client)))),
                        ),
                      );
                    },
                  ),
                )
              : Expanded(
                  child: Center(
                    child: Text("It looks like your client list is empty.",
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          color: Colors.grey[500],
                        )),
                  ),
                ),
        )
      ],
    );
  }

  bool net = false;
  List<Client> listOfClients = [];
  List<Client> clientsBackup = [];
  String? dataString;
  Map<dynamic, dynamic>? map;
  double? frameHeight;
  double? frameWidth;
  File? _profilePicture;
  String barcode = "";
  final GlobalKey<FormState> addClientKey = GlobalKey<FormState>();
  var nameController = TextEditingController();
  var incomeController = TextEditingController();
  var numberController = TextEditingController();
  var tabController = TextEditingController();
  String? name;
  double? income = 0;
  int? number;
  double tab = 0;

  String idGenerator() {
    final now = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    return "C" + now.substring(0, 8) + "T" + now.substring(8) + "00";
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

  buildClientAdd() {
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
                        height: frameHeight! / 4,
                        width: frameWidth! / 1.25,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                                padding: const EdgeInsets.only(
                                                    left: 10.0),
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  radius: 50,
                                                  child: CircleAvatar(
                                                    radius: 48,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    backgroundImage:
                                                        const AssetImage(
                                                            "assets/icons/Default_PP.png"),
                                                  ),
                                                ),
                                              ),
                                              /*                                                      Edit button*/
                                              !kIsWeb
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 70.0,
                                                              left: 45.0),
                                                      child: RaisedButton(
                                                        onPressed: () async {
                                                          final source =
                                                              await showOptionsMenu(
                                                                  context);
                                                          source != null
                                                              ? await getImage(
                                                                  source)
                                                              : ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      SnackBar(
                                                                  backgroundColor:
                                                                      Colors.blueGrey[
                                                                          900],
                                                                  dismissDirection:
                                                                      DismissDirection
                                                                          .up,
                                                                  content: Text(
                                                                      "WARNING: No image was picked."),
                                                                ));
                                                          setState(() {});
                                                        },
                                                        shape:
                                                            const CircleBorder(),
                                                        elevation: 1.0,
                                                        child: Icon(
                                                          Icons.edit_outlined,
                                                          size: 12.5,
                                                          color: Colors.teal,
                                                        ),
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : SizedBox(),
                                            ],
                                          ),
                                          !kIsWeb
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Scan Barcode",
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                          fontFamily: 'Mukta',
                                                          fontSize: 10.0 *
                                                              defaultTextScaleFactor,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    PlatformIconButton(
                                                      onPressed: () async {
                                                        await FlutterBarcodeScanner
                                                                .scanBarcode(
                                                                    "#FF0000",
                                                                    "Cancel",
                                                                    true,
                                                                    ScanMode
                                                                        .BARCODE)
                                                            .then((value) =>
                                                                setState(() {
                                                                  barcode =
                                                                      value;
                                                                }));
                                                      },
                                                      icon: Icon(
                                                          Icons
                                                              .document_scanner_rounded,
                                                          size: 25.0 *
                                                              defaultTextScaleFactor,
                                                          color:
                                                              barcode.isNotEmpty &&
                                                                      barcode !=
                                                                          "-1"
                                                                  ? Colors
                                                                      .teal[400]
                                                                  : Colors.grey[
                                                                      700]),
                                                      material: (_, __) =>
                                                          MaterialIconButtonData(
                                                        splashRadius: 25.0,
                                                        splashColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                      ),
                                                    ),
                                                    SizedBox(),
                                                    Text(
                                                      "Code:",
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        fontSize: 13.75 *
                                                            defaultTextScaleFactor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      barcode != "-1"
                                                          ? barcode.toString()
                                                          : "",
                                                      overflow:
                                                          TextOverflow.fade,
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 10.0,
                                                      child: PlatformIconButton(
                                                          onPressed:
                                                              barcode.isNotEmpty &&
                                                                      barcode !=
                                                                          "-1"
                                                                  ? () {
                                                                      setState(
                                                                          () {
                                                                        barcode =
                                                                            "";
                                                                      });
                                                                    }
                                                                  : null,
                                                          icon:
                                                              barcode.isNotEmpty &&
                                                                      barcode !=
                                                                          "-1"
                                                                  ? Icon(
                                                                      Icons
                                                                          .close_rounded,
                                                                    )
                                                                  : Icon(null),
                                                          material: (_, __) =>
                                                              MaterialIconButtonData(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                              )),
                                                    ),
                                                  ],
                                                )
                                              : SizedBox(),
                                          const SizedBox(
                                            height: 25.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  /*                                                Form*/
                                  Form(
                                    key: addClientKey,
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
                                              _buildName(),
                                              _buildNumber(),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        fontSize: 16.5 * defaultTextScaleFactor,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  style: ButtonStyle(
                                    overlayColor: MaterialStateProperty.all(
                                        Colors.grey.withOpacity(0.1)),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final isValid =
                                        addClientKey.currentState!.validate();
                                    if (isValid) {
                                      addClientKey.currentState!.save();
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        backgroundColor: Colors.grey[300],
                                        dismissDirection: DismissDirection.up,
                                        content: Text(
                                          "Trying to create client...",
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ));
                                      String id;
                                      barcode.isEmpty
                                          ? id = idGenerator()
                                          : id = barcode;
                                      Map<String, dynamic> clientInfo = {
                                        "id": id.toString(),
                                        "name": name,
                                        "number": number,
                                      };
                                      await createClient(clientInfo);
                                      /* await uploadClientToStorage(
                                          FirebaseAuth.instance.currentUser!,
                                          clientInfo); */
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        15.0, 5.0, 15.0, 5.0),
                                    child: Text(
                                      "Add",
                                      style: TextStyle(
                                        fontFamily: 'Mukta',
                                        fontSize: 16.5 * defaultTextScaleFactor,
                                      ),
                                    ),
                                  ),
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18.0),
                                            side: BorderSide(
                                                color: Colors.transparent))),
                                    backgroundColor: MaterialStateProperty.all(
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
  }

  Future uploadClientToStorage(User user, Map info) async {
    final userID = user.uid;
    final String path = "$userID/Clients/${info["id"]}";

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

  Widget _buildName() {
    return Container(
      height: (frameHeight! / 2) / 6 >= 75 ? (frameHeight! / 2) / 6 : 75,
      width: (frameWidth! / 1.25) / 3,
      decoration: BoxDecoration(
          //border: Border.all(),
          borderRadius: BorderRadius.circular(15.0)),
      child: Center(
        child: TextFormField(
          controller: nameController,
          maxLines: 1,
          style: const TextStyle(
              fontFamily: 'Titillium Web', height: 1.2, color: Colors.black87),
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: 'Name',
            hintStyle: const TextStyle(
                fontFamily: 'Titillium Web', color: Colors.black38),
            prefixIcon: const Icon(
              Icons.person,
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
            return (value as String).isEmpty ? 'Name Missing!' : null;
          },
          onSaved: (String? value) {
            name = value;
          },
        ),
      ),
    );
  }

  Widget _buildNumber() {
    return SafeArea(
      child: Container(
        height: (frameHeight! / 2) / 6 >= 85 ? (frameHeight! / 2) / 6 : 85,
        width: (frameWidth! / 1.25) / 3,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
        child: Center(
          child: TextFormField(
            controller: numberController,
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
              hintText: 'Phone Number',
              hintStyle: const TextStyle(
                  fontFamily: 'Titillium Web', color: Colors.black38),
              prefixIcon: const Icon(
                Icons.phone,
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
              value != null && value.isNotEmpty
                  ? number = int.parse(value.toString())
                  : number = null;
            },
          ),
        ),
      ),
    );
  }

  getClients() {
    try {
      net = false;
      _dbref!.orderByKey().onValue.listen((event) {
        listOfClients = [];
        clientsBackup = [];
        if (event.snapshot.value != null) {
          dataString = jsonEncode(event.snapshot.value);
          map = jsonDecode(dataString!);
          listOfClients = [];
          clientsBackup = [];

          map!.forEach((idKey, element) {
            listOfClients.add(
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
          clientsBackup = listOfClients;
          removeDuplicates();
          clearSearch();
          if (mounted) setState(() {});
        } else {
          listOfClients = [];
          clientsBackup = [];
        }
      });
    } on Exception {
      if (mounted) {
        setState(() {
          net = true;
        });
      }
    }
  }

  removeDuplicates() {
    listOfClients = listOfClients.toSet().toList();
    clientsBackup = clientsBackup.toSet().toList();
  }

  clearSearch() {
    searchController.clear();
    setState(() => listOfClients = clientsBackup);
  }

  createClient(Map clientData) {
    _dbref!.child(clientData["id"]).set({
      "imgUrl": "",
      "income": 0,
      "name": clientData["name"],
      "nextPayment": "",
      "number": clientData["number"] ?? -1,
      "tab": 0,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.blueGrey[900],
        dismissDirection: DismissDirection.up,
        content: Text(
          "Client created successfully.",
          style: TextStyle(fontFamily: 'Mukta'),
        ),
      ));
    }).catchError((onError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        dismissDirection: DismissDirection.up,
        content: Text(
          "Couldn't create the client profile, reason: " + onError.toString(),
          style: TextStyle(fontFamily: 'Mukta'),
        ),
      ));
    });
  }

  void searchClient(String query) {
    final suggestion = clientsBackup.where((client) {
      final clientName = client.name.toLowerCase();
      final input = query.toLowerCase();

      return clientName.contains(input);
    }).toList();

    setState(() => listOfClients = suggestion);
  }
}
