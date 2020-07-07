import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:lmao/pages/register.dart';
import 'package:lmao/pages/slideRightRoute.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<FormState>();
  SharedPreferences sharedPreferences;
  String username, password, URL;
  String dialogHead = "";
  String dialogMessage = "";
  bool _isLoading = false;
  dynamic responseData;

  _loadUrl() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      URL = sharedPreferences.getString("url") + "login";
    });
  }

  @override
  initState() {
    _loadUrl();
  }

  _submit() {
    @override
    setState() {
      _isLoading = true;
    }

    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      process();
    }
  }

  Future<http.Response> _login() async {
    var payload = {"username": username, "password": password};
    http.Response response = await http.post(URL,
        body: convert.jsonEncode(payload),
        headers: {"Content-Type": "application/json"});
    return response;
  }

  process() async {
    setState(() {
      _isLoading = true;
    });
    var response;
    var connected = true;
    try {
      response = await _login();
    } catch (e) {
      connected = false;
      setState(() {
        _isLoading = false;
      });
      print(e);
    }
    if (connected) {
      if (response.statusCode == 200) {
        var jsonResponse = convert.jsonDecode(response.body);
        var status = jsonResponse['status']['type'];
        if (status == 'failure') {
          dialogHead = "Failure";
          dialogMessage = jsonResponse['status']['message'];
          setState(() {
            _isLoading = false;
          });
          showAlertDialog();
        } else {
          responseData = jsonResponse;
          setState(() {
            _isLoading = false;
          });
          onSuccess();
        }
      }
    } else {
      setState(() {
        dialogHead = "Connection Error";
        dialogMessage = "Check connection and try again";
      });
      setState(() {
        _isLoading = false;
      });
      showAlertDialog();
    }
  }

  showAlertDialog() {
    showDialog(
      context: context,
      child: new AlertDialog(
        title: Text(dialogHead),
        content: Text(dialogMessage),
        actions: [
          new FlatButton(
              child: const Text("Ok"),
              onPressed: () {
                Navigator.pop(context);
              }),
        ],
      ),
    );
  }

  onSuccess() async {
    sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool("isLogged", true);
    sharedPreferences.setString("token", responseData["token"]);
    sharedPreferences.setString("loggedUser", responseData["username"]);
    sharedPreferences.setString("firstname", responseData["firstname"]);
    sharedPreferences.setString("lastname", responseData["lastname"]);
    sharedPreferences.setBool("status", responseData["verified"]);
    Navigator.pushReplacementNamed(context, '/activity');
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double screenHeight = size.height;
    double fs = 50.0 * MediaQuery.of(context).size.width / 1100;
    return Form(
      key: formKey,
      child: AbsorbPointer(
        absorbing: _isLoading,
        child: Material(
          child: Stack(children: <Widget>[
            Positioned(
                child: Container(
              height: screenHeight * 0.7,
              width: size.width,
              decoration: BoxDecoration(color: Colors.white),
            )),
            Positioned(
              top: screenHeight * 0.7,
              child: Container(
                width: size.width,
                height: screenHeight * 0.3,
                decoration: BoxDecoration(color: Colors.black),
                child: Align(
                  alignment: Alignment.center,
                  child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            SlideRightRoute(page: Register()));
                      },
                      child: Text(
                        "Don't have an account?",
                        style: TextStyle(
                            fontFamily: 'Oxygen',
                            fontSize: fs,
                            color: Colors.white,
                            decoration: TextDecoration.underline),
                      )),
                ),
              ),
            ),
            Positioned(
              child: Padding(
                padding: EdgeInsets.only(left: 50.0, right: 50.0, top: 20.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: size.width,
                    height: screenHeight * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius:
                              2.0, // has the effect of softening the shadow
                          spreadRadius:
                              0.0, // has the effect of extending the shadow
                          offset: Offset(
                            0.0, // horizontal, move right 10
                            0.0, // vertical, move down 10
                          ),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Flexible(
                              flex: 40,
                              child: RichText(
                                text: TextSpan(children: <TextSpan>[
                                  TextSpan(
                                      text: "  Sign In\n",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Oxygen',
                                          fontSize: 50.0 * MediaQuery.of(context).size.width / 500,
                                          fontWeight: FontWeight.bold)),
                                  TextSpan(
                                      text: "Login to your account.",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Oxygen',
                                        fontSize: 50.0 * MediaQuery.of(context).size.width / 1100,
                                      )),
                                ]),
                              ),
                            ),
                            Flexible(
                              flex: 40,
                              child: Column(children: <Widget>[
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 30.0, right: 30.0),
                                    child: Container(
                                      height: 70.0,
                                      child: TextFormField(
                                        style:
                                            new TextStyle(color: Colors.green),
                                        decoration: new InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.person_pin,
                                            color: Colors.black,
                                          ),
                                          hintText: 'Usernames',
                                          hintStyle: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 20.0),
                                        ),
                                        validator: (value) {
                                          if (value.isEmpty)
                                            return "Empty username";
                                          if (value.length < 8) {
                                            return "Atleast 8 digits";
                                          }
                                        },
                                        onSaved: (val) => username = val,
                                      ),
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 30.0, right: 30.0),
                                    child: Container(
                                      height: 70.0,
                                      child: TextFormField(
                                        obscureText: true,
                                        style:
                                            new TextStyle(color: Colors.green),
                                        decoration: new InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.lock,
                                            color: Colors.black,
                                          ),
                                          hintText: 'Password',
                                          hintStyle: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 20.0),
                                        ),
                                        validator: (value) {
                                          if (value.isEmpty)
                                            return "Empty password";
                                          if (value.length < 8) {
                                            return "Atleast 8 digits";
                                          }
                                        },
                                        onSaved: (val) => password = val,
                                      ),
                                    )),
                              ]),
                            ),
                            Flexible(
                              flex: 30,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 60.0, right: 60.0, bottom: 20.0),
                                child: Material(
                                    borderRadius: BorderRadius.circular(20.0),
                                    color: Colors.green,
                                    child: InkWell(
                                        splashColor: Colors.lime,
                                        onTap: () {
                                          _submit();
                                        },
                                        child: Container(
                                          height: 50.0 * MediaQuery.of(context).size.width / 400,
                                          child: Center(
                                            child: (_isLoading)
                                                ? CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  )
                                                : Text(
                                                    "Login",
                                                    style: TextStyle(
                                                        fontSize: 20.0,
                                                        fontFamily: 'Oxygen',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white),
                                                  ),
                                          ),
                                        ))),
                              ),
                            )
                          ],
                        ),
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
}
