import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final TextEditingController controller = new TextEditingController();
  @override
  _ActivityState createState() => _ActivityState();
}

class _ActivityState extends State<Activity> {
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>.broadcast();

  SharedPreferences sharedPreferences;
  String barcode,
      fetchURL,
      joinURL,
      scanURL,
      verifiedURL,
      secretKey,
      _user = "",
      _firstname = "",
      _lastname = "";
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  var _jsonData, now;
  File galleryFile;
  List events = [];
  bool _update = false, _status = false;
  Image image = null;

  _loadFetchUrl() async {
    sharedPreferences = await SharedPreferences.getInstance();
    joinURL = sharedPreferences.getString("url") + "join_event";
    scanURL = sharedPreferences.getString("url") + "read_qr";
    verifiedURL = sharedPreferences.getString("url") + "verified";
  }

  Future _loadPost() async {
    var _jsonResponse;
    sharedPreferences = await SharedPreferences.getInstance();
    fetchURL = sharedPreferences.getString("url") + "get_event/" + _user;
    while (!_streamController.isClosed) {
      http.Response response = await http
          .get(fetchURL, headers: {"Content-Type": "application/json"});
      _jsonResponse = json.decode(response.body);

      if (_jsonResponse.length != 0) {
        if (_jsonResponse[0]['verified'] && !_status) {
          setState(() {
            _status = true;
          });
        }
      }
      if (!_streamController.isClosed) {
        _streamController.add(_jsonResponse);
      }

      await Future.delayed(Duration(seconds: 5));
    }
    print('loop has stop');
  }

  _selectFileFromCamera() async {
    final _file = await ImagePicker.pickImage(source: ImageSource.camera);
    if (_file != null) {
      setState(() {
        galleryFile = _file;
        _scaffoldKey.currentState.openEndDrawer();
      });
    }
  }

  Future<http.Response> _joinEvent(File image) async {
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');
    final imageUploadRequest =
        http.MultipartRequest('Post', Uri.parse(joinURL));
    final file = await http.MultipartFile.fromPath('file', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploadRequest.files.add(file);
    imageUploadRequest.fields['username'] =
        sharedPreferences.getString("loggedUser");
    imageUploadRequest.fields['eventKey'] = secretKey;
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

  _getUser() async {
    sharedPreferences = await SharedPreferences.getInstance();
    print("this is token");
    print(sharedPreferences.getString('token'));
    setState(() {
      _user = sharedPreferences.getString('loggedUser');
      _firstname = sharedPreferences.getString('firstname');
      _lastname = sharedPreferences.getString('lastname');
      _status = sharedPreferences.getBool('status');
    });
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
    _loadImg();
    _loadPost();
    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  _loadImg() async {
    now = DateTime.now();
    sharedPreferences = await SharedPreferences.getInstance();
    String url = sharedPreferences.getString("url") +
        "profile_image/" +
        sharedPreferences.getString("loggedUser") +
        "?v=" +
        now.millisecondsSinceEpoch.toString();
    image = Image.network(
      url,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent loadingProgress) {
        if (loadingProgress == null) return child;
        return CircularProgressIndicator();
      },
    );

    precacheImage(image.image, context);
  }

  Color circleColor(String date) {
    if (date == "Monday") {
      return Colors.yellow[300];
    }
    if (date == "Tuesday") {
      return Colors.pink[300];
    }
    if (date == "Wednesday") {
      return Colors.green[300];
    }
    if (date == "Thursday") {
      return Colors.orange[300];
    }
    if (date == "Friday") {
      return Colors.blue[300];
    }
    if (date == "Saturday") {
      return Colors.purple[300];
    }
    if (date == "Sunday") {
      return Colors.red[300];
    }
  }

  _showDialog() {
    showDialog<String>(
      context: context,
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: widget.controller,
                autofocus: false,
                decoration:
                    InputDecoration(labelText: 'Secret', hintText: 'eg. NxAqy'),
              ),
            )
          ],
        ),
        actions: <Widget>[
          FlatButton(
              child: const Text('Back'),
              onPressed: () {
                Navigator.pop(context);
              }),
          FlatButton(
              child: const Text('Join'),
              onPressed: () {
                setState(() {
                  barcode = widget.controller.text;
                });
                eventDetail();
                widget.controller.clear();
                Navigator.pop(context);
              })
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomInset: false,
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
                                if (_update) {
                                  _loadImg();
                                }
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
            // ListTile(
            //   leading: Icon(Icons.keyboard),
            //   title: Text('Secret Key',
            //       style: TextStyle(
            //         fontSize: 18.0,
            //         fontFamily: 'Oxygen',
            //       )),
            //   onTap: () {
            //     _showDialog();
            //   },
            // ),
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
              if (!_status)
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
                        stream: _streamController.stream,
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
                                itemCount: snapshot.data.length,
                                itemBuilder: (BuildContext context, int index) {
                                  var post = snapshot.data[index];
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
                                                    padding: EdgeInsets.only(
                                                        left: 10.0),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Container(
                                                        width: 70.0,
                                                        height: 70.0,
                                                        decoration: BoxDecoration(
                                                            color: circleColor(
                                                                post['date_time']
                                                                    .substring(
                                                                        11)),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        50.0)),
                                                        child: Center(
                                                          child: Text(
                                                            post['event_name']
                                                                .substring(
                                                                    0, 1),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    'Oxygen',
                                                                fontSize: 50.0 *
                                                                    size.width /
                                                                    900),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 10.0,
                                                      left: 100.0,
                                                    ),
                                                    child: Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          'Status : ',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black54,
                                                              fontFamily:
                                                                  'Oxygen',
                                                              fontSize: 50.0 *
                                                                  size.width /
                                                                  1100),
                                                        )),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 5.0, left: 175.0),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            color: (post[
                                                                        'event_type'] ==
                                                                    "fail")
                                                                ? Colors.red
                                                                : (post['event_type'] ==
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
                                                              post[
                                                                  'event_type'],
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
                                                        left: 100.0,
                                                        bottom: 20.0),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.bottomLeft,
                                                      child: Text(
                                                          post['date_time']
                                                              .substring(0, 10),
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
                                                    padding: EdgeInsets.only(
                                                        left: 90.0,
                                                        bottom: 10.0),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: Container(
                                                          child: Padding(
                                                        padding: EdgeInsets.all(
                                                            10.0),
                                                        child: Text(
                                                            post['event_name'],
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 50.0 *
                                                                    size.width /
                                                                    800,
                                                                fontFamily:
                                                                    'Oxygen')),
                                                      )),
                                                    ),
                                                  ),
                                                  if (post['event_type'] ==
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
                                                                                post['_id']));
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
                                                                      400,
                                                                  color: (post['event_type'] ==
                                                                              "attended" ||
                                                                          post['event_type'] ==
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
      "eventKey": secretKey,
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

  bool checkQR() {
    try {
      secretKey = this.barcode.substring(0, 5);
      DateTime time = DateTime.parse(barcode.substring(6));
      DateTime now = DateTime.now();
      if (now.difference(time).inSeconds > 10) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  scan(int option) async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() {
        this.barcode = barcode;
      });
      switch (option) {
        case 1:
          {
            if (checkQR()) {
              eventDetail();
            } else {
              showDialog(
                context: context,
                child: CupertinoAlertDialog(
                    title: Text("Alert"),
                    content: Text("QRCode has expired."),
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
          break;
        case 2:
          {
            verified();
          }
          break;
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

class _SystemPadding extends StatelessWidget {
  final Widget child;

  _SystemPadding({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return AnimatedContainer(
        //padding: mediaQuery.viewInsets,
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}
