import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:image_cropper/image_cropper.dart';

class Register2 extends StatefulWidget {
  final String username, password, firstname, lastname;
  const Register2(this.username, this.password, this.firstname, this.lastname);
  @override
  _Register2State createState() => _Register2State();
}

class _Register2State extends State<Register2> {
  SharedPreferences sharedPreferences;
  File galleryFile;
  String URL, message, _text = 'Sign me in!';
  bool _isLoading = false;
  Color _color = Colors.white,
      _textColor = Colors.black,
      _iconColor = Colors.white;

  @override
  initState() {
    _loadUrl('register2');
  }

  _loadUrl(String url) async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      URL = sharedPreferences.getString('url') + url;
    });
  }

  _selectImageFromCamera() async {
    final _file = await ImagePicker.pickImage(source: ImageSource.camera);
    if (_file != null) {
      File _cropped = await ImageCropper.cropImage(
          sourcePath: _file.path,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 100,
          maxHeight: 700,
          maxWidth: 700,
          cropStyle: CropStyle.circle,
          compressFormat: ImageCompressFormat.jpg,
          androidUiSettings: AndroidUiSettings(
            toolbarColor: Colors.grey,
            backgroundColor: Colors.white,
          ),
          iosUiSettings: IOSUiSettings(
            minimumAspectRatio: 1.0,
          ));
      setState(() {
        galleryFile = _cropped;
        _text = 'Sign me in!';
        _textColor = Colors.black;
        _color = Colors.white;
        _iconColor = Colors.white38;
      });
    }
  }

  Future<http.Response> _register(File image) async {
    _loadUrl('register2');
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');
    final imageUploadRequest = http.MultipartRequest('Post', Uri.parse(URL));
    final file = await http.MultipartFile.fromPath('profile_image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploadRequest.fields['username'] = widget.username;
    imageUploadRequest.fields['password'] = widget.password;
    imageUploadRequest.fields['firstname'] = widget.firstname;
    imageUploadRequest.fields['lastname'] = widget.lastname;
    imageUploadRequest.fields['ext'] = mimeTypeData[1];
    imageUploadRequest.files.add(file);

    final streamResponse = await imageUploadRequest.send();
    final response = await http.Response.fromStream(streamResponse);

    return response;
  }

  Future<http.Response> _sendFile(File image) async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      URL = sharedPreferences.getString('url') + 'save_image';
    });
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');
    final imageUploadRequest = http.MultipartRequest('Post', Uri.parse(URL));
    final file = await http.MultipartFile.fromPath('profile_image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploadRequest.fields['_username'] = widget.username;
    imageUploadRequest.files.add(file);

    final streamResponse = await imageUploadRequest.send();
    final response = await http.Response.fromStream(streamResponse);
    return response;
  }

  process() async {
    setState(() {
      _isLoading = true;
    });
    var response;
    var connected = true;
    try {
      response = await _register(galleryFile);
    } catch (e) {
      connected = false;
      print(e);
    }
    if (connected) {
      if (response.statusCode == 200) {
        var jsonResponse = convert.jsonDecode(response.body);
        var msg = jsonResponse['msg'];
        print("this is reponse message : $msg");
        if (msg == 'face was not found in the image') {
          setState(() {
            _isLoading = false;
            _text = 'Image has no face';
            _textColor = Colors.black;
            _color = Colors.yellowAccent;
          });
        }
        if (msg == 'something is wrong') {
          setState(() {
            _isLoading = false;
            _text = 'Please try again';
            _textColor = Colors.black;
            _color = Colors.yellowAccent;
          });
        }
        if (msg == 'bad file type') {
          setState(() {
            _isLoading = false;
            _text = "Bad file type";
            _textColor = Colors.black;
            _color = Colors.yellowAccent;
          });
        }
        if (msg == 'register success!') {
          await _sendFile(galleryFile);
          setState(() {
            _textColor = Colors.white;
            _color = Colors.green;
          });
          await Future.delayed(Duration(seconds: 2));
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  showAlertDialog() {
    showDialog(
      context: context,
      child: AlertDialog(
        content: Text(message),
        actions: [
          FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.pop(context);
              }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double screenHeight = size.height;
    double fs = 50.0 * MediaQuery.of(context).size.width / 900;
    // TODO: implement build
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          centerTitle: true,
          title: Text('Choose your image',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: fs,
                  fontFamily: 'Oxygen',
                  fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: Column(children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
                left: 30.0, right: 30.0, top: 50.0, bottom: 30.0),
            child: Material(
              borderRadius: BorderRadius.circular(360.0),
              child: InkWell(
                splashColor: Colors.white,
                onTap: () {
                  _selectImageFromCamera();
                },
                child: Container(
                  width: size.width,
                  height: screenHeight * 0.5,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: galleryFile == null
                          ? AssetImage('images/Black.jpg')
                          : FileImage(galleryFile),
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius:
                            10.0, // has the effect of softening the shadow
                        spreadRadius:
                            0.0, // has the effect of extending the shadow
                        offset: Offset(
                          0.0, // horizontal, move right 10
                          0.0, // vertical, move down 10
                        ),
                      )
                    ],
                  ),
                  child: Center(
                      child: Icon(
                    Icons.camera_alt,
                    size: 150.0,
                    color: _iconColor,
                  )),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 70.0, right: 70.0, top: 40.0),
            child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                child: InkWell(
                    onTap: () {
                      if (galleryFile == null) {
                        setState(() {
                          _text = 'No image';
                          _textColor = Colors.white;
                          _color = Colors.red;
                        });
                      } else {
                        process();
                      }
                    },
                    child: Container(
                      height: 50.0,
                      decoration: BoxDecoration(
                          color: _color,
                          border: Border.all(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.circular(30.0)),
                      child: Center(
                        child: (_isLoading)
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_textColor),
                              )
                            : Text(_text,
                                style: TextStyle(
                                    color: _textColor,
                                    fontFamily: 'Oxygen',
                                    fontSize: fs,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ))),
          ),
        ]),
      ),
    );
  }
}
