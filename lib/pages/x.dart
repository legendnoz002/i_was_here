import 'package:flutter/material.dart';
import 'package:lmao/pages/customDialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class X extends StatefulWidget {
  Xstate createState() => Xstate();
}

class Xstate extends State<X> {
SharedPreferences sharedPreferences;
  _logout() async {
    sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("token", null);
    sharedPreferences.setBool("isLogged", null);
    sharedPreferences.setString("loggedUser", null);
    sharedPreferences.setBool("status", null);
    sharedPreferences.setString("firstname", null);
    sharedPreferences.setString("lastname", null);
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        body: Container(
            child: Center(
      child: Icon(Icons.clear)
    )));
  }
}
