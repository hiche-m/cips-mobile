import 'dart:convert';
import 'package:application/TextFormulations.dart';
import 'package:application/Widgets/dialogWidget.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:application/EmlpoyeeClass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Administration extends StatefulWidget {
  Administration({Key? key, required this.data}) : super(key: key);

  Map data;

  @override
  State<Administration> createState() => _AdministrationState(data: data);
}

List<Employee> employeeList = [];
List<bool> selectedTiles = [];

CollectionReference user = FirebaseFirestore.instance.collection("users");
final FirebaseAuth instance = FirebaseAuth.instance;

class _AdministrationState extends State<Administration> {
  _AdministrationState({required this.data});
  final CollectionReference user =
      FirebaseFirestore.instance.collection("users");

  bool waitingForResponse = false;

  @override
  void initState() {
    List userData = [];
    isAdmin = data['isAdmin'];
    employeeList.clear();
    selectedTiles.clear();

    user.snapshots().listen((snapshot) {
      userData = [];
      employeeList.clear();
      selectedTiles.clear();
      snapshot.docs.map((DocumentSnapshot document) {
        Map userInfo = document.data() as Map<String, dynamic>;
        if (document.id == instance.currentUser!.uid) {
          data = userInfo;
          userData.add(userInfo);
          if (userInfo['isAdmin'] == true) {
            userData = [];
            CollectionReference employees = FirebaseFirestore.instance
                .collection(
                    "users/" + instance.currentUser!.uid + "/employees");

            employees.snapshots().listen((element) {
              final List employeeMap = [];
              for (var employeeInfo in element.docs) {
                Map employeeData = employeeInfo.data() as Map<String, dynamic>;
                employeeMap.add(employeeData);
                selectedTiles.add(false);
                employeeList.add(Employee(
                  addTime: employeeData["addDate"].toString(),
                  post: employeeData["post"].toString(),
                  email: employeeInfo.id.toString(),
                  fullName: employeeData["fullName"].toString().isNotEmpty
                      ? employeeData["fullName"].toString()
                      : "",
                ));
              }

              if (mounted) setState(() {});
            });

            if (mounted) setState(() {});
          } else {
            if (mounted) setState(() {});
          }
        }
        userInfo['id'] = document.id;
        if (mounted) setState(() {});
      }).toList();

      if (mounted) {
        setState(() {
          employeeList = employeeList.toSet().toList();
        });
      }
    });
    super.initState();
    firstNameController.text = data["firstName"];
    lastNameController.text = data["lastName"];
    companyNameController.text = data["companyName"];
    data["isAdmin"]
        ? emailController.text = data["ownerEmail"]
        : emailController.text = data["email"];
  }

