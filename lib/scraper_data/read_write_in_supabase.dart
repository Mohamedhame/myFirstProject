import 'dart:io';

import 'package:attendance_departure/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class ReadWriteInSupabase {
  String loginUrl = "https://seahorse-app-dy9b3.ondigitalocean.app/acc/login/";
  final supabase = Supabase.instance.client;
  final constant = Constant();
  //=========================================
  Future<String> signUpOrSignIn(
      String email, String paawod, BuildContext context) async {
    try {
      final response = await supabase.auth
          .signUp(email: email.trim(), password: paawod.trim());
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('User signed up successfully: ${response.user?.email}')));
      }
      return constant.noExist;
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        try {
          await supabase.auth
              .signInWithPassword(email: email.trim(), password: paawod.trim());
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم تسجيل الدخول بنجاح ")));
          return constant.exist;
        } catch (e) {
          print(e);
          return constant.error;
        }
      } else {
        print(e.message);
        return constant.error;
      }
    } catch (e) {
      return constant.error;
    }
  }

  //============================================
  void createRow(String id, String username) async {
    DateTime now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    // تحقق إذا كانت القيمة موجودة بالفعل
    final response =
        await supabase.from('projects').select().eq('id', id).maybeSingle();
    if (response == null) {
      // إذا لم تكن القيمة موجودة، قم بإدخال الصف الجديد
      await supabase.from('projects').insert({
        'id': id,
        'created_at': formattedDate,
        'name': username,
        "data": "{}"
      });
    } else {
      print('A project with the same ID already exists.');
    }
  }

  //=======================================================
  Future<List> readData(String uuid) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> data =
        supabase.from('projects').select('data').eq('id', uuid);
    return data;
  }

//================================================================
  Future<List> fillAsList(String uuid) async {
    List collections = [];
    try {
      List data = await readData(uuid);
      for (var element in data[0]['data']) {
        collections.add(element);
      }
      return collections;
    } catch (e) {
      print(e);
      return [];
    }
  }

