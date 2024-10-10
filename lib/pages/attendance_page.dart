import 'package:attendance_departure/constant/constant.dart';
import 'package:attendance_departure/pages/cars.dart';
import 'package:attendance_departure/pages/cars_depature.dart';
import 'package:attendance_departure/pages/depature.dart';
import 'package:attendance_departure/pages/login.dart';
import 'package:attendance_departure/scraper_data/data_all.dart';
import 'package:attendance_departure/scraper_data/read_write_in_supabase.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  bool isFetch = false;
  bool selectAll = false;
  //==========================================
  List<Map<String, String>> names = [];
  List<bool> checkboxValues = [];
  List<TextEditingController> controllers1 = [];
  List<TextEditingController> controllers2 = [];
  List<Map<String, String>> data = [];
  //=========================================================================
  TextEditingController controllerAllHours = TextEditingController(text: '08');
  TextEditingController controllerAlMinutes = TextEditingController(text: '00');
  //==============================================================================
  String? token;
  String? nameManager;
  List<Map<String, dynamic>> dataNames = [];
  final supabase = Supabase.instance.client;
  DateTime currentDate = DateTime.now();
  //========================================================
  final constant = Constant();
  final dataAll = DataAll();
  ReadWriteInSupabase dealWithSupabase = ReadWriteInSupabase();
  //======================================================

  Future<void> write() async {
    String uuid = await supabase.auth.currentUser!.id;
    String today = currentDate.toString().split(' ')[0];
    int i = 0;
    for (var element in names) {
      if (data[i]['name'] == element['name']) {
        dataNames.add({
          'data': [today, element['name'], 'attended', data[i]['time_in'], '-']
        });
        i++;
      } else {
        dataNames.add({
          'data': [today, element['name'], 'absent', 'N/A', '-']
        });
      }
    }
    await dealWithSupabase.appendData(uuid, dataNames);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("تم تخزين البيانات ")));
    dataNames.clear();
  }

  Future<String> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString(constant.accessToken);
    setState(() {});
    return token!;
  }

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

  Future<void> _fetchNames() async {
    try {
      List<Map<String, String>> fetchedNames =
          await dataAll.fetchAllNames(context);
      setState(() {
        names = fetchedNames;
        checkboxValues = List<bool>.filled(names.length, false);
        controllers1 = List.generate(
            names.length, (index) => TextEditingController(text: '00'));
        controllers2 = List.generate(
            names.length, (index) => TextEditingController(text: '08'));
        if (fetchedNames.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Depature()),
          );
        }

        isFetch = true;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      names.clear();
      _fetchNames();
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      checkboxValues = List<bool>.filled(names.length, selectAll);

      if (selectAll) {
        data = List.generate(
          names.length,
          (index) => {
            "name": names[index]['name']!,
            "uuid": names[index]['uuid']!,
            "time_in":
                "${controllers2[index].text}:${controllers1[index].text}:00"
          },
        );
      } else {
        data = [];
      }
    });
  }

  void _handleCheckboxChange(bool? value, int index) {
    setState(() {
      checkboxValues[index] = value ?? false;

      // إعداد البيانات الجديدة
      Map<String, String> data2 = {
        "name": names[index]['name']!,
        "uuid": names[index]['uuid']!,
        "time_in": "${controllers2[index].text}:${controllers1[index].text}:00"
      };

      // إضافة أو إزالة البيانات من القائمة بناءً على حالة checkbox
      if (checkboxValues[index]) {
        if (!data.contains(data2)) {
          data.add(data2);
        }
      } else {
        data.removeWhere((element) => element['uuid'] == names[index]['uuid']);
      }

      selectAll = checkboxValues.every((val) => val);
    });
  }

  @override
  void initState() {
    super.initState();
    getToken().then((value) {
      _fetchNames();
      getManager().then((_) {
        nameManager;
      });
    });
  }

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
              //========================================================
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
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: constant.bgDarkColor,
                          border: Border.all(),
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
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 20),
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
                        itemCount: names.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: constant.bgDarkColor,
                                border: Border.all(color: constant.buttonColor),
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Checkbox(
                                    value: checkboxValues[index],
                                    onChanged: (value) {
                                      setState(() {
                                        _handleCheckboxChange(value, index);
                                      });
                                    },
                                  ),
                                  title: InkWell(
                                    onTap: () {
                                      _handleCheckboxChange(
                                          !checkboxValues[index], index);
                                    },
                                    child: Text(
                                      names[index]['name']!,
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
                                          enabled: !checkboxValues[index],
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
                                          enabled: !checkboxValues[index],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      'ايام الغياب المتبقية',
                                      style: TextStyle(
                                          color: constant.whiteColor,
                                          fontSize: 20),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 15),
                                      width: 50,
                                      height: 50,
                                      child: Text(
                                        '${names[index]['remaining']}',
                                        style: TextStyle(
                                            color: constant.whiteColor,
                                            fontSize: 20),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // ==================================
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: constant.bgDarkColor, // لون الشريط السفلي
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(
                        color: constant.sliderColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: MaterialButton(
                      textColor: data.isEmpty ? Colors.black12 : Colors.white,
                      onPressed: () async {
                        setState(() {
                          isFetch = false;
                        });
                        write();
                        await dataAll.attendance(data, 0, context);

                        setState(() {
                          names.clear();
                          data.clear();
                          _fetchNames();
                          isFetch = true;
                        });
                      },
                      child: const Text(
                        'حضور',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                        color: constant.sliderColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: MaterialButton(
                      textColor: data.isEmpty ? Colors.black12 : Colors.white,
                      onPressed: () async {
                        setState(() {
                          isFetch = false;
                        });

                        await dataAll.attendance(data, 1, context);
                        setState(() {
                          names.clear();
                          data.clear();
                          _fetchNames();
                          isFetch = true;
                        });
                      },
                      child: const Text(
                        'اجازه',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                        color: constant.sliderColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: MaterialButton(
                      textColor: data.isEmpty ? Colors.black12 : Colors.white,
                      onPressed: () async {
                        setState(() {
                          isFetch = false;
                        });
                        await dataAll.attendance(data, 2, context);
                        setState(() {
                          names.clear();
                          data.clear();
                          _fetchNames();
                          isFetch = true;
                        });
                      },
                      child: const Text(
                        'غياب',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
