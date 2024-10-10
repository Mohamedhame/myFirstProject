import 'dart:async';

import 'package:attendance_departure/constant/constant.dart';
import 'package:attendance_departure/network_state/network_controller.dart';
import 'package:attendance_departure/pages/attendance_page.dart';
import 'package:attendance_departure/pages/depature.dart';
import 'package:attendance_departure/scraper_data/data_all.dart';
import 'package:attendance_departure/scraper_data/read_write_in_supabase.dart';
import 'package:attendance_departure/scraper_data/read_write_json.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  List sug = [];
  List data = [];
  final constant = Constant();
  final dealWithSupabase = ReadWriteInSupabase();
  final supabase = Supabase.instance.client;
  final dataAll = DataAll();
  bool isShow = true;
  bool isConnected = false;
  bool isDelete = true;
  late StreamSubscription _connectionSubscription;
//====== Check internet status ===============

  Future<void> checkConnection() async {
    isConnected = await NetworkController.isConnection();
    setState(() {});
  }

  //==========================
  void saveData() async {
    Map<String, dynamic> data = {
      'username': _username.text,
      'password': _password.text,
    };
    ReadWriteJson().writeInJson(data);
  }

  //========================
  void returnData() async {
    List dataName = await ReadWriteJson().readFromJson();
    data = dataName;
  }

  //=========================================
  Future<bool> login() async {
    bool isHasData;
    String data = await dataAll.start(_username.text, _password.text, context);
    if (data.isEmpty) {
      isHasData = false;
    } else {
      isHasData = true;
    }
    return isHasData;
  }

  //========================
  @override
  void initState() {
    super.initState();
    returnData();
    checkConnection();
    _connectionSubscription =
        NetworkController.connectionStream.listen((status) {
      setState(() {
        isConnected = status;
      });
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  //========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: constant.bgColor,
      appBar: AppBar(
        backgroundColor: constant.bgDarkColor,
        centerTitle: true,
        title: Text(
          'تسجيل الدخول',
          style: GoogleFonts.amiri(color: constant.whiteColor, fontSize: 30),
        ),
      ),
      body: Center(
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TypeAheadField(
                  controller: _username,
                  builder: (context, controller, focusNode) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      style:
                          TextStyle(color: constant.whiteColor, fontSize: 22),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () {
                            _username.clear();
                            _password.clear();
                          },
                          icon: const Icon(Icons.close),
                        ),
                        labelStyle: GoogleFonts.amiri(
                            color: constant.whiteColor, fontSize: 25),
                        labelText: 'اسم المستخدم',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion),
                      trailing: IconButton(
                        onPressed: () async {
                          await ReadWriteJson().deleteUserFromJson(suggestion);
                          setState(() {
                            sug.remove(suggestion);
                            sug.clear();
                          });
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    );
                  },
                  onSelected: (value) {
                    setState(() {
                      _username.text = value;
                      for (var element in data) {
                        if (element['username'] == value) {
                          _password.text = element['password'];
                        }
                      }
                    });
                  },
                  suggestionsCallback: (String search) async {
                    if (search.isEmpty) return [];
                    sug = data
                        .where((element) => element['username']
                            .toLowerCase()
                            .contains(search.toLowerCase()))
                        .map((element) => element['username'])
                        .toList();
                    setState(() {
                      data;
                      sug;
                    });
                    return sug;
                  },
                ),
              ),
              //========================Password Field================================
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _password,
                  style: TextStyle(color: constant.whiteColor, fontSize: 22),
                  textAlign: TextAlign.center,
                  obscureText: isShow,
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isShow = !isShow;
                            });
                          },
                          icon: const Icon(Icons.remove_red_eye)),
                      labelStyle: GoogleFonts.amiri(
                          color: constant.whiteColor, fontSize: 25),
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20))),
                ),
              ),
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                    color: constant.buttonColor,
                    borderRadius: BorderRadius.circular(15)),
                child: MaterialButton(
                  textColor: isConnected ? constant.whiteColor : Colors.black12,
                  onPressed: isConnected
                      ? () async {
                          bool isHasData = await login();
                          if (isHasData) {
                            saveData();
                            //================================

                            String isReturn =
                                await dealWithSupabase.signUpOrSignIn(
                                    _username.text, _password.text, context);
                            if (isReturn == constant.noExist) {
                              final id = supabase.auth.currentUser!.id;
                              dealWithSupabase.createRow(id, _username.text);
                            }
                            //==========================================
                            List namesAll =
                                await dataAll.fetchAllNames(context);
                            if (namesAll.isEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Depature()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Attendance()),
                              );
                            }
                          } else {
                            print('error');
                          }
                        }
                      : null,
                  child: Text(
                    'تسجيل',
                    style: GoogleFonts.amiri(fontSize: 25),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
