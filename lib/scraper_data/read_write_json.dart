import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ReadWriteJson {
  //===========================
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final path = Platform.isWindows
        ? '${directory.path}\\suggestion.json'
        : '${directory.path}/suggestion.json';
    return path;
  }

//=============================================================
  Future<String> writeInJson(Map<String, dynamic> jsonData) async {
    final path = await _localPath;
    List<dynamic> existingData = [];

    final File file = File(path);
    if (await file.exists()) {
      String existingContent = await file.readAsString();
      if (existingContent.isNotEmpty) {
        try {
          existingData = jsonDecode(existingContent);
        } catch (e) {
          print('Error decoding JSON: $e');
          existingData = [];
        }
      }
    }

    bool userExists = false;
    for (var item in existingData) {
      if (item['username'] == jsonData['username']) {
        item['password'] = jsonData['password'];
        userExists = true;
        break;
      }
    }

    if (!userExists) {
      existingData.add(jsonData);
    }

    String jsonString = jsonEncode(existingData);
    await file.writeAsString(jsonString);
    return path;
  }

  //====================================
  Future<List> readFromJson() async {
    final path = await _localPath;
    final File file = File(path);
    if (!(await file.exists())) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode([]));
    }
    String fileContents = await file.readAsString();
    List<dynamic> jsonData = jsonDecode(fileContents);
    return jsonData;
  }

  //===================
  Future<void> deleteUserFromJson(String username) async {
    final path = await _localPath;
    final File file = File(path);
    if (await file.exists()) {
      String fileContents = await file.readAsString();
      List<dynamic> existingData = jsonDecode(fileContents);

      existingData.removeWhere((item) => item['username'] == username);

      String updatedJsonString = jsonEncode(existingData);
      await file.writeAsString(updatedJsonString);

      print("تم حذف المستخدم بنجاح!");
    } else {
      print("الملف غير موجود.");
    }
  }
}
