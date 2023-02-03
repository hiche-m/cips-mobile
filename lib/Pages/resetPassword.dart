import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class Reset extends StatefulWidget {
  const Reset({Key? key}) : super(key: key);

  @override
  State<Reset> createState() => _ResetState();
}

class _ResetState extends State<Reset> {
  final emailController = TextEditingController();
  final GlobalKey<FormState> _resetKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();

    super.dispose();
  }

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
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => value != null && !EmailValidator.validate(value)
              ? '      Please enter a valid email.'
              : null,
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        backgroundColor: Color.fromARGB(255, 23, 24, 23),
        material: (_, __) => MaterialAppBarData(
          elevation: 0,
        ),
        title: Text("Reset password"),
      ),
      body: Container(
        decoration: BoxDecoration(color: Color.fromARGB(255, 23, 24, 23)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Forgot Password?",
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: 35.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                SizedBox(
                  height: 5.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "You will be sent an email with a password reset link if the email you provide already exists.",
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: 15.0,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 15.0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: _buildUser(),
                ),
                SizedBox(
                  height: 15.0,
                ),
                /*                                                              Submit button*/
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Container(
                    height: 55.0,
                    child: ElevatedButton(
                      onPressed: () {
                        resetPass(emailController.text.trim());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(),
                          Text(
                            "Send link",
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
                            Colors.tealAccent[700]!),
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
              ]),
        ),
      ),
    );
  }

  Future resetPass(email) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SpinKitCubeGrid(
        color: Colors.white,
        size: 35.0,
      ),
    );
    try {
      await _auth.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('A password reset email has been sent.'),
      ));
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message!),
      ));
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
