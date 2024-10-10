import 'package:attendance_departure/constant/constant.dart';
import 'package:attendance_departure/scraper_data/data_all.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarsDepature extends StatefulWidget {
  const CarsDepature({super.key});

  @override
  State<CarsDepature> createState() => _CarsDepatureState();
}

class _CarsDepatureState extends State<CarsDepature> {
  final constant = Constant();
  final dataAll = DataAll();
  bool isFetch = false;
  bool selectAll = false;
  //============================================
  List<Map<String, String>> data = [];
  List nameOfDrivers = [];
  List<TextEditingController> controllers1 = [];
  List<TextEditingController> controllers2 = [];
  List<bool> checkboxValues = [];
  //=================================================
  TextEditingController controllerAllHours = TextEditingController(text: '18');
  TextEditingController controllerAlMinutes = TextEditingController(text: '00');
  //====================================
  Future<List> getNameOfDrivers() async {
    try {
      List fetchedNames = await dataAll.getDepartureCar();
      setState(() {
        nameOfDrivers = fetchedNames;
        checkboxValues = List<bool>.filled(nameOfDrivers.length, false);
        controllers1 = List.generate(
            nameOfDrivers.length, (index) => TextEditingController(text: '00'));
        controllers2 = List.generate(
            nameOfDrivers.length, (index) => TextEditingController(text: '18'));
        isFetch = true;
      });
      return fetchedNames;
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      print('Error fetching data: $e');
      return [];
    }
  }

  //===========================================================
  void _toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      for (int i = 0; i < nameOfDrivers.length; i++) {
        if (nameOfDrivers[i]['time_out'] == "No Time Out" &&
            nameOfDrivers[i]['status'] == "Attended") {
          checkboxValues[i] = selectAll;
        } else {
          checkboxValues[i] = false;
        }
      }
      if (selectAll) {
        data = List.generate(
          nameOfDrivers.length,
          (index) => {
            "uuid": nameOfDrivers[index]['uuid']!,
            "time_out":
                "${controllers2[index].text}:${controllers1[index].text}:00",
          },
        );
      } else {
        data = [];
      }
    });
  }

  //============================================
  void _handleCheckboxChange(bool? value, int index) {
    setState(() {
      bool isTimeOutValid = nameOfDrivers[index]['time_out'] == "No Time Out";
      bool isStatusValid = nameOfDrivers[index]['status'] == "Attended";

      checkboxValues[index] =
          (isTimeOutValid && isStatusValid) ? (value ?? false) : false;

      Map<String, String> data2 = {
        "uuid": nameOfDrivers[index]['uuid']!,
        "time_out":
            "${controllers2[index].text}:${controllers1[index].text}:00",
      };

      if (checkboxValues[index]) {
        if (!data.any(
            (element) => element['uuid'] == nameOfDrivers[index]['uuid'])) {
          data.add(data2);
        }
      } else {
        data.removeWhere(
            (element) => element['uuid'] == nameOfDrivers[index]['uuid']);
      }
      selectAll = checkboxValues.every((val) => val);
    });
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
    getNameOfDrivers().then((_) {
      nameOfDrivers;
    });
  }

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
                            border: Border.all(
                                color: constant.buttonColor, width: 1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
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
                                          borderRadius:
                                              BorderRadius.circular(15),
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
                                      enabled: !selectAll,
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
                                          borderRadius:
                                              BorderRadius.circular(15),
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
                                          enabled: nameOfDrivers[index]
                                                          ['time_out'] !=
                                                      "No Time Out" ||
                                                  checkboxValues[index]
                                              ? false
                                              : true,
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
                                          enabled: nameOfDrivers[index]
                                                          ['time_out'] !=
                                                      "No Time Out" ||
                                                  checkboxValues[index]
                                              ? false
                                              : true,
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
                              ],
                            ),
                          );
                        },
                      ))
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  )),
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
                    await dataAll.departureCar(data);

                    setState(() {
                      data.clear();
                      checkboxValues =
                          List<bool>.filled(nameOfDrivers.length, false);
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
