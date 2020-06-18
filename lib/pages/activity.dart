import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lmao/models/log_models.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:lmao/pages/profile.dart';
import 'package:lmao/pages/customDialog.dart';
import 'package:lmao/custom/my_flutter_app_icons.dart';

class Activity extends StatefulWidget {
  @override
  _ActivityState createState() => _ActivityState();
}

class _ActivityState extends State<Activity> {
  SharedPreferences sharedPreferences;
  String barcode;
  String eventName;
  String fetchURL,
      joinURL,
      scanURL,
      imgURL,
      verifiedURL,
      _user = "",
      _firstname = "",
      _lastname = "";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  var _jsonData, now;
  File galleryFile;
  List events = [];
  bool _isLoading = false, _update = false, _status = false, _flag = false;
  Image image = null;

  _selectFileFromCamera() async {
    final _file = await ImagePicker.pickImage(source: ImageSource.camera);
    if (_file != null) {
      setState(() {
        galleryFile = _file;
        _scaffoldKey.currentState.openEndDrawer();
      });
    }
  }

  _loadFetchUrl() async {
    sharedPreferences = await SharedPreferences.getInstance();
    fetchURL = sharedPreferences.getString("url") + "get_event";
    joinURL = sharedPreferences.getString("url") + "join_event";
    scanURL = sharedPreferences.getString("url") + "read_qr";
    verifiedURL = sharedPreferences.getString("url") + "verified";
  }

  _loadImg() {
    now = DateTime.now();
    String url = imgURL +
        "profile_image/" +
        _user +
        "?v=" +
        now.millisecondsSinceEpoch.toString();
    setState(() {
      image = Image.network(
        url,
      );
    });
  }

