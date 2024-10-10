import 'package:attendance_departure/constant/constant.dart';
import 'package:attendance_departure/scraper_data/data_all.dart';
import 'package:attendance_departure/scraper_data/read_write_in_supabase.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Cars extends StatefulWidget {
  const Cars({super.key});

  @override
  State<Cars> createState() => _CarsState();
}

class _CarsState extends State<Cars> {
  bool isFetch = false;
  bool selectAll = false;
  //==============================
  final constant = Constant();
  final dataAll = DataAll();
  final supabase = Supabase.instance.client;
  ReadWriteInSupabase dealWithSupabase = ReadWriteInSupabase();
//========================================
  List status = [];
  List nameOfDrivers = [];
  //=========================================================================
  TextEditingController controllerAllHours = TextEditingController(text: '08');
  TextEditingController controllerAlMinutes = TextEditingController(text: '00');
  //==============================================================================
  List<bool> checkboxValues = [];
  List<Map<String, String>> data = [];
  List<TextEditingController> controllers1 = [];
  List<TextEditingController> controllers2 = [];
  List<TextEditingController> counterController = [];
  List<Map<String, String>> listOfCounter = [];
  //===============================================================================
  Future<List> getStatus() async {
    status = await dataAll.statusCars();
    return status;
  }

  //========================================
  Future<List> getNameOfDrivers() async {
    nameOfDrivers = await dataAll.getNamesOfDrivers();
    setState(() {
      nameOfDrivers;
      checkboxValues = List<bool>.filled(nameOfDrivers.length, false);
      controllers1 = List.generate(
          nameOfDrivers.length, (index) => TextEditingController(text: '00'));
      controllers2 = List.generate(
          nameOfDrivers.length, (index) => TextEditingController(text: '08'));

      counterController = List.generate(
          nameOfDrivers.length, (index) => TextEditingController(text: '0'));

      isFetch = true;
    });
    return nameOfDrivers;
  }

  //====================================================
  void _toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      checkboxValues = List<bool>.filled(nameOfDrivers.length, selectAll);
      if (selectAll) {
        data = List.generate(
          nameOfDrivers.length,
          (index) => {
            "uuid": nameOfDrivers[index]['uuid']!,
            "time_in":
                "${controllers2[index].text}:${controllers1[index].text}:00",
            "counter": counterController[index].text
          },
        );
      } else {
        data = [];
      }
    });
  }

//======================================================
  void _handleCheckboxChange(bool? value, int index) {
    setState(() {
      checkboxValues[index] = value ?? false;

      Map<String, String> data2 = {
        "uuid": nameOfDrivers[index]['uuid']!,
        "time_in": "${controllers2[index].text}:${controllers1[index].text}:00",
        "counter": counterController[index].text
      };

      if (checkboxValues[index]) {
        if (!data.contains(data2)) {
          data.add(data2);
        }
      } else {
        data.removeWhere(
            (element) => element['uuid'] == nameOfDrivers[index]['uuid']);
      }

      selectAll = checkboxValues.every((val) => val);
    });
  }

  //=====================================
  Future<void> saveCounter() async {
    String uuid = await supabase.auth.currentUser!.id;
    for (var i = 0; i < nameOfDrivers.length; i++) {
      listOfCounter.add({
        "name": nameOfDrivers[i]['name'],
        "count": counterController[i].text
      });
    }
    await dealWithSupabase.appendToCars(uuid, listOfCounter);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("تم تخزين البيانات ")));
    listOfCounter.clear();
  }

  //====================================
  Future<void> getCounters() async {
    String uuid = await supabase.auth.currentUser!.id;
    try {
      List dataCounter = await dealWithSupabase.readCounter(uuid);
      if (dataCounter.isNotEmpty) {
        int i = 0;
        for (var element in dataCounter[0]['cars']) {
          if (element['name'] == nameOfDrivers[i]['name']) {
            counterController[i].text = element['count'];
            i++;
          }
        }
      } else {
        for (var element in counterController) {
          element.text = '0';
        }
      }
    } catch (e) {
      for (var element in counterController) {
        element.text = '0';
      }
    }
  }

  //====================================
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      nameOfDrivers.clear();
      getNameOfDrivers().then((_) {
        nameOfDrivers;
      });
    });
  }

  //====================================
  @override
  void initState() {
    super.initState();
    getStatus();
    getNameOfDrivers().then((_) {
      nameOfDrivers;
      getCounters();
    });
  }

  //===================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: constant.bgColor,
      appBar: AppBar(
        backgroundColor: constant.bgDarkColor,
        foregroundColor: constant.whiteColor,
        centerTitle: true,
        title: Text(
          'السيارات',
          style: GoogleFonts.amiri(fontSize: 25),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(25),
              bottomLeft: Radius.circular(25)),
        ),
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
                      itemCount: nameOfDrivers.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: constant.bgDarkColor,
                              border: Border.all(
                                  color: constant.buttonColor, width: 1),
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
                                    nameOfDrivers[index]['name'],
                                    style: GoogleFonts.elMessiri(
                                        color: constant.whiteColor,
                                        fontSize: 18),
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
                                        enabled: !checkboxValues[index],
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
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 50,
                                      height: 50,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        controller: controllers2[index],
                                        enabled: !checkboxValues[index],
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      child: Text(
                                        'قراءة العداد',
                                        style: GoogleFonts.amiri(
                                            color: constant.whiteColor,
                                            fontSize: 20),
                                      ),
                                    ),
                                    Container(
                                        width: 120,
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          controller: counterController[index],
                                          enabled: !checkboxValues[index],
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
                                        ))
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: constant.sliderColor,
                    borderRadius: BorderRadius.circular(20)),
                child: MaterialButton(
                  minWidth: 150,
                  textColor: data.isNotEmpty ? Colors.white : Colors.black12,
                  onPressed: data.isNotEmpty
                      ? () async {
                          saveCounter();
                          dataAll.attendanceCar(
                              data, "${status[0]['uuid']}", context);
                        }
                      : null,
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
                decoration: BoxDecoration(
                    color: constant.sliderColor,
                    borderRadius: BorderRadius.circular(20)),
                child: MaterialButton(
                  minWidth: 150,
                  textColor: data.isNotEmpty ? Colors.white : Colors.black12,
                  onPressed: data.isNotEmpty
                      ? () async {
                          dataAll.absentCar(
                              data, "${status[1]['uuid']}", context);
                        }
                      : null,
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
        ),
      ),
    );
  }
}
