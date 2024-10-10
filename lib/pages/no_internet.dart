import 'package:attendance_departure/constant/constant.dart';
import 'package:flutter/material.dart';

class NoInternet extends StatelessWidget {
  NoInternet({super.key});
  final constant = Constant();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: constant.bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.red,
              size: 80,
            ),
            Text(
              'CONNECT TO THE INTERNET',
              style: TextStyle(color: constant.whiteColor, fontSize: 27),
            )
          ],
        ),
      ),
    );
  }
}
