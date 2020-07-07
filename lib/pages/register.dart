import 'package:flutter/material.dart';
import 'package:lmao/pages/register2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lmao/pages/slideRightRoute.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}


class _RegisterState extends State<Register> {
  final formKey = GlobalKey<FormState>();
  String username, password, firstname, lastname, URL;
  SharedPreferences sharedPreferences;
  bool _isLoading = false;

  @override
  initState(){
    _loadUrl();
  }

  _loadUrl() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      URL = sharedPreferences.getString("url") + "register1";
    });
  }

  Future<http.Response> _register() async {
    final req = http.MultipartRequest('Post', Uri.parse(URL));
    req.fields['username'] = username;
    final streamResponse = await req.send();
    final response = await http.Response.fromStream(streamResponse);
    return response;
  }

  showAlertDialog() {
    showDialog(
      context: context,
      child: new AlertDialog(
        content: Text("Username is already used."),
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

  process() async {
    setState(() {
      _isLoading = true;
    });
    var response;
    var connected = true;
    try {
      response = await _register();
    } catch (e) {
      connected = false;
      print(e);
    }
    if (connected) {
      if (response.statusCode == 201) {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
            context,
            SlideRightRoute(
                page: Register2(username, password, firstname, lastname)));
      }
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
        showAlertDialog();
      }
    }
  }

  _validate() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      process();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double screenHeight = size.height;
    double fs = 50.0 * MediaQuery.of(context).size.width / 800;
    double fs2 = 50.0 * MediaQuery.of(context).size.width / 1000;
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Form(
        key: formKey,
        child: Scaffold(
          resizeToAvoidBottomPadding: false,
          appBar: AppBar(
            centerTitle: true,
            title: Text("General information",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fs,
                    fontFamily: 'Oxygen',
                    fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          body: Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 30.0, right: 30.0, top: 40.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0)),
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10.0),
                      child: TextFormField(
                        
                        style: TextStyle(
                            color: Colors.lightGreen[800], fontSize: 20.0),
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person_pin,
                              color: Colors.black,
                            ),
                            hintText: "Username",
                            hintStyle:
                                TextStyle(color: Colors.black, fontSize: fs2),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black))),
                        validator: (value) {
                          if (value.isEmpty) return "Empty username";
                          if (value.length < 8) return "Atleast 8 digits.";
                        },
                        onSaved: (val) => username = val,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0)),
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10.0),
                      child: TextFormField(
                        style: TextStyle(
                            color: Colors.lightGreen[800], fontSize: 20.0),
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock_open,
                              color: Colors.black,
                            ),
                            hintText: "Password",
                            hintStyle:
                                TextStyle(color: Colors.black, fontSize: fs2),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black))),
                        validator: (value) {
                          if (value.isEmpty) return "Empty password";
                          if (value.length < 8) return "Atleast 8 digits.";
                        },
                        onSaved: (val) => password = val,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0)),
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10.0),
                      child: TextFormField(
                        style: TextStyle(
                            color: Colors.lightGreen[800], fontSize: 20.0),
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.black,
                            ),
                            hintText: "Firstname",
                            hintStyle:
                                TextStyle(color: Colors.black, fontSize: fs2),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black))),
                        validator: (value) {
                          if (value.isEmpty) return "Empty firstname";
                        },
                        onSaved: (val) => firstname = val,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0)),
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10.0),
                      child: TextFormField(
                        style: TextStyle(
                            color: Colors.lightGreen[800], fontSize: 20.0),
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Colors.black,
                            ),
                            hintText: "Lastname",
                            hintStyle:
                                TextStyle(color: Colors.black, fontSize: fs2),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black45)),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black))),
                        validator: (value) {
                          if (value.isEmpty) return "Empty lastname";
                        },
                        onSaved: (val) => lastname = val,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 60.0),
                  child: Material(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30.0),
                      child: InkWell(
                        splashColor: Colors.blue[100],
                        onTap: () {
                          _validate();
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          child: Center(
                            child: (_isLoading)
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white))
                                : Text(
                                    "NEXT",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: fs),
                                  ),
                          ),
                        ),
                      )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
