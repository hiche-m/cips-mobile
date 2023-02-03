import 'package:application/Pages/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class SignIn extends StatefulWidget {
  final bool? showError;
  const SignIn({Key? key, bool? error})
      : showError = error,
        super(key: key);

  @override
  State<SignIn> createState() => _SignInState(showError);
}

class _SignInState extends State<SignIn> {
  String? _email;
  String? _password;
  bool? showError;
  String? errorShown;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _signInKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  _SignInState(bool? error) {
    showError = error;
  }

/*                                                                              Email textfield widget*/
  Widget _buildUser() {
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
          controller: emailController,
          style: TextStyle(
              fontFamily: 'Titillium Web',
              height: 1.5,
              fontSize: 15.0,
              color: Colors.white70),
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: false,
            hintText: 'Email',
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
          ),
          validator: (String? value) => (value as String).isEmpty
              ? '      Please enter a valid email.'
              : null,
          onSaved: (String? value) {
            _email = value;
          },
        ),
      ),
    ]);
  }

  bool visible = false;
/*                                                                              Password textfield widget*/
  Widget _buildPassword() {
    return Theme(
      data: ThemeData(
        colorScheme: ThemeData().colorScheme.copyWith(
              primary: Colors.tealAccent[400],
            ),
      ),
      child: Stack(children: [
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
            obscureText: visible ? false : true,
            style: TextStyle(
                fontFamily: 'Titillium Web',
                height: 1.5,
                fontSize: 15.0,
                color: Colors.white70),
            decoration: InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: 'Password',
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
              suffixIcon: PlatformIconButton(
                onPressed: () {
                  setState(() {
                    visible = !visible;
                  });
                },
                icon: Icon(
                    visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 22.5),
              ),
            ),
            validator: (value) => value != null && value.length < 8
                ? '      Please enter a valid password.'
                : null,
            onSaved: (String? value) {
              _password = value;
            },
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      /*                                                                        Background*/
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
                  /*                                                                      Form widget*/
                  child: Form(
                      key: _signInKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              /*                                                        Logo image*/
                              Image(
                                image: AssetImage("assets/icons/Logo.png"),
                                height: 120.0,
                                width: 120.0,
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              Text("CIPS Mobile",
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                          SizedBox(
                            height: 15.0,
                          ),
                          /*                                                              Login Text*/
                          Text(
                            "Log In to your account:",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.5,
                              fontFamily: 'Titillium Web',
                              //fontWeight: FontWeight.bold
                            ),
                          ),
                          SizedBox(
                            height: 15.0,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              showError! ? errorShown! : "",
                              softWrap: true,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.fade,
                              maxLines: 3,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 15.0,
                                fontFamily: 'Mukta',
                                //fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 40.0,
                          ),
                          /*                                                              Build email widget*/
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 50.0),
                            child: _buildUser(),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          /*                                                              Build password widget*/
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 50.0),
                            child: _buildPassword(),
                          ),
                          SizedBox(
                            height: 15.0,
                          ),
                          /*                                                              Submit button*/
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 50.0),
                            child: Container(
                              height: 55.0,
                              child: ElevatedButton(
                                onPressed: () {
                                  signIn(emailController.text.trim(),
                                      passwordController.text.trim());
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(),
                                    Text(
                                      "Log In",
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
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: InkWell(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/pass'),
                              child: Text(
                                "Forgot password?",
                                style: TextStyle(
                                    fontFamily: 'Titillium Web',
                                    color: Colors.tealAccent[700],
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          ),
                          /*                                                              Bottom line text*/
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    0, 5.0, 15.0, 30.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        fontFamily: 'Titillium Web',
                                        color: Colors.grey,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Auth().toggleSignIn();
                                        Navigator.pushReplacementNamed(
                                            context, "/auth");
                                      },
                                      child: Text(
                                        "Sign Up for FREE!",
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

  Future signIn(String Email, String Password) async {
    final isValid = _signInKey.currentState!.validate();
    if (!isValid) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SpinKitCubeGrid(
        color: Colors.white,
        size: 35.0,
      ),
    );
    try {
      await _auth.signInWithEmailAndPassword(
        email: Email,
        password: Password,
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushReplacementNamed("/");
      }
    } on FirebaseAuthException catch (e) {
      /* Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(e.message!),
      )); */
      /* _signInKey.currentState!.validate(); */
      setState(() {
        showError = true;
        errorShown = e.message!;
      });
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