  Future<http.Response> _joinEvent(File image) async {
    _isLoading = true;
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');
    final imageUploadRequest =
        http.MultipartRequest('Post', Uri.parse(joinURL));
    final file = await http.MultipartFile.fromPath('file', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploadRequest.files.add(file);
    imageUploadRequest.fields['username'] =
        sharedPreferences.getString("loggedUser");
    imageUploadRequest.fields['eventKey'] = barcode;
    imageUploadRequest.fields['ext'] = mimeTypeData[1];

    final streamResponse = await imageUploadRequest.send();
    final response = await http.Response.fromStream(streamResponse);

    return response;
  }

  _process() async {
    var response;
    var connected = true;
    await _selectFileFromCamera();
    try {
      response = await _joinEvent(galleryFile);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      connected = false;
      print(e);
    }
    if (connected) {
      if (response.statusCode == 201) {
        showDialog(
          context: context,
          child: CupertinoAlertDialog(
              title: Text("Alert"),
              content: Text("No face was found."),
              actions: [
                CupertinoDialogAction(
                  child: Text("Got it"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ]),
        );
      }
    }
  }

  Stream<List> fetchPost() async* {
    var payload = {"username": _user};
    while (true) {
      await Future.delayed(Duration(seconds: 7));
      http.Response response = await http.post(fetchURL,
          body: jsonEncode(payload),
          headers: {"Content-Type": "application/json"});
      events.clear();
      _jsonData = json.decode(response.body);
      if (_update) {
        _loadImg();
        _update = false;
      }
      for (var i in _jsonData) {
        LogModel _event = LogModel(
            i["date_time"], i["event_type"], i["event_name"], i["_id"]);
        events.add(_event);
      }
      if (_jsonData.length != 0) {
        if (_jsonData[0]['verified'] && !_status) {
          setState(() {
            _status = true;
          });
        }
      }
      yield events;
    }
  }

  _getUser() async {
    sharedPreferences = await SharedPreferences.getInstance();
    _user = sharedPreferences.getString('loggedUser');
    _firstname = sharedPreferences.getString('firstname');
    _lastname = sharedPreferences.getString('lastname');
  }

  _logout() async {
    sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("token", null);
    sharedPreferences.setBool("isLogged", null);
    sharedPreferences.setString("loggedUser", null);
    sharedPreferences.setBool("status", null);
    sharedPreferences.setString("firstname", null);
    sharedPreferences.setString("lastname", null);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void initState() {
    _loadFetchUrl();
    _getUser();
    super.initState();
  }

  @override
  didChangeDependencies() async {
    now = DateTime.now();
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      imgURL = sharedPreferences.getString("url") +
          "profile_image/" +
          sharedPreferences.getString("loggedUser") +
          "?v=" +
          now.millisecondsSinceEpoch.toString();
      _status = sharedPreferences.getBool('status');
    });
    image = Image.network(
      imgURL,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent loadingProgress) {
        if (loadingProgress == null) return child;
        return CircularProgressIndicator();
      },
    );

    precacheImage(image.image, context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Colors.white,
        key: _scaffoldKey,
        drawer: SafeArea(
          child: Drawer(
              child: ListView(padding: EdgeInsets.zero, children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black87),
              child: Container(
                child: Row(children: <Widget>[
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Flexible(
                          flex: 10,
                          child: ClipOval(
                            child: image,
                          ),
                        ),
                        Flexible(
                          flex: 4,
                          child: Text(
                            _firstname,
                            style: TextStyle(
                                fontSize: 18.0,
                                fontFamily: 'Oxygen',
                                color: Colors.white),
                          ),
                        ),
                        Flexible(
                          flex: 4,
                          child: Text(_lastname,
                              style: TextStyle(
                                  fontSize: 18.0,
                                  fontFamily: 'Oxygen',
                                  color: Colors.white)),
                        ),
                      ]),
                ]),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('My Profile',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'Oxygen',
                  )),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Profile((value) {
                              setState(() {
                                _update = value;
                              });
                            })));
              },
            ),
            ListTile(
              leading: Icon(Icons.center_focus_weak),
              title: Text('Join',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'Oxygen',
                  )),
              onTap: () {
                scan(1);
              },
            ),
            if (_status)
              ListTile(
                leading: Icon(Icons.radio_button_checked),
                title: Text('Verified',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontFamily: 'Oxygen',
                    )),
                onTap: () {
                  scan(2);
                },
              ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'Oxygen',
                  )),
              onTap: () {
                _logout();
              },
            )
          ])),
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 24),
          child: Column(
            children: <Widget>[
              Flexible(
                flex: 8,
                child: Stack(
                  children: <Widget>[
                    Container(
                        child: Container(
                      height: 50.0 * size.width / 300,
                      decoration: (BoxDecoration(color: Colors.black)),
                      child: Stack(children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: Colors.orange,
                                child: SizedBox(
                                  width: 70.0,
                                  height: 70.0,
                                  child: Icon(
                                    Icons.menu,
                                    color: Colors.white,
                                    size: 40.0,
                                  ),
                                ),
                                onTap: () async {
                                  await Future.delayed(
                                      Duration(milliseconds: 150));
                                  _scaffoldKey.currentState.openDrawer();
                                },
                              )),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "ACTIVITY",
                            style: TextStyle(
                                fontSize: 50.0 * size.width / 1000,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        )
                      ]),
                    )),
                  ],
                ),
              ),
              if(!_status)
              Flexible(
                flex: 10,
                child: Container(
                  height: 50.0 * size.width / 350,
                  color: Color(0xffababab),
                  child: Stack(children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding: EdgeInsets.only(right: 10.0),
                          child: (_status)
                              ? Icon(
                                  Icons.done,
                                  size: 40.0,
                                  color: Colors.green,
                                )
                              : Icon(
                                  Icons.clear,
                                  size: 40.0,
                                  color: Colors.red,
                                )),
                    )
                  ]),
                ),
              ),
              Flexible(
                flex: 70,
                child: Container(
                    color: Colors.white,
                    child: StreamBuilder(
                        stream: fetchPost(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data.length == 0) {
                              return Center(
                                child: Container(
                                  child: Text("You never join any event.",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Oxygen',
                                          fontSize: 20.0)),
                                ),
                              );
                            } else {
                              return ListView.builder(
                                itemBuilder: (BuildContext context, int index) {
                                  return Container(
                                    color: Colors.white,
                                    child: Stack(
                                      children: <Widget>[
                                        Padding(
                                            padding: EdgeInsets.only(
                                                left: 10.0, right: 10.0),
                                            child: Card(
                                              child: Container(
                                                width: size.width,
                                                height: 50.0 * size.width / 170,
                                                decoration: BoxDecoration(
                                                    color: Colors.white),
                                                child: Stack(children: <Widget>[
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(10.0),
                                                    child: Align(
                                                        alignment:
                                                            Alignment.topLeft,
                                                        child: Text(
                                                          'Status : ',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'Oxygen',
                                                              fontSize: 50.0 *
                                                                  size.width /
                                                                  1100),
                                                        )),
                                                  ),
                                                  Positioned(
                                                    left: 80.0,
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 5.0, left: 5.0),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            color: (snapshot
                                                                        .data[
                                                                            index]
                                                                        .type ==
                                                                    "fail")
                                                                ? Colors.red
                                                                : (snapshot
                                                                            .data[
                                                                                index]
                                                                            .type ==
                                                                        "attended")
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .yellow,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        40.0)),
                                                        child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    5.0),
                                                            child: Text(
                                                              snapshot
                                                                  .data[index]
                                                                  .type,
                                                              style: TextStyle(
                                                                  fontSize: 50.0 *
                                                                      size
                                                                          .width /
                                                                      1100,
                                                                  fontFamily:
                                                                      'Oxygen',
                                                                  color: Colors
                                                                      .white),
                                                            )),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 10.0,
                                                        bottom: 20.0),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                          snapshot.data[index]
                                                              .dateTime,
                                                          style: TextStyle(
                                                              fontSize: 50.0 *
                                                                  size.width /
                                                                  1500,
                                                              fontFamily:
                                                                  'Oxygen',
                                                              color: Colors
                                                                  .black54)),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(10.0),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.bottomLeft,
                                                      child: Container(
                                                          decoration: BoxDecoration(
                                                              color:
                                                                  Colors.orange,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          40.0)),
                                                          child: Padding(
                                                                         padding: EdgeInsets.all(10.0)   ,                                          child: Text(snapshot
                                                                .data[index]
                                                                .eventName,style: TextStyle(color: Colors.black,fontSize: 50.0 * size.width / 1100,fontFamily: 'Oxygen')),
                                                          )),
                                                    ),
                                                  ),
                                                  if (snapshot
                                                          .data[index].type ==
                                                      "fail")
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 10.0),
                                                      child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: InkWell(
                                                              splashColor: Colors
                                                                  .transparent,
                                                              onTap: () {
                                                                showDialog(
                                                                    context:
                                                                        context,
                                                                    builder: (BuildContext
                                                                            context) =>
                                                                        CustomDialog(
                                                                            barcode:
                                                                                snapshot.data[index].id));
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            10.0),
                                                                child: Icon(
                                                                  MyFlutterApp
                                                                      .qrcode_1,
                                                                  size: 50 *
                                                                      MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width /
                                                                      500,
                                                                  color: (snapshot.data[index].type ==
                                                                              "attended" ||
                                                                          snapshot.data[index].type ==
                                                                              "waiting")
                                                                      ? Colors
                                                                          .transparent
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                              ),
                                                            ),
                                                          )),
                                                    )
                                                ]),
                                              ),
                                            )),
                                      ],
                                    ),
                                  );
                                },
                                itemCount: snapshot.data.length,
                              );
                            }
                          } else {
                            return Align(
                                alignment: Alignment.center,
                                child: Container(
                                    child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                )));
                          }
                        })),
              ),
            ],
          ),
        ),
        floatingActionButton: Container(
          height: 50.0 * size.width / 300,
          width: 50.0 * size.width / 300,
          child: FittedBox(
            child: FloatingActionButton(
              onPressed: () {
                scan(1);
              },
              child:
                  Icon(Icons.center_focus_weak, size: 50.0 * size.width / 700),
              backgroundColor: Colors.black,
            ),
          ),
        ));
  }

  Future<Widget> eventDetail() async {
    var payload = {
      "eventKey": barcode,
      "username": sharedPreferences.getString("loggedUser")
    };
    var response = await http.post(scanURL,
        body: jsonEncode(payload),
        headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      var msg = jsonResponse['msg'];
      if (msg == 'found') {
        var title = jsonResponse['event_name'];
        return showDialog(
          context: context,
          child: CupertinoAlertDialog(
              title: Text("Do you want to join?"),
              content: Text(title),
              actions: [
                CupertinoDialogAction(
                  child: Text("No"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: Text("Yes"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _process();
                  },
                ),
              ]),
        );
      } else if (msg == 'fake secret') {
        return showDialog(
          context: context,
          child: CupertinoAlertDialog(
              title: Text("Alert"),
              content: Text("This QRCode is not valid."),
              actions: [
                CupertinoDialogAction(
                  child: Text("Got it"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ]),
        );
      }
    } else {
      return showDialog(
        context: context,
        child: CupertinoAlertDialog(
            title: Text("Alert"),
            content: Text("You already joined this event."),
            actions: [
              CupertinoDialogAction(
                child: Text("Got it"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ]),
      );
    }
  }

  Future verified() async {
    //send waiter objectID && logged username
    var payload = {"waiter": barcode};
    var response = await http.post(verifiedURL,
        body: jsonEncode(payload),
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 201) {
      showDialog(
        context: context,
        child: CupertinoAlertDialog(
            title: Text("Alert"),
            content: Text("This QRCode is not valid."),
            actions: [
              CupertinoDialogAction(
                child: Text("Got it"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ]),
      );
    }
  }

  scan(int option) async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() {
        this.barcode = barcode;
      });
      if (option == 1) {
        eventDetail();
      }
      if (option == 2) {
        verified();
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        // The user did not grant the camera permission.
      } else {
        // Unknown error.
      }
    } on FormatException {
      // User returned using the "back"-button before scanning anything.
    } catch (e) {
      // Unknown error.
    }
  }
}
