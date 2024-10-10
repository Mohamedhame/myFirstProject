import 'package:flutter/material.dart';

class Constant {
  final bgColor = const Color(0xff1F212c);
  final whiteColor = const Color(0xffFFFFFF);
  final sliderColor = const Color(0xff7E70FF);
  final buttonColor = const Color(0xff60E95D);
  final bgDarkColor = const Color(0xff070B11);
  final accessToken = 'access_token';
  final refresh = 'refresh';
  final uuidManager = 'manager';
  String exist = "exist";
  String noExist = "no exist";
  String error = "no exist";

  Future<void> errorData(BuildContext context, String name) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
            name,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 22),
          ),
          actions: [
            TextButton(
              child: const Text("تمام"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