//=============================================================
  Future<void> appendData(String uuid, List dataNames) async {
    List collections = await fillAsList(uuid);
    // List test_1 = [];

    for (var element in dataNames) {
      collections.add(element);
    }

    collections.removeWhere((element) {
      try {
        // نفترض أن التنسيق هو "YYYY-MM-DD"
        List<String> parts = element['data'][0].split('-');

        // تحليل الأجزاء
        int year = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int day = int.parse(parts[2]);

        DateTime parsedDate = DateTime(year, month, day);
        DateTime currentDate = DateTime.now();

        // التحقق إذا كان التاريخ قبل 61 يوماً من التاريخ الحالي
        return parsedDate
            .isBefore(currentDate.subtract(const Duration(days: 61)));
      } catch (e) {
        print('Error parsing date: ${element['data'][0]}');
        return false;
      }
    });
    // for (var element in dataNames) {
    //   print(element);
    // }
    await supabase
        .from('projects')
        .update({'data': collections}).eq('id', uuid);
    print('done');
  }

  //===============================================================
  Future<String> writeInExcel(String uuid) async {
    List collections = await fillAsList(uuid);

    final directory = await getApplicationDocumentsDirectory();
    final path = Platform.isWindows
        ? '${directory.path}\\output.xlsx'
        : '${directory.path}/output.xlsx';

    final File file = File(path);

    if (await file.exists()) {
      await file.delete();
      print('Old file deleted.');
    }

    int row = 3;

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.isRightToLeft = true;

    final cellName = sheet.getRangeByName('A1');
    cellName.setText('الاسماء');
    cellName.cellStyle.hAlign = HAlignType.center;

    final cellDate = sheet.getRangeByName('A2');
    cellDate.setText('التاريخ');
    cellDate.cellStyle.hAlign = HAlignType.center;

    List attended = ["انصراف", "حضور"];
    List employeeName = [];
    for (var i = 0; i < collections.length; i++) {
      if (!employeeName.contains(collections[i]['data'][1])) {
        employeeName.add(collections[i]['data'][1]);
      }
    }

    for (int i = 0; i < employeeName.length; i++) {
      final range = sheet.getRangeByIndex(1, i * 2 + 2, 1, i * 2 + 3);
      range.merge();
      range.setText(employeeName[i]);
      range.cellStyle.hAlign = HAlignType.center;
      range.cellStyle.vAlign = VAlignType.center;
      range.cellStyle.wrapText = true;

      for (var a = 0; a < attended.length; a++) {
        final cell = sheet.getRangeByIndex(2, i * 2 + a + 2);
        cell.setText(attended[a]);
        cell.cellStyle.hAlign = HAlignType.center;
        cell.cellStyle.vAlign = VAlignType.center;
        cell.cellStyle.wrapText = true;
      }
    }
    List date = [];
    for (var i = 0; i < collections.length; i++) {
      if (!date.contains(collections[i]['data'][0])) {
        date.add(collections[i]['data'][0]);
      }
    }
    for (var i = 0; i < date.length; i++) {
      final cellDays = sheet.getRangeByIndex(i + 3, 1);
      cellDays.setText(date[i].toString());
      cellDays.cellStyle.hAlign = HAlignType.center;
      cellDays.cellStyle.vAlign = VAlignType.center;
      cellDays.columnWidth = 20;
    }

    for (var i = 0; i < collections.length; i++) {
      String currentDate = collections[i]['data'][0];
      String currentEmployee = collections[i]['data'][1];

      if (date.contains(currentDate) &&
          employeeName.contains(currentEmployee)) {
        int rowIndex = date.indexOf(currentDate) + row;
        int colIndex = (employeeName.indexOf(currentEmployee) * 2) + 3;

        final cellAttend = sheet.getRangeByIndex(rowIndex, colIndex);
        final cellDeptur = sheet.getRangeByIndex(rowIndex, colIndex - 1);

        String attendanceTime = collections[i]['data'][3];
        cellAttend.setText(attendanceTime);
        cellAttend.cellStyle.hAlign = HAlignType.center;
        cellAttend.cellStyle.vAlign = VAlignType.center;
        cellAttend.columnWidth = 15;
        cellDeptur.setText(collections[i]['data'][4]);
        cellDeptur.cellStyle.hAlign = HAlignType.center;
        cellDeptur.cellStyle.vAlign = VAlignType.center;
        cellDeptur.columnWidth = 15;

        print(
            'Value "$attendanceTime" added to cell at row $rowIndex, column $colIndex');
      } else {
        print("Date or Employee not found for ${collections[i]['data']}");
      }
    }

    // حفظ الملف
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    await file.writeAsBytes(bytes, flush: true);

    print('File saved at $path');
    return path;
  }

  //==========================================================================
  Future<void> openExcel(String uuid) async {
    String fileName = await writeInExcel(uuid);
    OpenFile.open(fileName);
  }

  //======================================================
  Future<void> update(String uuid, List dataNames) async {
    List collection = await fillAsList(uuid);
    DateTime currentDate = DateTime.now();
    String today = currentDate.toString().split(' ')[0];

    for (var i = 0; i < collection.length; i++) {
      if (collection[i]['data'][0] == today) {
        bool foundMatch = false;
        for (var dataName in dataNames) {
          if (collection[i]['data'][1] == dataName['name']) {
            collection[i]['data'][4] = dataName['date'];
            foundMatch = true;
            break;
          }
        }
        if (!foundMatch) {
          collection[i]['data'][4] = '---';
        }
      }
    }

    await supabase.from('projects').update({'data': collection}).eq('id', uuid);
    print('finish');
  }

//===========================================================
  Future<List> readCounter(String uuid) async {
    final data = supabase.from('projects').select('cars').eq('id', uuid);
    return data;
  }

  //====================================================================

//==================================================
  Future<void> appendToCars(String uuid, List collections) async {
    for (var element in collections) {
      print(element);
    }
    await supabase
        .from('projects')
        .update({'cars': collections}).eq('id', uuid);
    print('done');
  }
}
