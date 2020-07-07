import 'package:flutter/material.dart';
import 'package:async/async.dart';

class Date extends StatelessWidget {
  compare() async {
    // String date1 = '2020-07-02 15:45:38';
    // DateTime todayDate1 = DateTime.parse(date1);
    // DateTime todayDate2 = DateTime.now();
    // var diff = todayDate2.difference(todayDate1).inSeconds;
    // print(todayDate1);
    // print(todayDate2);
    String a = 'LbcTv,2018-09-27 13:30:47';
    print(a.substring(6));
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        body: Center(
            child: Container(
      child: RaisedButton(
        onPressed: () {
          compare();
        },
        color: Colors.blue,
        child: Text(
          'Raised Button',
          style: TextStyle(color: Colors.white),
        ),
      ),
    )));
  }
}
