import 'dart:js';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tswcd/Pages/Registration_page.dart';
import 'package:tswcd/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';

class SnackBarService {
  static const errorColor = Colors.red;
  static const okColor = Colors.green;

  static Future<void> showSnackBar(
      BuildContext context, String message, bool error) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: error ? errorColor : okColor,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}




class RegistrationBusi extends StatefulWidget {
  @override
  State<RegistrationBusi> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<RegistrationBusi> {
  Future<void> signupemailpass(String email, String pass) async {
    await _auth.signInWithEmailAndPassword(email: email, password: pass);
  }

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _saveToDatabase() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        String currentDate = DateTime.now().toIso8601String().split('T')[0];
        // Retrieve the name using the UID from the users branch
        final nameSnapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').once();
        String name = nameSnapshot.snapshot.value?.toString() ?? '';

        // Set the user's email and name in the database under the 'users' branch
        await FirebaseDatabase.instance.ref('users/${user.uid}').set({
          'email': user.email,
          'name': namecontroller.text.trim(),
          'IIN': IINcontroller.text.trim(),
          'role': 'Busi',
          'interests': {
            'sport': 0,
            'IT':0,
            'culture':0,
            'charity':0,
            'study':0,
          }
        });
      }
    });
  }
  Future<void> registerUser(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

    } on FirebaseAuthException catch (e) {

    }
  }
  TextEditingController IINcontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController namecontroller=TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    IINcontroller.dispose();
    emailcontroller.dispose();
    namecontroller.dispose();
    passwordcontroller.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: true,
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key:_formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                  ),
                  Row(
                    children: [
                      if (isDesktop(context))
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width:
                                MediaQuery.of(context).size.shortestSide / 2,
                                height:
                                MediaQuery.of(context).size.shortestSide / 2,
                                child: Container(
                                  width: 300,
                                  height: 230,
                                  decoration: BoxDecoration(color: Colors.white),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(67.0),
                                    child: Image.asset(
                                      'assets/images/ptr_neskuchno.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              Text(
                                'Добро пожаловать на NEskuchnoPtr,\n систему поиска развлечения в Петропавловске',
                                style: TextStyle(fontFamily: "Futura"),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (!isDesktop(context))
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width:
                                    MediaQuery.of(context).size.shortestSide /
                                        2,
                                    height:
                                    MediaQuery.of(context).size.shortestSide /
                                        2,
                                    child: Container(

                                      width: 300,
                                      height: 230,
                                      decoration:
                                      BoxDecoration(color: Colors.white,),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(67.0),
                                        child: Image.asset(

                                          'assets/images/ptr_neskuchno.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10,),

                                  Text(
                                    'Добро пожаловать на NEskuchnoPtr,\nсистему поиска развлечения в Петропавловске',
                                    style: TextStyle(fontFamily: 'Futura'),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            SizedBox(
                              height: 10,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Введите свое ИИН:',
                                    style: TextStyle(
                                      fontFamily: 'Futura',
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding:
                                  EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                                  child: Container(
                                    width: 450,
                                    height: 50,
                                    child: SizedBox(
                                      height: 70,
                                      child: TextFormField(
                                        controller: IINcontroller,
                                        textCapitalization: TextCapitalization.none,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                          Color.fromRGBO(46, 46, 93, 0.04),
                                          labelText: 'ИИН',
                                          labelStyle: TextStyle(
                                            fontFamily: 'Futura',
                                            fontWeight: FontWeight.normal,
                                          ),
                                          errorStyle: TextStyle(
                                            fontSize: 12.0, // Set your desired error font size
                                            color: Colors.red,
                                          ),
                                          floatingLabelStyle: TextStyle(
                                            fontFamily: 'Futura',
                                            fontWeight: FontWeight.normal,
                                            color: Colors.brown,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Futura',
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value ) {
                                          if (value == null || value.isEmpty || value.length !=12 ) {
                                            return 'Пожалуйста введите свой ИИН';
                                          }

                                          return null; // means input is correct
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20,),
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Введите свое имя:',
                                    style: TextStyle(
                                      fontFamily: 'Futura',
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding:
                                  EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                                  child: Container(
                                    width: 450,
                                    height: 50,
                                    child: SizedBox(
                                      height: 70,
                                      child: TextFormField(
                                        controller: namecontroller,
                                        textCapitalization: TextCapitalization.none,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                          Color.fromRGBO(46, 46, 93, 0.04),
                                          labelText: 'Имя',
                                          labelStyle: TextStyle(
                                            fontFamily: 'Futura',
                                            fontWeight: FontWeight.normal,
                                          ),
                                          floatingLabelStyle: TextStyle(
                                            fontFamily: 'Futura',
                                            fontWeight: FontWeight.normal,
                                            color: Colors.brown,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Futura',
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Пожалуйста введите свое имя';
                                          }
                                          return null; // means input is correct
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20,),
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Введите почту:',
                                    style: TextStyle(
                                      fontFamily: 'Futura',
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                SizedBox(height: 15,),
                                Padding(
                                  padding:
                                  EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                                  child: Container(
                                    width: 450,
                                    height: 50,
                                    child: SizedBox(
                                      height: 70,
                                      child: TextFormField(
                                        controller: emailcontroller,
                                        textCapitalization: TextCapitalization.none,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                          Color.fromRGBO(46, 46, 93, 0.04),
                                          labelText: 'Электронная почта',
                                          labelStyle: TextStyle(
                                            fontFamily: 'Futura',
                                            fontWeight: FontWeight.normal,
                                          ),
                                          floatingLabelStyle: TextStyle(
                                            fontFamily: 'Futura',
                                            fontWeight: FontWeight.normal,
                                            color: Colors.brown,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Futura',
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Введите эл почту';
                                          } else if (!value.contains('@')) {
                                            return 'Введите правильную эл почту';
                                          }
                                          return null; // means input is correct
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Введите пароль:',
                                    style: TextStyle(
                                      fontFamily: 'Futura',
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding:
                                  EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                                  child: Container(
                                    width: 450,
                                    height: 50,
                                    child: SizedBox(
                                      height: 130,
                                      child: TextFormField(
                                        controller: passwordcontroller,
                                        textCapitalization: TextCapitalization.none,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                          Color.fromRGBO(46, 46, 93, 0.04),
                                          labelText: 'Пароль',
                                          labelStyle: TextStyle(
                                            fontFamily: 'Futura',
                                            fontWeight: FontWeight.normal,
                                          ),
                                          floatingLabelStyle: TextStyle(
                                            fontFamily: 'Futura',
                                            fontWeight: FontWeight.normal,
                                            color: Colors.brown,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Futura',
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        keyboardType: TextInputType.visiblePassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Ввведите пароль';
                                          } else if (value.length < 6) {
                                            return 'Пароль должен быть минимум 6 символов в длину';
                                          }
                                          return null; // means input is correct
                                        },

                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                              EdgeInsetsDirectional.fromSTEB(0, 50, 0, 0),
                              child: SizedBox(
                                height: 50,
                                width: 300,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) { // <-- Add this line
                                      // If the form is valid, display a Snackbar.
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text('Аккаунт успешно создан')));

                                      // Call your registration logic here
                                      registerUser(emailcontroller.text.trim(), passwordcontroller.text.trim());
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    primary: Color(
                                        0xFF4838D1), // Replace with your desired button color
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Зарегестрироваться',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w100,
                                          fontFamily: 'Futura',
                                          color: Colors.white,
                                          fontSize: 16,
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
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[700],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Если у вас есть аккаунт',
                                    softWrap: true,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                                GestureDetector(
                                  child: Text(
                                    ' войдите.',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => MyHomePage()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),child:
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[700],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                    child: Text(
                                      'А если вы обычный пользователь,то заходите ',
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[700]),
                                    )),
                                GestureDetector(
                                  child: Text(
                                    ' сюда ',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => Registration()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}