import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showImage = false;
  final theImage = Image.network(
      "https://67561a95.ngrok.io/profile_image/test1234",
      fit: BoxFit.cover);

  /// Did Change Dependencies
  @override
  void didChangeDependencies() {
    precacheImage(theImage.image, context);
    super.didChangeDependencies();
  }

  /// Widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: showImage
            ? Container(
                height: double.infinity,
                color: Colors.black.withOpacity(0.8),
                child: theImage,
              )
            : Container(
                child: Center(
                  child: RaisedButton(
                    color: Color(0XFF5DAD2D),
                    onPressed: () {
                      setState(() {
                        showImage = true;
                      });
                    },
                    child: Text(
                      "SHOW IMAGE",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ));
  }
}
