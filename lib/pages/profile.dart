import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

typedef value = bool Function(bool);

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
  value callback;
  Profile(this.callback);
}

class _ProfileState extends State<Profile> {
  File galleryFile;
  SharedPreferences sharedPreferences;
  String imgURL, updateURL, checkURL, _text = 'Update';
  var image;
  Color _textColor = Colors.black, _color = Colors.white;
  bool _isLoading = false, _selected = true;
  var now = new DateTime.now();

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
        _color = Colors.black;
        _textColor = Colors.white;
        _selected = false;
        _text = 'Press to update';
      });
    }
  }

  _loadImg() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      imgURL = sharedPreferences.getString("url") +
          "profile_image/" +
          sharedPreferences.getString("loggedUser") +
          "?v=" +
          now.millisecondsSinceEpoch.toString();
    });
  }

  Future<http.Response> _checkImage(File image) async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      checkURL = sharedPreferences.getString('url') + 'check_image';
      _isLoading = true;
    });
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');
    final imageUploadRequest =
        http.MultipartRequest('Post', Uri.parse(checkURL));
    final file = await http.MultipartFile.fromPath('profile_image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploadRequest.files.add(file);
    imageUploadRequest.fields['_username'] =
        sharedPreferences.getString('loggedUser');

    final streamResponse = await imageUploadRequest.send();
    final response = await http.Response.fromStream(streamResponse);

    return response;
  }

  Future<http.Response> _updateImage(File image) async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      checkURL = sharedPreferences.getString('url') + 'save_image';
    });
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');
    final imageUploadRequest =
        http.MultipartRequest('Post', Uri.parse(checkURL));
    final file = await http.MultipartFile.fromPath('profile_image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploadRequest.files.add(file);
    imageUploadRequest.fields['_username'] =
        sharedPreferences.getString('loggedUser');

    final streamResponse = await imageUploadRequest.send();
    final response = await http.Response.fromStream(streamResponse);

    return response;
  }

  process() async {
    var response;
    var connected = true;
    try {
      response = await _checkImage(galleryFile);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _selected = true;
      });
      connected = false;
      print(e);
    }
    if (connected) {
      if (response.statusCode == 201) {
        try {
          response = await _updateImage(galleryFile);
        } catch (e) {
          setState(() {
            _isLoading = false;
            _selected = true;
          });
          connected = false;
          print(e);
        }
        if (response.statusCode == 200) {
          widget.callback(true);
          _loadImg();
          setState(() {
            _selected = true;
            _isLoading = false;
            _textColor = Colors.black;
            _color = Colors.white;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _selected = true;
          _text = 'No face was found';
          _color = Colors.white;
          _textColor = Colors.black;
        });
      }
    }
  }

  @override
  didChangeDependencies() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      imgURL = sharedPreferences.getString("url") +
          "profile_image/" +
          sharedPreferences.getString("loggedUser") +
          "?v=" +
          now.millisecondsSinceEpoch.toString();
    });

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double screenHeight = size.height;
    // TODO: implement build
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Profile',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
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
                        image: (imgURL == null && galleryFile == null)
                            ? AssetImage('images/bg.jpg')
                            : (imgURL != null && galleryFile == null)
                                ? NetworkImage(imgURL)
                                : FileImage(galleryFile)),
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
                    color: Colors.white24,
                  )),
                ),
              ),
            ),
          ),
          AbsorbPointer(
            absorbing: _selected,
            child: Padding(
              padding: EdgeInsets.only(left: 70.0, right: 70.0, top: 40.0),
              child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  child: InkWell(
                      onTap: () {
                        process();
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : Text(_text,
                                  style: TextStyle(
                                      color: _textColor,
                                      fontFamily: 'Oxygen',
                                      fontSize: 25.0,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ))),
            ),
          ),
        ]),
      ),
    );
  }
}
