import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CustomDialog extends StatelessWidget {
  final String barcode;

  CustomDialog({this.barcode});

  

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0.0,
      backgroundColor: Colors.white70,
      child: Container(
            child: QrImage(
              data: barcode,
              version: QrVersions.auto,
              size: 300.0,
            ),
          ),
    );
  }
}
