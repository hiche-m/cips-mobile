import 'package:application/userDB.dart';
import 'package:application/TextFormulations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'auth.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key, bool? showEror})
      : this.showEror = showEror,
        super(key: key);
  final bool? showEror;
  @override
  State<SignUp> createState() => _SignUpState(error: showEror);
}

class _SignUpState extends State<SignUp> {
  String? _firstName;
  String? _lastName;
  String? _company;
  String? _email;
  String? _password;
  String? _rePassword;
  late bool? error;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isAdmin = true;
  final GlobalKey<FormState> signUpKey = GlobalKey<FormState>();

  _SignUpState({required this.error});

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    companyController.dispose();

    super.dispose();
  }

  Widget _buildFirstName() {
    return Stack(
      children: [
        Container(
          height: 50.0,
          decoration: BoxDecoration(
              color: Colors.grey[900],
              //border: Border.all(),
              borderRadius: BorderRadius.circular(25)),
        ),
        Center(
          child: TextFormField(
            controller: firstNameController,
            maxLines: 1,
            style: const TextStyle(
                fontFamily: 'Titillium Web',
                height: 1.5,
                fontSize: 15.0,
                color: Colors.white70),
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: 'First Name',
              hintStyle:
                  TextStyle(fontFamily: 'Titillium Web', color: Colors.white30),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 5.0),
                child: Icon(
                  Icons.account_circle_rounded,
                  color: Colors.white30,
                  size: 17.0,
                ),
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(/*top: 8.0, */ left: 10.0),
                child: Text(
                  "*",
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: "Mukta",
                    fontSize: 25.0,
                  ),
                ),
              ),
            ),
            validator: (value) => value != null && value.isEmpty
                ? '      Please enter a valid first name.'
                : null,
            onSaved: (String? value) {
              _firstName = value;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLastName() {
    return Stack(
      children: [
        Container(
          height: 50.0,
          decoration: BoxDecoration(
              color: Colors.grey[900],
              //border: Border.all(),
              borderRadius: BorderRadius.circular(25)),
        ),
        Center(
          child: TextFormField(
            controller: lastNameController,
            maxLines: 1,
            style: const TextStyle(
                fontFamily: 'Titillium Web',
                height: 1.5,
                fontSize: 15.0,
                color: Colors.white70),
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: 'Last Name',
              hintStyle:
                  TextStyle(fontFamily: 'Titillium Web', color: Colors.white30),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 5.0),
                child: Icon(
                  Icons.account_circle_rounded,
                  color: Colors.white30,
                  size: 17.0,
                ),
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(/*top: 8.0, */ left: 10.0),
                child: Text(
                  "*",
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: "Mukta",
                    fontSize: 25.0,
                  ),
                ),
              ),
            ),
            validator: (value) => value != null && value.isEmpty
                ? '      Please enter a valid last name.'
                : null,
            onSaved: (String? value) {
              _lastName = value;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompany() {
    return Container(
      height: 50.0,
      decoration: BoxDecoration(
          color: Colors.grey[900],
          //border: Border.all(),
          borderRadius: BorderRadius.circular(25)),
      child: Center(
        child: TextFormField(
          controller: companyController,
          maxLines: 1,
          style: TextStyle(
              fontFamily: 'Titillium Web',
              height: 1.5,
              fontSize: 15.0,
              color: Colors.white70),
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: 'Company name',
            hintStyle:
                TextStyle(fontFamily: 'Titillium Web', color: Colors.white30),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: Icon(
                Icons.business,
                color: Colors.white30,
                size: 17.0,
              ),
            ),
          ),
          validator: (String? value) {
            (value as String).isEmpty ? 'Please enter a company name!' : null;
          },
          onSaved: (String? value) {
            _company = value;
          },
        ),
      ),
    );
  }

  Widget _buildEmail() {
    return Stack(
      children: [
        Container(
          height: 50.0,
          decoration: BoxDecoration(
              color: Colors.grey[900],
              //border: Border.all(),
              borderRadius: BorderRadius.circular(25)),
        ),
        Center(
          child: TextFormField(
            controller: emailController,
            maxLines: 1,
            style: TextStyle(
                fontFamily: 'Titillium Web',
                height: 1.5,
                fontSize: 15.0,
                color: Colors.white70),
            decoration: InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: 'Your email',
              hintStyle:
                  TextStyle(fontFamily: 'Titillium Web', color: Colors.white30),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: Icon(
                  Icons.email_rounded,
                  color: Colors.white30,
                  size: 17.0,
                ),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(/*top: 8.0, */ left: 10.0),
                child: Text(
                  "*",
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: "Mukta",
                    fontSize: 25.0,
                  ),
                ),
              ),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                value != null && !EmailValidator.validate(value)
                    ? '      Please enter a valid email.'
                    : null,
            onSaved: (String? value) {
              _email = value;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPassword() {
    return Stack(children: [
      Container(
        height: 50.0,
        decoration: BoxDecoration(
            color: Colors.grey[900],
            //border: Border.all(),
            borderRadius: BorderRadius.circular(25)),
      ),
      Center(
        child: TextFormField(
          controller: passwordController,
          maxLines: 1,
          obscureText: true,
          style: TextStyle(
              fontFamily: 'Titillium Web',
              height: 1.5,
              fontSize: 15.0,
              color: Colors.white70),
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: 'Create a new password',
            hintStyle:
                TextStyle(fontFamily: 'Titillium Web', color: Colors.white30),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 5.5),
              child: Icon(
                Icons.lock,
                color: Colors.white30,
                size: 17.0,
              ),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(/*top: 8.0, */ left: 10.0),
              child: Text(
                "*",
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: "Mukta",
                  fontSize: 25.0,
                ),
              ),
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => value != null && value.length < 8
              ? '      Password should have at least 6 characters.'
              : null,
          onChanged: (String? value) {
            _password = value;
          },
        ),
      ),
    ]);
  }

  Widget _buildPasswordAgain() {
    return Stack(children: [
      Container(
        height: 50.0,
        decoration: BoxDecoration(
            color: Colors.grey[900],
            //border: Border.all(),
            borderRadius: BorderRadius.circular(25)),
      ),
      Center(
        child: TextFormField(
          maxLines: 1,
          obscureText: true,
          style: const TextStyle(
              fontFamily: 'Titillium Web',
              height: 1.5,
              fontSize: 15.0,
              color: Colors.white70),
          decoration: const InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: 'Enter your password again',
            hintStyle:
                TextStyle(fontFamily: 'Titillium Web', color: Colors.white30),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 5.5),
              child: Icon(
                Icons.lock,
                color: Colors.white30,
                size: 17.0,
              ),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(/*top: 8.0, */ left: 10.0),
              child: Text(
                "*",
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: "Mukta",
                  fontSize: 25.0,
                ),
              ),
            ),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value != null && value.isEmpty) {
              return '      Please enter a valid password.';
            } else if (value != _password) {
              return '      The passwords do not match!';
            }
          },
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;
    return PlatformScaffold(
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSwatch(
            accentColor: Colors.grey, // but now it should be declared like this
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal[700]!, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Form(
                      key: signUpKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 10.0,
                              ),
                              Image(
                                image: AssetImage("assets/icons/Logo.png"),
                                height: 75.0,
                                width: 75.0,
                              ),
                              Text("CIPS Mobile",
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  )),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 15.0, 15.0, 25.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            "Already have an account? ",
                                            style: TextStyle(
                                              fontFamily: 'Titillium Web',
                                              color: Colors.grey,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Auth().toggleSignIn();
                                              Navigator.pushReplacementNamed(
                                                  context, '/auth');
                                            },
                                            child: Text(
                                              "Log In!",
                                              style: TextStyle(
                                                  fontFamily: 'Titillium Web',
                                                  color: Colors.tealAccent[700],
                                                  decoration:
                                                      TextDecoration.underline),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "Create a new account:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.5,
                                  fontFamily: 'Titillium Web',
                                  //fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                error! ? "Something went wrong." : "",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.5,
                                  fontFamily: 'Mukta',
                                  //fontWeight: FontWeight.bold
                                ),
                              ),
                              SizedBox(
                                height: 15.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50.0),
                                child: _buildFirstName(),
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50.0),
                                child: _buildLastName(),
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50.0),
                                child: _buildCompany(),
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50.0),
                                  child: _buildEmail(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50.0),
                                child: _buildPassword(),
                              ),
                              const SizedBox(
                                height: 10.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50.0),
                                child: _buildPasswordAgain(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Choose account type: ",
                                style: TextStyle(
                                  fontFamily: 'Mukta',
                                  color: Colors.white,
                                  fontSize: 17.5 * scale,
                                ),
                              ),
                              const SizedBox(
                                width: 15.0,
                              ),
                              //Admin
                              InkWell(
                                onTap: () {
                                  !isAdmin
                                      ? setState(() {
                                          isAdmin = true;
                                        })
                                      : null;
                                },
                                child: CircleAvatar(
                                  radius: 6.0 * scale,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 4.0 * scale,
                                    backgroundColor: isAdmin
                                        ? Colors.tealAccent
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 5.0,
                              ),
                              InkWell(
                                onTap: () {
                                  !isAdmin
                                      ? setState(() {
                                          isAdmin = true;
                                        })
                                      : null;
                                },
                                child: const Text(
                                  "Admin",
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 12.0,
                              ),
                              //Employee
                              InkWell(
                                onTap: () {
                                  isAdmin
                                      ? setState(() {
                                          isAdmin = false;
                                        })
                                      : null;
                                },
                                child: CircleAvatar(
                                  radius: 6.0 * scale,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 4.0 * scale,
                                    backgroundColor: isAdmin
                                        ? Colors.transparent
                                        : Colors.tealAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 5.0,
                              ),
                              InkWell(
                                onTap: () {
                                  isAdmin
                                      ? setState(() {
                                          isAdmin = false;
                                        })
                                      : null;
                                },
                                child: const Text(
                                  "Employee",
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20.0,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 50.0),
                            child: Container(
                              height: 55.0,
                              child: ElevatedButton(
                                onPressed: () {
                                  signUp(
                                      firstNameController.text,
                                      lastNameController.text,
                                      companyController.text,
                                      emailController.text.trim(),
                                      passwordController.text,
                                      isAdmin);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(),
                                    Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        fontFamily: 'Titillium Web',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(),
                                  ],
                                ),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.tealAccent[700]!),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                      //side: BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35.0),
                        ],
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future signUp(String firstName, String lastName, String companyName,
      String email, String password, bool isAdmin) async {
    final isValid = signUpKey.currentState!.validate();
    if (!isValid) return;

    /*print(TextFormulations.capFix(firstName) +
        TextFormulations.capFix(lastName) +
        TextFormulations.capFix(companyName));*/
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SpinKitCubeGrid(
        color: Colors.white,
        size: 35.0,
      ),
    );
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userDatabase(userID: result.user!.uid).updateUserData(
        capFix(firstName),
        capFix(lastName),
        capFix(companyName),
        "",
        isAdmin,
        email,
        "Seller",
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message!),
      ));
    }
    Auth().toggleSignIn();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacementNamed("/");
    }
  }
}