  Future<bool> sendPushMessage(String uid, String role) async {
    DocumentSnapshot snapshot = await user.doc(uid).get();
    String _token = snapshot['token'].substring(1);
    String titleMessage = "Employement add request";
    String bodyMessage = firstWordWithNoSpaces(data['firstName']) +
        " wants to add you as an employee, click here to accept.";
    bool continueBool = true;
    await user.doc(uid).get().then((document) {
      Map userInfo = document.data() as Map<String, dynamic>;
      if (userInfo['ownerEmail'].toString().isNotEmpty) {
        continueBool = false;
        setState(() {
          waitingForResponse = false;
        });
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.blueGrey[900],
          dismissDirection: DismissDirection.up,
          content: const Text(
            "You cannot add this user, they already have an administrator.",
            style: TextStyle(fontFamily: 'Mukta'),
          ),
        ));
        return false;
      }
    });

    if (continueBool) {
      if (!kIsWeb) {
        try {
          await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization':
                  'key=${{ secrets.FIREBASE_CLMS_API_KEY }}',
            },
            body: jsonEncode(
              <String, dynamic>{
                'notification': <String, dynamic>{
                  'body': bodyMessage,
                  'title': titleMessage
                },
                'priority': 'high',
                'data': <String, dynamic>{
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'id': DateFormat('yyyyMMdd').format(DateTime.now()) +
                      "T" +
                      DateFormat('kkmm').format(DateTime.now()),
                  'role': role,
                  'uid': data['uid']
                },
                "to": _token,
              },
            ),
          );
        } catch (e) {
          print("error push notification");
        }
      } else {
        if (_token == null) {
          setState(() {
            waitingForResponse = false;
          });
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.blueGrey[900],
            dismissDirection: DismissDirection.up,
            content: const Text(
              "Something went wrong, this user cannot be found.",
              style: TextStyle(fontFamily: 'Mukta'),
            ),
          ));
          return false;
        }
        try {
          await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization':
                  'key=${{ secrets.FIREBASE_CLMS_API_KEY }}'
            },
            body: json.encode({
              'to': _token,
              'message': {
                'token': _token,
              },
              'notification': {"title": titleMessage, "body": bodyMessage},
              'data': <String, dynamic>{
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'id': DateFormat('yyyyMMdd').format(DateTime.now()) +
                    "T" +
                    DateFormat('kkmm').format(DateTime.now()),
                'role': role,
                'uid': data['uid']
              },
            }),
          );
        } catch (e) {
          print(e);
        }
        setState(() {
          waitingForResponse = false;
        });
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.blueGrey[900],
          dismissDirection: DismissDirection.up,
          content: const Text(
            "An invitation was sent to this user.",
            style: TextStyle(fontFamily: 'Mukta'),
          ),
        ));
      }
    }

    return true;
  }

  Map data;
  late double scale;
  late double width;
  late double height;
  bool qrMode = false;
  String? _addEmail;

  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var companyNameController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var newPasswordController = TextEditingController();
  var newRePasswordController = TextEditingController();

  bool firstNameEmpty = false;
  bool lastNameEmpty = false;
  bool companyNameEmpty = false;
  bool emailEmpty = false;
  bool passwordEmpty = true;
  bool newPasswordEmpty = true;
  bool newRePasswordEmpty = true;

  bool firstNameChanged = false;
  bool lastNameChanged = false;
  bool companyNameChanged = false;
  bool emailChanged = false;
  bool passwordChanged = false;
  bool newPasswordChanged = false;
  bool newRePasswordChanged = false;

  Map<String, bool> criticalValids = {
    "password": false,
    "email": true,
    "newPassword": true,
    "newRePassword": true,
  };

  bool checkedPasswordCorrect = false;

  Future<bool> checkPassword(String password) async {
    if (password.isNotEmpty) {
      var authCredentials = EmailAuthProvider.credential(
        email: instance.currentUser!.email!,
        password: password,
      );
      bool valid = false;
      await instance.currentUser!
          .reauthenticateWithCredential(authCredentials)
          .then((value) {
        valid = true;
      }).catchError((onError) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          dismissDirection: DismissDirection.up,
          content: Text(
            "Wrong password.",
            style: TextStyle(
              fontFamily: 'Mukta',
              color: Colors.white,
            ),
          ),
        ));
        valid = false;
      });
      return valid;
    } else {
      print("Invalid Password");
      return false;
    }
  }

  String? firstName;
  String? lastName;
  String? companyName;
  String? email;
  String? password;
  String? newPassword;
  String? newRePassword;

  @override
  Widget build(BuildContext context) {
    scale = MediaQuery.of(context).textScaleFactor;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    bool selectionActive = false;
    int selectedNumber = 0;
    for (var selection in selectedTiles) {
      if (selection) {
        selectionActive = true;
        selectedNumber++;
      }
    }
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
        title: Text("Account Management",
            style: TextStyle(
              fontFamily: 'Mukta',
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey[50],
          child: Form(
            key: _settingsFormKey,
            //The column of columns
            child: Column(
              children: [
                //First Section
                isAdmin
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //Employees Title
                            Text(" Employees:",
                                style: TextStyle(
                                  fontFamily: 'Mukta',
                                  color: Colors.grey[500],
                                )),
                            const SizedBox(height: 10.0),
                            //Employees List
                            SingleChildScrollView(
                              child: Container(
                                height: height / 3 > 85 ? height / 3 : 85,
                                width: width,
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 250, 250, 250),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(15.0)),
                                  border: Border.all(
                                      width: 2.0, color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: (height / 16) > 50
                                            ? height / 16
                                            : 50,
                                      ),
                                      child: employeeList.isNotEmpty
                                          ? ListView.separated(
                                              primary: false,
                                              itemBuilder: ((context, index) =>
                                                  employeeTile(
                                                      index,
                                                      selectedTiles[index],
                                                      selectionActive)),
                                              separatorBuilder:
                                                  ((context, index) =>
                                                      const Divider()),
                                              itemCount: employeeList.length)
                                          : Center(
                                              child:
                                                  Text("You have no employees.",
                                                      style: TextStyle(
                                                        fontFamily: 'Mukta',
                                                        color: Colors.grey[500],
                                                      ))),
                                    ),
                                    selectionActive
                                        //Delete / Edit buttons
                                        ? Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                //Delete button
                                                SizedBox(
                                                  height: height / 16 > 50
                                                      ? height / 16
                                                      : 50,
                                                  width: selectedNumber == 1
                                                      ? (width / 2) - 17
                                                      : width / 2,
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      final action =
                                                          await DialogWidget
                                                              .yesCancelDialog(
                                                                  context,
                                                                  "Are you sure?",
                                                                  "This will delete the users you selected.",
                                                                  Colors.red);
                                                      if (action ==
                                                          DialogAction.yes) {
                                                        deleteEmployee(
                                                            selectedTiles);
                                                      }
                                                      setState(() {
                                                        int i = 0;
                                                        for (var element
                                                            in selectedTiles) {
                                                          selectedTiles[i] =
                                                              false;
                                                          i++;
                                                        }
                                                        selectionActive = false;
                                                      });
                                                    },
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(Colors
                                                                  .red[500]!),
                                                      shape: MaterialStateProperty
                                                          .all<
                                                              RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      15.0),
                                                        ),
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                //Edit Button
                                                selectedNumber == 1
                                                    ? SizedBox(
                                                        height: height / 16 > 50
                                                            ? height / 16
                                                            : 50,
                                                        width: (width / 2) - 17,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            int selectedIndex =
                                                                0;
                                                            int i = 0;
                                                            for (var element
                                                                in selectedTiles) {
                                                              element
                                                                  ? selectedIndex =
                                                                      i
                                                                  : null;
                                                              i++;
                                                            }
                                                            showRoleDialog(
                                                                employeeList[
                                                                    selectedIndex]);
                                                          },
                                                          style: ButtonStyle(
                                                            backgroundColor:
                                                                MaterialStateProperty.all<
                                                                    Color>(Colors
                                                                        .blueGrey[
                                                                    900]!),
                                                            shape: MaterialStateProperty
                                                                .all<
                                                                    RoundedRectangleBorder>(
                                                              RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            15.0),
                                                              ),
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .edit_note_rounded,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      )
                                                    : const SizedBox(),
                                              ],
                                            ),
                                          )
                                        //Add Button
                                        : Align(
                                            alignment: Alignment.bottomCenter,
                                            child: SizedBox(
                                              height: height / 16 > 50
                                                  ? height / 16
                                                  : 50,
                                              width: width,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  buildAddEmployeeDialog();
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all<
                                                              Color>(
                                                          Colors.grey[300]!),
                                                  shape:
                                                      MaterialStateProperty.all<
                                                          RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15.0),
                                                    ),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.add_rounded,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              " Owner's email:",
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            Text(
                              data['ownerEmail'].toString().isNotEmpty
                                  ? data['ownerEmail']
                                  : "None",
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                color: Colors.blueGrey[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                //General settings
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(" General settings:",
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            color: Colors.grey[500],
                          )),
                      const SizedBox(height: 10.0),
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 235, 235, 235),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(15.0)),
                          border: Border.all(
                            width: 2.0,
                            color: Color.fromARGB(255, 235, 235, 235),
                          ),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              //First Name
                              SizedBox(
                                width: width,
                                height: (height / 16) > 50 ? height / 16 : 50,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            "First Name:",
                                            softWrap: false,
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                              fontSize: 17.5 * scale,
                                            ),
                                          ),
                                        )),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 5.0),
                                      child: SizedBox(
                                        width: 10.0,
                                        child: firstNameChanged
                                            ? const Text(
                                                "!",
                                                style: TextStyle(
                                                  fontFamily: 'Bebas Neue',
                                                  color: Colors.red,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Flexible(
                                      flex: 4,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          textSelectionTheme:
                                              TextSelectionThemeData(
                                            selectionColor: Colors.grey[700],
                                          ),
                                        ),
                                        child: Theme(
                                          data: ThemeData(
                                            colorScheme: ThemeData()
                                                .colorScheme
                                                .copyWith(
                                                  primary: Colors.grey[700],
                                                ),
                                          ),
                                          child: TextFormField(
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp("[a-z A-Z]")),
                                            ],
                                            textInputAction:
                                                TextInputAction.next,
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                            controller: firstNameController,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              hintText: 'Enter a first name',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Mukta',
                                              ),
                                              suffixIcon: !firstNameEmpty
                                                  ? InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          firstNameController
                                                              .clear();
                                                          firstNameEmpty = true;
                                                          firstNameChanged =
                                                              false;
                                                        });
                                                      },
                                                      child: const Icon(
                                                          Icons.close_rounded),
                                                    )
                                                  : null,
                                            ),
                                            onSaved: (value) {
                                              if (value != null &&
                                                  value.isNotEmpty) {
                                                firstName = capFix(value);
                                              }
                                            },
                                            onChanged: (value) {
                                              String account =
                                                  data["firstName"];
                                              if (value.isEmpty) {
                                                setState(() {
                                                  firstNameChanged = false;
                                                  firstNameEmpty = true;
                                                });
                                              } else if (value != account &&
                                                  !firstNameChanged) {
                                                setState(() {
                                                  firstNameChanged = true;
                                                  firstNameEmpty = false;
                                                });
                                              } else if (value == account &&
                                                  firstNameChanged) {
                                                setState(() {
                                                  firstNameChanged = false;
                                                  firstNameEmpty = false;
                                                });
                                              } else if (firstNameEmpty) {
                                                setState(() {
                                                  firstNameEmpty = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //Last Name
                              SizedBox(
                                width: width,
                                height: (height / 16) > 50 ? height / 16 : 50,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            "Last Name:",
                                            softWrap: false,
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                              fontSize: 17.5 * scale,
                                            ),
                                          ),
                                        )),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 5.0),
                                      child: SizedBox(
                                        width: 10.0,
                                        child: lastNameChanged
                                            ? const Text(
                                                "!",
                                                style: TextStyle(
                                                  fontFamily: 'Bebas Neue',
                                                  color: Colors.red,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Flexible(
                                      flex: 4,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          textSelectionTheme:
                                              TextSelectionThemeData(
                                            selectionColor: Colors.grey[700],
                                          ),
                                        ),
                                        child: Theme(
                                          data: ThemeData(
                                            colorScheme: ThemeData()
                                                .colorScheme
                                                .copyWith(
                                                  primary: Colors.grey[700],
                                                ),
                                          ),
                                          child: TextFormField(
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp("[a-zA-Z]")),
                                            ],
                                            textInputAction:
                                                TextInputAction.next,
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                            controller: lastNameController,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              hintText: 'Enter a last name',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Mukta',
                                              ),
                                              suffixIcon: !lastNameEmpty
                                                  ? InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          lastNameController
                                                              .clear();
                                                          lastNameEmpty = true;
                                                          lastNameChanged =
                                                              false;
                                                        });
                                                      },
                                                      child: const Icon(
                                                          Icons.close_rounded),
                                                    )
                                                  : null,
                                            ),
                                            onSaved: (value) {
                                              if (value != null &&
                                                  value.isNotEmpty) {
                                                lastName = capFix(value);
                                              }
                                            },
                                            onChanged: (value) {
                                              String account = data["lastName"];
                                              if (value.isEmpty) {
                                                setState(() {
                                                  lastNameChanged = false;
                                                  lastNameEmpty = true;
                                                });
                                              } else if (value != account &&
                                                  !lastNameChanged) {
                                                setState(() {
                                                  lastNameChanged = true;
                                                  lastNameEmpty = false;
                                                });
                                              } else if (value == account &&
                                                  lastNameChanged) {
                                                setState(() {
                                                  lastNameChanged = false;
                                                  lastNameEmpty = false;
                                                });
                                              } else if (lastNameEmpty) {
                                                setState(() {
                                                  lastNameEmpty = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //Company Name
                              SizedBox(
                                width: width,
                                height: (height / 16) > 50 ? height / 16 : 50,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        flex: 5,
                                        child: Text(
                                          "Company Name:",
                                          softWrap: false,
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                            fontSize: 17.5 * scale,
                                          ),
                                        )),
                                    SizedBox(
                                      width: 10.0,
                                      child: companyNameChanged
                                          ? const Text(
                                              "!",
                                              style: TextStyle(
                                                fontFamily: 'Bebas Neue',
                                                color: Colors.red,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Flexible(
                                      flex: 7,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          textSelectionTheme:
                                              TextSelectionThemeData(
                                            selectionColor: Colors.grey[700],
                                          ),
                                        ),
                                        child: Theme(
                                          data: ThemeData(
                                            colorScheme: ThemeData()
                                                .colorScheme
                                                .copyWith(
                                                  primary: Colors.grey[700],
                                                ),
                                          ),
                                          child: TextFormField(
                                            textInputAction:
                                                TextInputAction.next,
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                            controller: companyNameController,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              hintText: 'Enter a company name',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Mukta',
                                              ),
                                              suffixIcon: !companyNameEmpty
                                                  ? InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          companyNameController
                                                              .clear();
                                                          companyNameEmpty =
                                                              true;
                                                          companyNameChanged =
                                                              false;
                                                        });
                                                      },
                                                      child: const Icon(
                                                          Icons.close_rounded),
                                                    )
                                                  : null,
                                            ),
                                            onSaved: (value) {
                                              if (value != null &&
                                                  value.isNotEmpty) {
                                                companyName = capFix(value);
                                              }
                                            },
                                            onChanged: (value) {
                                              String account =
                                                  data["companyName"];
                                              if (value.isEmpty) {
                                                setState(() {
                                                  companyNameChanged = false;
                                                  companyNameEmpty = true;
                                                });
                                              } else if (value != account &&
                                                  !companyNameChanged) {
                                                setState(() {
                                                  companyNameChanged = true;
                                                  companyNameEmpty = false;
                                                });
                                              } else if (value == account &&
                                                  companyNameChanged) {
                                                setState(() {
                                                  companyNameChanged = false;
                                                  companyNameEmpty = false;
                                                });
                                              } else if (companyNameEmpty) {
                                                setState(() {
                                                  companyNameEmpty = false;
                                                });
                                              }
                                            },
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
                    ],
                  ),
                ),
                //Security settings
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(" Security settings:",
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            color: Colors.grey[500],
                          )),
                      const SizedBox(height: 10.0),
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 235, 235, 235),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(15.0)),
                          border: Border.all(
                            width: 2.0,
                            color: Color.fromARGB(255, 235, 235, 235),
                          ),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              //Email
                              SizedBox(
                                width: width,
                                height: (height / 16) > 50 ? height / 16 : 50,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        flex: 1,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            "Email:",
                                            softWrap: false,
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontWeight: FontWeight.bold,
                                              color: criticalValids['email'] ==
                                                      true
                                                  ? Colors.grey[600]
                                                  : Colors.red,
                                              fontSize: 17.5 * scale,
                                            ),
                                          ),
                                        )),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 5.0),
                                      child: SizedBox(
                                        width: 10.0,
                                        child: emailChanged
                                            ? const Text(
                                                "!",
                                                style: TextStyle(
                                                  fontFamily: 'Bebas Neue',
                                                  color: Colors.red,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Flexible(
                                      flex: 4,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          textSelectionTheme:
                                              TextSelectionThemeData(
                                            selectionColor: Colors.grey[700],
                                          ),
                                        ),
                                        child: Theme(
                                          data: ThemeData(
                                            colorScheme: ThemeData()
                                                .colorScheme
                                                .copyWith(
                                                  primary: Colors.grey[700],
                                                ),
                                          ),
                                          child: TextFormField(
                                            textInputAction:
                                                TextInputAction.next,
                                            validator: (value) {
                                              value != null && value.isNotEmpty
                                                  ? !EmailValidator.validate(
                                                          value)
                                                      ? setState(() {
                                                          criticalValids[
                                                              'email'] = false;
                                                        })
                                                      : setState(() {
                                                          criticalValids[
                                                              'email'] = true;
                                                        })
                                                  : setState(() {
                                                      criticalValids['email'] =
                                                          true;
                                                    });
                                              return value != null &&
                                                      value.isNotEmpty
                                                  ? !EmailValidator.validate(
                                                          value)
                                                      ? '      Please enter a valid email.'
                                                      : null
                                                  : null;
                                            },
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                            controller: emailController,
                                            decoration: InputDecoration(
                                              errorStyle:
                                                  TextStyle(fontSize: 0.01),
                                              border: InputBorder.none,
                                              isDense: true,
                                              hintText: 'Enter an email',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Mukta',
                                              ),
                                              suffixIcon: !emailEmpty
                                                  ? InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          emailChanged = false;
                                                          emailController
                                                              .clear();
                                                          emailEmpty = true;
                                                        });
                                                      },
                                                      child: const Icon(
                                                          Icons.close_rounded),
                                                    )
                                                  : null,
                                            ),
                                            onSaved: (value) {
                                              if (value != null &&
                                                  value.isNotEmpty) {
                                                email = capFix(value);
                                              }
                                            },
                                            onChanged: (value) {
                                              String account = data["email"];
                                              if (value.isEmpty) {
                                                setState(() {
                                                  emailChanged = false;
                                                  emailEmpty = true;
                                                });
                                              } else if (value != account &&
                                                  !emailChanged) {
                                                setState(() {
                                                  emailChanged = true;
                                                  emailEmpty = false;
                                                });
                                              } else if (value == account &&
                                                  emailChanged) {
                                                setState(() {
                                                  emailChanged = false;
                                                  emailEmpty = false;
                                                });
                                              } else if (emailEmpty) {
                                                setState(() {
                                                  emailEmpty = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //New Password
                              SizedBox(
                                width: width,
                                height: (height / 16) > 50 ? height / 16 : 50,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        flex: 5,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            "New Password:",
                                            softWrap: false,
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                              fontSize: 17.5 * scale,
                                            ),
                                          ),
                                        )),
                                    const SizedBox(width: 10.0),
                                    Flexible(
                                      flex: 7,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          textSelectionTheme:
                                              TextSelectionThemeData(
                                            selectionColor: Colors.grey[700],
                                          ),
                                        ),
                                        child: Theme(
                                          data: ThemeData(
                                            colorScheme: ThemeData()
                                                .colorScheme
                                                .copyWith(
                                                  primary: Colors.grey[700],
                                                ),
                                          ),
                                          child: TextFormField(
                                            textInputAction:
                                                TextInputAction.next,
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                            controller: newPasswordController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              errorStyle:
                                                  TextStyle(fontSize: 0.01),
                                              border: InputBorder.none,
                                              isDense: true,
                                              hintText: 'Create a new password',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Mukta',
                                              ),
                                              suffixIcon: !newPasswordEmpty
                                                  ? InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          newPasswordController
                                                              .clear();
                                                          newPasswordEmpty =
                                                              true;
                                                        });
                                                      },
                                                      child: const Icon(
                                                          Icons.close_rounded),
                                                    )
                                                  : null,
                                            ),
                                            validator: (value) {
                                              if (value != null &&
                                                  value.isNotEmpty) {
                                                if (value.length < 8) {
                                                  setState(() {
                                                    criticalValids[
                                                        'newPassword'] = false;
                                                  });
                                                  return 'Password should be at least 8 characters.';
                                                }
                                              } else {
                                                setState(() {
                                                  criticalValids[
                                                      'newPassword'] = true;
                                                });
                                                return null;
                                              }
                                            },
                                            onSaved: (value) {
                                              if (value != null &&
                                                  value.isNotEmpty) {
                                                newPassword = value;
                                              }
                                            },
                                            onChanged: (value) {
                                              if (value.isEmpty) {
                                                setState(() {
                                                  newPasswordEmpty = true;
                                                });
                                              } else if (newPasswordEmpty &&
                                                  value.isNotEmpty) {
                                                setState(() {
                                                  newPasswordEmpty = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //Repeat Password
                              SizedBox(
                                width: width,
                                height: (height / 16) > 50 ? height / 16 : 50,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        flex: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            "Repeat Password:",
                                            softWrap: false,
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                              fontSize: 17.5 * scale,
                                            ),
                                          ),
                                        )),
                                    const SizedBox(width: 10.0),
                                    Flexible(
                                      flex: 7,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          textSelectionTheme:
                                              TextSelectionThemeData(
                                            selectionColor: Colors.grey[700],
                                          ),
                                        ),
                                        child: Theme(
                                          data: ThemeData(
                                            colorScheme: ThemeData()
                                                .colorScheme
                                                .copyWith(
                                                  primary: Colors.grey[700],
                                                ),
                                          ),
                                          child: TextFormField(
                                            textInputAction:
                                                TextInputAction.next,
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                            controller: newRePasswordController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              errorStyle:
                                                  TextStyle(fontSize: 0.01),
                                              border: InputBorder.none,
                                              isDense: true,
                                              hintText: 'Enter password again',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Mukta',
                                              ),
                                              suffixIcon: !newRePasswordEmpty
                                                  ? InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          newRePasswordController
                                                              .clear();
                                                          newRePasswordEmpty =
                                                              true;
                                                        });
                                                      },
                                                      child: const Icon(
                                                          Icons.close_rounded),
                                                    )
                                                  : null,
                                            ),
                                            validator: (value) {
                                              newPasswordController.text ==
                                                      value
                                                  ? setState(() {
                                                      criticalValids[
                                                              'newRePassword'] =
                                                          true;
                                                    })
                                                  : setState(() {
                                                      criticalValids[
                                                              'newRePassword'] =
                                                          false;
                                                    });
                                              return newPasswordController
                                                          .text ==
                                                      value
                                                  ? null
                                                  : 'Passwords do not match!';
                                            },
                                            onSaved: (value) {
                                              if (value != null &&
                                                  value.isNotEmpty) {
                                                newRePassword = capFix(value);
                                              }
                                            },
                                            onChanged: (value) {
                                              if (value.isEmpty) {
                                                setState(() {
                                                  newRePasswordEmpty = true;
                                                });
                                              } else if (newRePasswordEmpty &&
                                                  value.isNotEmpty) {
                                                setState(() {
                                                  newRePasswordEmpty = false;
                                                });
                                              }
                                            },
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
                    ],
                  ),
                ),
                //Current Password
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 235, 235, 235),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15.0)),
                        border: Border.all(
                          width: 2.0,
                          color: Color.fromARGB(255, 235, 235, 235),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: width,
                              height: (height / 16) > 50 ? height / 16 : 50,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                      flex: 4,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          "Your Password:",
                                          softWrap: false,
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            fontWeight: FontWeight.bold,
                                            color: criticalValids["password"] ==
                                                    true
                                                ? Colors.grey[600]
                                                : Colors.red,
                                            fontSize: 17.5 * scale,
                                          ),
                                        ),
                                      )),
                                  const SizedBox(width: 10.0),
                                  Flexible(
                                    flex: 7,
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        textSelectionTheme:
                                            TextSelectionThemeData(
                                          selectionColor: Colors.grey[700],
                                        ),
                                      ),
                                      child: Theme(
                                        data: ThemeData(
                                          colorScheme:
                                              ThemeData().colorScheme.copyWith(
                                                    primary: Colors.grey[700],
                                                  ),
                                        ),
                                        child: TextFormField(
                                          textInputAction: TextInputAction.next,
                                          style: const TextStyle(
                                            fontFamily: 'Mukta',
                                          ),
                                          controller: passwordController,
                                          obscureText: true,
                                          decoration: InputDecoration(
                                            errorStyle:
                                                TextStyle(fontSize: 0.01),
                                            border: InputBorder.none,
                                            isDense: true,
                                            hintText:
                                                'Enter your current password',
                                            hintStyle: const TextStyle(
                                              fontFamily: 'Mukta',
                                            ),
                                            suffixIcon: !passwordEmpty
                                                ? InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        passwordController
                                                            .clear();
                                                        passwordEmpty = true;
                                                      });
                                                    },
                                                    child: const Icon(
                                                        Icons.close_rounded),
                                                  )
                                                : null,
                                          ),
                                          validator: (value) {
                                            if (value != null &&
                                                value.isEmpty) {
                                              return "Enter password first!";
                                            } else if (value != null &&
                                                value.length < 8) {
                                              return "Invalid password!";
                                            }
                                          },
                                          onSaved: (value) {
                                            if (value != null &&
                                                value.isNotEmpty) {
                                              password = value;
                                            }
                                          },
                                          onChanged: (value) {
                                            if (value.isEmpty) {
                                              setState(() {
                                                passwordEmpty = true;
                                              });
                                            } else if (passwordEmpty &&
                                                value.isNotEmpty) {
                                              setState(() {
                                                passwordEmpty = false;
                                              });
                                            }
                                            if (value.toString().length >= 8) {
                                              setState(() {
                                                criticalValids["password"] =
                                                    true;
                                              });
                                            }
                                          },
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
                //Save button
                Padding(
                  padding:
                      const EdgeInsets.only(top: 20.0, left: 25.0, right: 25.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final isValid = _settingsFormKey.currentState!.validate();
                      _settingsFormKey.currentState!.save();
                      bool validPassword =
                          isValid ? await checkPassword(password!) : false;
                      isValid && validPassword
                          ? {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                backgroundColor: Colors.grey[400],
                                dismissDirection: DismissDirection.up,
                                content: Text(
                                  "Saving...",
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    color: Colors.grey[700],
                                  ),
                                ),
                              )),
                              updateUserData()
                            }
                          : setState(() {
                              print('Password ' + validPassword.toString());
                              criticalValids['password'] = false;
                            });
                    },
                    child: SizedBox(
                      height: height / 16 > 55 ? height / 16 : 55,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Save Changes",
                            style: TextStyle(
                              fontFamily: 'Titillium Web',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.blueGrey[900]!),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          //side: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
                //Delete Account
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: TextButton(
                    onPressed: () async {
                      final action = await DialogWidget.yesCancelDialog(
                          context,
                          "Are you sure?",
                          "This will delete the users you selected.",
                          Colors.red);
                      action == DialogAction.yes ? print("Delete User") : null;
                    },
                    style: ButtonStyle(
                      overlayColor: MaterialStateColor.resolveWith(
                          (states) => Colors.grey.withOpacity(0.1)),
                    ),
                    child: const Text(
                      "Delete my account",
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  deleteEmployee(List<bool> selectedList) {
    int i = 0;
    selectedList.forEach((element) async {
      if (element) {
        print("Delete " +
            employeeList[i].email +
            " de " +
            data['uid'].toString());
        await user
            .doc(instance.currentUser!.uid)
            .collection('employees')
            .doc(employeeList[i].email)
            .delete()
            .catchError((onError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.blueGrey[900],
            dismissDirection: DismissDirection.up,
            content: const Text(
              "Something went wrong, couldn't delete user.",
              style: TextStyle(fontFamily: 'Mukta'),
            ),
          ));
          return;
        });
        String email = employeeList[i].email;
        user.get().then((snapshot) {
          snapshot.docs
              .asMap()
              .forEach((index, DocumentSnapshot document) async {
            Map userInfo = document.data() as Map<String, dynamic>;
            if (userInfo['email'] == email) {
              await user.doc(document.id).update(
                  {'ownerEmail': "", 'post': "Seller"}).catchError((onError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.blueGrey[900],
                  dismissDirection: DismissDirection.up,
                  content: const Text(
                    "Something went wrong, couldn't delete user.",
                    style: TextStyle(fontFamily: 'Mukta'),
                  ),
                ));
                return;
              }).then((value) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.blueGrey[900],
                  dismissDirection: DismissDirection.up,
                  content: Text(
                    '"' + email + '" was deleted successfully.',
                    style: TextStyle(fontFamily: 'Mukta'),
                  ),
                ));
              });
            }
          });
        });
      }
      i++;
    });
  }

  var _settingsFormKey = GlobalKey<FormState>();
  late TextEditingController copyLinkController;
  final empAddEmailController = TextEditingController();
  final GlobalKey<FormState> addEmailKey = GlobalKey<FormState>();
  bool isValid = true;
  bool isManager = false;
  bool isAdmin = false;

  buildAddEmployeeDialog() {
    copyLinkController = TextEditingController(text: 'cd.m/dsqxQSz2');
    copyLinkController.selection = TextSelection(
        baseOffset: 0, extentOffset: copyLinkController.value.text.length);

    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
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
                      child: Column(
                        children: [
                          //Top bar
                          Flexible(
                            flex: 4,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.of(context, rootNavigator: true)
                                        .pop(),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: (width / 1.2 / 2) / 10,
                                ),
                              ),
                            ),
                          ),
                          //Content
                          Flexible(
                            flex: 25,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                //Email or QR option
                                Expanded(
                                  flex: 1,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (qrMode) {
                                            setState(() {
                                              qrMode = !qrMode;
                                            });
                                          }
                                        },
                                        child: Container(
                                            color: !qrMode
                                                ? Colors.teal[50]
                                                : Colors.transparent,
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                "Email",
                                                style: TextStyle(
                                                    fontFamily: 'Mukta'),
                                              ),
                                            )),
                                      ),
                                      /* Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: SizedBox(
                                          height: 35.0 * (scale / 2),
                                          child: VerticalDivider(
                                            color: Colors.grey[400],
                                            thickness: 0.5,
                                          ),
                                        ),
                                      ), */
                                      /* InkWell(
                                        onTap: () {
                                          if (!qrMode) {
                                            setState(() {
                                              qrMode = !qrMode;
                                            });
                                          }
                                        },
                                        child: Container(
                                            color: qrMode
                                                ? Colors.teal[50]
                                                : Colors.transparent,
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                "QR",
                                                style: TextStyle(
                                                    fontFamily: 'Mukta'),
                                              ),
                                            )),
                                      ), */
                                    ],
                                  ),
                                ),
                                //Email fill section
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "Owner Email:  ",
                                            softWrap: false,
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              color: Colors.blueGrey[900],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 5,
                                          child: Stack(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                            Radius.circular(
                                                                15.0))),
                                              ),
                                              Theme(
                                                data: ThemeData(
                                                  colorScheme: ThemeData()
                                                      .colorScheme
                                                      .copyWith(
                                                        primary: Colors.red,
                                                        onSurface: Colors.red,
                                                      ),
                                                  textSelectionTheme:
                                                      TextSelectionThemeData(
                                                    cursorColor: Colors.grey,
                                                    selectionColor:
                                                        Colors.grey[400],
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Form(
                                                    key: addEmailKey,
                                                    child: TextFormField(
                                                      controller:
                                                          empAddEmailController,
                                                      textInputAction:
                                                          TextInputAction.next,
                                                      style: const TextStyle(
                                                        fontFamily: 'Mukta',
                                                      ),
                                                      autovalidateMode:
                                                          AutovalidateMode
                                                              .onUserInteraction,
                                                      validator: (value) => value !=
                                                                  null &&
                                                              !EmailValidator
                                                                  .validate(
                                                                      value)
                                                          ? '      Please enter a valid email.'
                                                          : null,
                                                      onSaved: (value) {
                                                        _addEmail = value;
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        prefixIcon: !isValid
                                                            ? Icon(Icons
                                                                .warning_rounded)
                                                            : SizedBox(),
                                                        errorStyle: TextStyle(
                                                            fontSize: 0.01),
                                                        hintStyle: TextStyle(
                                                          fontFamily: 'Mukta',
                                                        ),
                                                        border:
                                                            InputBorder.none,
                                                        isDense: true,
                                                        hintText:
                                                            'example@domain.com',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                isManager = !isManager;
                                              });
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Text(
                                                  isManager
                                                      ? "Manager"
                                                      : "Seller",
                                                  softWrap: false,
                                                  style: TextStyle(
                                                    fontFamily: 'Mukta',
                                                    color: Colors.blueGrey[900],
                                                  ),
                                                ),
                                                Icon(
                                                  isManager
                                                      ? Icons
                                                          .switch_left_rounded
                                                      : Icons
                                                          .switch_right_rounded,
                                                  color: Colors.grey[700],
                                                  size: 15.0 * scale,
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 1,
                                  child: Center(
                                      child: Text(
                                    "Or",
                                    style: TextStyle(
                                      fontFamily: 'Mukta',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                                ),
                                //Copy Link
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        50.0, 8.0, 50.0, 8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(15.0))),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Theme(
                                              data: Theme.of(context).copyWith(
                                                textSelectionTheme:
                                                    TextSelectionThemeData(
                                                  cursorColor: Colors.grey,
                                                  selectionColor:
                                                      Colors.grey[400],
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextFormField(
                                                  autofocus: true,
                                                  controller:
                                                      copyLinkController,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  style: const TextStyle(
                                                    fontFamily: 'Mukta',
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    hintText: 'Referal Code',
                                                    hintStyle: TextStyle(
                                                      fontFamily: 'Mukta',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 5.0),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                                child: ElevatedButton(
                                                  onPressed: () {},
                                                  style: ButtonStyle(
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(Colors
                                                                      .blueGrey[
                                                                  900]!)),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 10.0),
                                                    child: Text(
                                                      "Copy",
                                                      style: TextStyle(
                                                          fontFamily: 'Mukta'),
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
                                ),
                              ],
                            ),
                          ),
                          //Dialog Actions
                          Flexible(
                            flex: 6,
                            child: Row(
                              children: [
                                //Left Button
                                Flexible(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: TextButton(
                                        onPressed: () => Navigator.of(context,
                                                rootNavigator: true)
                                            .pop(),
                                        style: ButtonStyle(
                                          overlayColor:
                                              MaterialStateColor.resolveWith(
                                                  (states) => Colors.grey
                                                      .withOpacity(0.1)),
                                        ),
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                //Right Button
                                Flexible(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: ElevatedButton(
                                        onPressed: !waitingForResponse
                                            ? () async {
                                                isValid = addEmailKey
                                                    .currentState!
                                                    .validate();
                                                isValid
                                                    ? {
                                                        sendEmailNotification(
                                                            isManager),
                                                        setState(() {
                                                          waitingForResponse =
                                                              true;
                                                        })
                                                      }
                                                    : setState(() {});
                                              }
                                            : null,
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  !waitingForResponse
                                                      ? Colors.tealAccent[400]!
                                                      : Colors.grey[500]!),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(
                                            !waitingForResponse
                                                ? "Send"
                                                : "Sending",
                                            style: const TextStyle(
                                              fontFamily: 'Mukta',
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

  sendEmailNotification(bool isManager) async {
    bool found = false;
    QuerySnapshot snapshot = await user.get();
    snapshot.docs
        .asMap()
        .forEach((int i, QueryDocumentSnapshot<Object?> document) {
      Map userInfo = document.data() as Map<String, dynamic>;
      if (empAddEmailController.text.trim() == userInfo["email"]) {
        found = true;
        if (userInfo["email"] == data['ownerEmail']) {
          setState(() {
            waitingForResponse = false;
          });
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.blueGrey[900],
            dismissDirection: DismissDirection.up,
            content: const Text(
              "You cannot add yourself.",
              style: TextStyle(fontFamily: 'Mukta'),
            ),
          ));
        } else if (!userInfo["isAdmin"]) {
          sendPushMessage(document.id, isManager ? "Manager" : "Seller");
        } else {
          setState(() {
            waitingForResponse = false;
          });
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.blueGrey[900],
            dismissDirection: DismissDirection.up,
            content: const Text(
              "That's not possible, this user is an administrator.",
              style: TextStyle(fontFamily: 'Mukta'),
            ),
          ));
        }
      } else {}
    });
    !found
        ? {
            setState(() {
              waitingForResponse = false;
            }),
            Navigator.of(context, rootNavigator: true).pop(),
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.blueGrey[900],
              dismissDirection: DismissDirection.up,
              content: const Text(
                "The email you entered does not belong to any user.",
                style: TextStyle(fontFamily: 'Mukta'),
              ),
            )),
          }
        : null;
  }

  employeeTile(int index, bool isSelected, bool selectionActive) {
    return InkWell(
      onLongPress: () {
        setState(() {
          selectedTiles[index] = true;
        });
      },
      onTap: () {
        setState(() {
          if (isSelected || selectionActive) {
            selectedTiles[index] = !selectedTiles[index];
          }
        });
      },
      child: ListTile(
        title: Text(
          employeeList[index].fullName.isEmpty
              ? employeeList[index].email
              : employeeList[index].fullName,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_box_rounded,
                color: Colors.red,
              )
            : Text(employeeList[index].post),
        subtitle: Text("Employee since " +
            DateFormat('dd/MM/yyyy').format(
                DateTime.parse(employeeList[index].addTime.toString()))),
      ),
    );
  }

  void showRoleDialog(Employee emlpoyee) {
    bool hasRole = emlpoyee.post == "Seller" ? false : true;
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  //Dialog object
                  child: Dialog(
                      backgroundColor: Colors.grey[100],
                      //Dialog Size
                      child: SizedBox(
                        height: height / 5,
                        width: width / 1.6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        child: Text(
                                          "Change user type: ",
                                          style: TextStyle(fontFamily: 'Mukta'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                hasRole = !hasRole;
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Icon(hasRole
                                                    ? Icons.switch_left_rounded
                                                    : Icons
                                                        .switch_right_rounded),
                                                Text(hasRole
                                                    ? "Manager"
                                                    : "Seller"),
                                              ],
                                            )),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            //Dialog actions
                            Flexible(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  //Cancel button
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextButton(
                                      onPressed: () => Navigator.of(context,
                                              rootNavigator: true)
                                          .pop(),
                                      style: ButtonStyle(
                                        overlayColor:
                                            MaterialStateColor.resolveWith(
                                                (states) => Colors.grey
                                                    .withOpacity(0.1)),
                                      ),
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                  //Submit button
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.blueGrey[900]!),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(5.0),
                                        child: Text(
                                          "Submit",
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
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
                      )),
                ),
              ],
            );
          });
        });
  }

  updateUserData() async {
    firstName != null && firstName!.isNotEmpty
        ? await user.doc(FirebaseAuth.instance.currentUser!.uid).update({
            'firstName': firstName,
          })
        : null;
    lastName != null && firstName!.isNotEmpty
        ? await user.doc(FirebaseAuth.instance.currentUser!.uid).update({
            'lastName': lastName,
          })
        : null;
    email != null && firstName!.isNotEmpty
        ? FirebaseAuth.instance.currentUser!
            .updateEmail(email!)
            .then((value) async {
            await user.doc(FirebaseAuth.instance.currentUser!.uid).update({
              'email': email,
            });
          })
        : null;
    companyName != null && firstName!.isNotEmpty
        ? await user.doc(FirebaseAuth.instance.currentUser!.uid).update({
            'companyName': companyName,
          })
        : null;
    password != null && password!.isNotEmpty
        ? FirebaseAuth.instance.currentUser!.updatePassword(password!)
        : null;
  }
}
