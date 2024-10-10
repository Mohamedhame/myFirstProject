import 'package:attendance_departure/constant/constant.dart';
import 'package:attendance_departure/pages/cars.dart';
import 'package:attendance_departure/pages/cars_depature.dart';
import 'package:attendance_departure/pages/login.dart';
import 'package:attendance_departure/scraper_data/data_all.dart';
import 'package:attendance_departure/scraper_data/read_write_in_supabase.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Depature extends StatefulWidget {
  const Depature({super.key});

  @override
  State<Depature> createState() => _DepatureState();
}

class _DepatureState extends State<Depature> {
  final constant = Constant();
  final dataAll = DataAll();
  final supabase = Supabase.instance.client;
  String? nameManager;
  bool isFetch = false;
  bool selectAll = false;
  String? token;
  final dealWithSupabase = ReadWriteInSupabase();
  //=======================================
  List<Map<String, String>> namesAllEmployee = [];
  List<Map<String, String>> data = [];
  List<bool> checkboxValues = [];
  //============================================
  List<TextEditingController> controllers1 = [];
  List<TextEditingController> controllers2 = [];
  final controllerAllHours = TextEditingController(text: '18');
  final controllerAlMinutes = TextEditingController(text: '00');
  //=======================================
  Future<String> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString(constant.accessToken);
    setState(() {});
    return token!;
  }

  //=======================================
  Future<void> _fetchNames() async {
    try {
      List<Map<String, String>> fetchedNames =
          await dataAll.fetchesNamesToDeparture();
      setState(() {
        namesAllEmployee = fetchedNames;
        checkboxValues = List<bool>.filled(namesAllEmployee.length, false);
        controllers1 = List.generate(namesAllEmployee.length,
            (index) => TextEditingController(text: '00'));
        controllers2 = List.generate(namesAllEmployee.length,
            (index) => TextEditingController(text: '18'));
        isFetch = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      print('Error fetching data: $e');
    }
  }

  //======================================
  void _toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      for (int i = 0; i < namesAllEmployee.length; i++) {
        if (namesAllEmployee[i]['time_out'] == "No Time Out" &&
            namesAllEmployee[i]['status'] == "Attended") {
          checkboxValues[i] = selectAll;
        } else {
          checkboxValues[i] = false;
        }
      }
      data = checkboxValues
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) {
        int index = entry.key;
        return {
          "name": namesAllEmployee[index]['name']!,
          "uuid": namesAllEmployee[index]['uuid']!,
          "time_out":
              "${controllers2[index].text}:${controllers1[index].text}:00"
        };
      }).toList();
    });
  }

  //=======================================
  void _handleCheckboxChange(bool? value, int index) {
    setState(() {
      bool isTimeOutValid =
          namesAllEmployee[index]['time_out'] == "No Time Out";
      bool isStatusValid = namesAllEmployee[index]['status'] == "Attended";

      checkboxValues[index] =
          (isTimeOutValid && isStatusValid) ? (value ?? false) : false;

      Map<String, String> data2 = {
        "name": namesAllEmployee[index]['name']!,
        "uuid": namesAllEmployee[index]['uuid']!,
        "time_out": "${controllers2[index].text}:${controllers1[index].text}:00"
      };

      if (checkboxValues[index]) {
        if (!data.any(
            (element) => element['uuid'] == namesAllEmployee[index]['uuid'])) {
          data.add(data2);
        }
      } else {
        data.removeWhere(
            (element) => element['uuid'] == namesAllEmployee[index]['uuid']);
      }

      selectAll = checkboxValues.every((val) => val);
    });
  }

  //=======================================
  Future<String> getManager() async {
    if (token == null) {
      return "Token is missing";
    }

    String name = await dataAll.getNameOfManager(token!);

    if (nameManager != name) {
      setState(() {
        nameManager = name;
      });
    }

    return name;
  }

  //=======================================

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        namesAllEmployee.clear();
      });
      await _fetchNames();

      if (mounted) {
        setState(() {});
      }
    }
  }

  //=======================================
  Future<void> updateData() async {
    String uuid = supabase.auth.currentUser!.id;
    List dataNames = [];
    for (var element in data) {
      dataNames.add({"name": element['name'], "date": element['time_out']});
    }
    for (var element in dataNames) {
      print(element);
    }
    await dealWithSupabase.update(uuid, dataNames);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("تم تحديث البيانات ")));
  }

  //=======================================
  @override
  void initState() {
    super.initState();
    getToken().then((_) {
      _fetchNames();
      getManager().then((_) {
        nameManager;
      });
    });
  }

  //=======================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: constant.bgColor,
      appBar: AppBar(
        backgroundColor: constant.bgDarkColor,
        foregroundColor: constant.whiteColor,
        title: Text(
          '$nameManager',
          style: GoogleFonts.amiri(fontSize: 30),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(25),
              bottomLeft: Radius.circular(25)),
        ),
        leading: PopupMenuButton(
            onSelected: (value) async {
              if (value == 'get') {
                String uuid = supabase.auth.currentUser!.id;
                dealWithSupabase.openExcel(uuid);
              }
              //===========================================
              if (value == "logOut") {
                bool logOut = await dataAll.logOut();
                if (logOut) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                }
              }
              //==================================================
              if (value == 'car') {
                List getNamesOfDrivers = await dataAll.getNamesOfDrivers();
                if (getNamesOfDrivers.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Cars()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CarsDepature()),
                  );
                }
              }
              //===========================================================
            },
            itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "get",
                    child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                            color: constant.buttonColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'جلب البيانات',
                              style: GoogleFonts.amiri(fontSize: 22),
                            ),
                            const Icon(Icons.folder)
                          ],
                        )),
                  ),
                  PopupMenuItem(
                    value: "car",
                    child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                            color: constant.buttonColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تحضير السيارات',
                              style: GoogleFonts.amiri(fontSize: 22),
                            ),
                            const Icon(Icons.car_crash_rounded)
                          ],
                        )),
                  ),
                  PopupMenuItem(
                    value: "logOut",
                    child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                            color: constant.buttonColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تسجيل خروج',
                              style: GoogleFonts.amiri(fontSize: 22),
                            ),
                            const Icon(Icons.logout)
                          ],
                        )),
                  ),
                ]),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: isFetch
              ? Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: constant.bgDarkColor,
                          border:
                              Border.all(color: constant.buttonColor, width: 1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Checkbox(
                                  value: selectAll,
                                  onChanged: _toggleSelectAll,
                                ),
                              ),
                              Text(
                                'تحديد الكل',
                                style: GoogleFonts.amiri(
                                    color: constant.whiteColor, fontSize: 25),
                              )
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 50,
                                  height: 60,
                                  child: TextField(
                                    enabled: !selectAll,
                                    keyboardType: TextInputType.number,
                                    controller: controllerAlMinutes,
                                    onChanged: (value) {
                                      for (var i = 0;
                                          i < controllers1.length;
                                          i++) {
                                        controllers1[i].text =
                                            controllerAlMinutes.text;
                                      }
                                    },
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        height: 1,
                                        color: constant.whiteColor),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 50,
                                  height: 60,
                                  child: TextField(
                                    enabled: !selectAll,
                                    keyboardType: TextInputType.number,
                                    controller: controllerAllHours,
                                    onChanged: (value) {
                                      for (var i = 0;
                                          i < controllers2.length;
                                          i++) {
                                        controllers2[i].text =
                                            controllerAllHours.text;
                                      }
                                    },
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        height: 1,
                                        color: constant.whiteColor),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: namesAllEmployee.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: constant.bgDarkColor,
                                border: Border.all(
                                    color: constant.buttonColor, width: 1),
                                borderRadius: BorderRadius.circular(20)),
                            child: ListTile(
                              leading: Checkbox(
                                value: checkboxValues[index],
                                onChanged: (value) {
                                  _handleCheckboxChange(value, index);
                                },
                              ),
                              title: InkWell(
                                onTap: () {
                                  _handleCheckboxChange(
                                      !checkboxValues[index], index);
                                },
                                child: Text(
                                  namesAllEmployee[index]['name']!,
                                  style: GoogleFonts.elMessiri(
                                      fontSize: 18.0,
                                      color: constant.whiteColor),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    child: TextField(
                                      controller: controllers1[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          height: 1,
                                          color: constant.whiteColor),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                                      enabled: namesAllEmployee[index]
                                                      ['time_out'] !=
                                                  "No Time Out" ||
                                              checkboxValues[index]
                                          ? false
                                          : true,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 50,
                                    height: 50,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: controllers2[index],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 20.0,
                                          height: 1,
                                          color: constant.whiteColor),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                                      enabled: namesAllEmployee[index]
                                                      ['time_out'] !=
                                                  "No Time Out" ||
                                              checkboxValues[index]
                                          ? false
                                          : true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: constant.bgDarkColor,
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: constant.sliderColor,
                    borderRadius: BorderRadius.circular(20)),
                child: MaterialButton(
                  minWidth: 300,
                  textColor: data.isEmpty ? Colors.black12 : Colors.white,
                  onPressed: () async {
                    setState(() {
                      isFetch = false;
                    });
                    updateData();
                    await dataAll.departure(data);

                    setState(() {
                      data.clear();
                      checkboxValues =
                          List<bool>.filled(namesAllEmployee.length, false);
                      isFetch = true;
                    });
                  },
                  child: const Text(
                    'انصراف',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 25,
                    ),
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
