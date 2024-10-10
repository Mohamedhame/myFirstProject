import 'dart:async';
import 'package:attendance_departure/constant/constant.dart';
import 'package:attendance_departure/network_state/network_controller.dart';
import 'package:attendance_departure/pages/attendance_page.dart';
import 'package:attendance_departure/pages/depature.dart';
import 'package:attendance_departure/pages/login.dart';
import 'package:attendance_departure/pages/no_internet.dart';
import 'package:attendance_departure/scraper_data/data_all.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthContainerState extends StatefulWidget {
  const AuthContainerState({super.key});

  @override
  State<AuthContainerState> createState() => _AuthContainerStateState();
}

class _AuthContainerStateState extends State<AuthContainerState> {
  bool isConnected = false;
  String? token;
  final constant = Constant();
  late StreamSubscription _connectionSubscription;
  final dataAll = DataAll();
  List<Map<String, String>>? namesAll;

  //====== Check internet status continuously ===============
  Future<void> checkConnection() async {
    isConnected = await NetworkController.isConnection();
    setState(() {});
  }

//=================================================================
  Future<void> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString(constant.accessToken);
    setState(() {});
  }

//==========================================================
  void getNames() async {
    if (token != null) {
      namesAll = await dataAll.fetchAllNames(context);
      setState(() {});
    }
  }

  //========================================================
  @override
  void initState() {
    super.initState();
    // Initial check for connection
    checkConnection();

    _connectionSubscription =
        NetworkController.connectionStream.listen((status) {
      setState(() {
        isConnected = status;
        getToken().then((_) {
          getNames();
        });
      });
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isConnected) {
      if (token == null) {
        return const Login();
      } else {
        if (namesAll == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // التحقق من إذا كانت القائمة فارغة
        if (namesAll!.isEmpty) {
          return Depature();
        } else {
          return Attendance();
        }
      }
    } else {
      return NoInternet();
    }
  }
}
