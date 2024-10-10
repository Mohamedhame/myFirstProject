import 'dart:convert';
import 'dart:io';

import 'package:attendance_departure/constant/constant.dart';
import 'package:attendance_departure/pages/auth_container_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class DataAll {
  String loginUrl = "https://seahorse-app-dy9b3.ondigitalocean.app/acc/login/";
  final constant = Constant();
  String? accessToken;
  String? uuidManager;
  final supabase = Supabase.instance.client;
  //=================================================================
  Future<void> saveAccessAndRefresh(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(key)) {
      await prefs.remove(key);
    }
    await prefs.setString(key, value);
  }

  //================================================================
  Future<String> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(constant.accessToken);
    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception('Access token not found');
    }
    return accessToken!;
  }

  //====================================================================
  Future<String> getUuidManager() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    uuidManager = prefs.getString(constant.uuidManager);
    if (uuidManager == null || uuidManager!.isEmpty) {
      throw Exception('Access token not found');
    }
    return uuidManager!;
  }

  //=======================================================================
  Future<String> start(
      String email, String password, BuildContext context) async {
    Map<String, String> payload = {"email": email, "password": password};
    try {
      http.Response response =
          await http.post(Uri.parse(loginUrl), body: payload);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String refresh = data['refresh'];
        saveAccessAndRefresh(constant.refresh, refresh);
        String accessToken = data['access'] ?? "";
        saveAccessAndRefresh(constant.accessToken, accessToken);
        return accessToken;
      } else {
        constant.errorData(context, "الايميل او كلمة المرور خطأ.");
        return "";
      }
    } on SocketException catch (e) {
      print(e.message);
      constant.errorData(context, "تحقق من الاتصال بالشبكة.");
      return "";
    } catch (e) {
      print('Unexpected error: $e');
      return "";
    }
  }

  //===========================================================================
  Future<String> getNameOfManager(String accessToken) async {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) throw Exception('Invalid token structure');

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final empUuid = payload['emp_name_ar'];
      return empUuid;
    } catch (e) {
      print(e.toString());
      return "";
    }
  }

//==============================================================================
  Future<List<Map<String, String>>> fetchAllNames(BuildContext context) async {
    await getToken();

    if (accessToken!.isNotEmpty) {
      final headers = {
        'accept': 'application/json, text/plain, */*',
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      };
      try {
        final parts = accessToken!.split('.');
        if (parts.length != 3) throw Exception('Invalid token structure');

        final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        final empUuid = payload['emp_uuid'];
        const baseUrl =
            "https://seahorse-app-dy9b3.ondigitalocean.app/att/att_by_emp_uuid";
        final userUrl = "$baseUrl/$empUuid";

        http.Response dataAll =
            await http.get(Uri.parse(userUrl), headers: headers);

        var projectUuid =
            jsonDecode(utf8.decode(dataAll.bodyBytes))['project']['uuid'];

        final url = Uri.parse(
            "https://seahorse-app-dy9b3.ondigitalocean.app/emp/get_emp_execluded_by_project/$projectUuid");
        final res = await http.get(url, headers: headers);

        var protectedData = jsonDecode(utf8.decode(res.bodyBytes));
        var data = protectedData['data'];

        List<Map<String, String>> names = [];
        for (var element in data) {
          names.add({
            "name": element['name_ar'],
            "uuid": element['uuid'],
            "remaining": '${element['monthly_remaining_vacations']}'
          });
        }
        return names;
      } catch (e) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthContainerState()),
        );
        return [];
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthContainerState()),
      );
      return [];
    }
  }

//==============================================================================
  Future<List<Map<String, String>>> fetchesNamesToDeparture() async {
    await getToken();
    if (accessToken!.isNotEmpty) {
      Map<String, String> headers = {"Authorization": "Bearer $accessToken"};
      try {
        final parts = accessToken!.split('.');
        if (parts.length != 3) throw Exception('Invalid token structure');

        final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

        final empUuid = payload['emp_uuid'];
        saveAccessAndRefresh(constant.uuidManager, empUuid);

        const baseUrl =
            "https://seahorse-app-dy9b3.ondigitalocean.app/att/att_by_emp_uuid";

        final userUrl = "$baseUrl/$empUuid";

        http.Response protectedResponse =
            await http.get(Uri.parse(userUrl), headers: headers);
        if (protectedResponse.statusCode == 200) {
          var protectedData =
              jsonDecode(utf8.decode(protectedResponse.bodyBytes));
          var attendanceData = protectedData['attendance_data'];
          if (attendanceData == null) {
            print('No attendance data found.');
            return [];
          }
          List<Map<String, String>> names = [];
          for (var attendance in attendanceData) {
            var employee = attendance['employee'];
            if (employee != null) {
              names.add({
                "name": employee['name_ar'] ?? 'No Name',
                "uuid": attendance['uuid'] ?? 'No UUID',
                "time_out": attendance['status']['status'] == "Attended"
                    ? attendance['time_out'] ?? 'No Time Out'
                    : "null",
                "status": attendance['status']['status']
              });
            } else {
              print('Employee data is null for an attendance entry.');
            }
          }
          return names;
        } else {
          print(
              'Failed to access protected URL: ${protectedResponse.statusCode}');
          return [];
        }
      } catch (e) {
        print('Error fetching data: $e');
        return [];
      }
    } else {
      return [];
    }
  }

//===================================================================
  Future<void> attendance(
      List<Map<String, String>> data, int num, BuildContext context) async {
    await getToken();
    final headers = {
      'accept': 'application/json, text/plain, */*',
      'authorization': 'Bearer $accessToken',
      'content-type': 'application/json',
    };

    try {
      final parts = accessToken!.split('.');
      if (parts.length != 3) throw Exception('Invalid token structure');

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final empUuid = payload['emp_uuid'];
      const baseUrl =
          "https://seahorse-app-dy9b3.ondigitalocean.app/att/att_by_emp_uuid";
      final userUrl = "$baseUrl/$empUuid";

      http.Response dataAll =
          await http.get(Uri.parse(userUrl), headers: headers);

      var projectUuid =
          jsonDecode(utf8.decode(dataAll.bodyBytes))['project']['uuid'];

      for (var element in data) {
        var state = await http.get(
            Uri.parse(
                "https://seahorse-app-dy9b3.ondigitalocean.app/att/att_status/${element['uuid']}"),
            headers: headers);

        var protectedData = jsonDecode(utf8.decode(state.bodyBytes));
        if ((protectedData.length != 3 && num == 1) ||
            (protectedData.length != 3 && num == 2)) {
          num = 1;

          bool result = await showAbsentDialog(context, '${element['name']}');

          if (result) {
            num = 1;
            print("المعلم اتغيب");
          } else {
            num = 0;
            print("النجم اتحضر");
          }
        }
        var stateUuid = protectedData[num]['uuid'];
        final jsonData = jsonEncode({
          "employee": element['uuid'],
          "status": stateUuid,
          "current_project_uuid": projectUuid,
          "time_in": element['time_in'],
        });
        print(jsonData);
        final r = await http.post(Uri.parse(userUrl),
            headers: headers, body: jsonData);
        print('Response for attendance submission: ${r.statusCode}');
      }
      data.clear();
    } catch (e) {
      print('Error submitting attendance: $e');
    }
  }

  //==================================================================
  Future<void> departure(List<Map<String, String>> data) async {
    final headers = {
      'accept': 'application/json, text/plain, */*',
      'authorization': 'Bearer $accessToken',
      'content-type': 'application/json',
    };

    for (var entry in data) {
      final jsonData = jsonEncode({"time_out": entry['time_out']});
      final url = Uri.parse(
          'https://seahorse-app-dy9b3.ondigitalocean.app/att/att_time_out/${entry['uuid']}');

      try {
        final res = await http.put(url, headers: headers, body: jsonData);
        print('Response status for ${entry['uuid']}: ${res.statusCode}');
      } catch (e) {
        print('Error updating departure for ${entry['uuid']}: $e');
      }
    }
  }

//==================================================================
  Future<bool> logOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(constant.accessToken);
    await prefs.remove(constant.refresh);
    await supabase.auth.signOut();
    return true;
  }

  //=========================================================================
  Future<bool> showAbsentDialog(BuildContext context, String name) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تأكيد التغييب"),
          content: Text("$name استنفد اجازاتة هل تريد تغيبة؟"),
          actions: [
            TextButton(
              child: const Text("نعم"),
              onPressed: () {
                Navigator.of(context).pop(true); // إعادة نعم
              },
            ),
            TextButton(
              child: const Text("لا"),
              onPressed: () {
                Navigator.of(context).pop(false); // إعادة لا
              },
            ),
          ],
        );
      },
    );
  }

//===========================================================================
  Future<List> statusCars() async {
    await getToken();
    List<Map> attendOrAbsent = [];
    try {
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Referer': 'https://att.dr-khaled-kandil.com/',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
      };

      final url = Uri.parse(
          'https://seahorse-app-dy9b3.ondigitalocean.app/att/vehicle-attendance-status/list');

      final res = await http.get(url, headers: headers);
      final status = res.statusCode;
      if (status != 200) {
        return [];
      }

      var statusUuid = jsonDecode(utf8.decode(res.bodyBytes));
      for (var element in statusUuid) {
        attendOrAbsent.add({
          "uuid": element['uuid'],
          "status": element['status'],
        });
      }
      return attendOrAbsent;
    } catch (e) {
      return [];
    }
  }

//============================================================================
  Future<List> getNamesOfDrivers() async {
    await getToken();
    List<Map> names = [];

    try {
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Referer': 'https://att.dr-khaled-kandil.com/',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
      };
      final url = Uri.parse(
          'https://seahorse-app-dy9b3.ondigitalocean.app/emp/vehicles/list-att');
      final res = await http.get(url, headers: headers);
      final drivers = res.statusCode;
      if (drivers != 200) {
        return [];
      }
      var driversName = jsonDecode(utf8.decode(res.bodyBytes));
      for (var element in driversName) {
        names.add(
            {"name": element['beneficiary_name'], "uuid": element['uuid']});
      }

      return names;
    } catch (e) {
      return [];
    }
  }

//============================================
  Future<void> attendanceCar(
      List data, String uuid, BuildContext context) async {
    await getToken();
    try {
      final headers = {
        'accept': 'application/json, text/plain, */*',
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      };
      for (var element in data) {
        final jsonData = jsonEncode({
          "vehicle": element['uuid'],
          "status": uuid,
          "kilometer": element['counter'],
          "time_in": element['time_in']
        });
        final url = Uri.parse(
            'https://seahorse-app-dy9b3.ondigitalocean.app/att/vehicle-attendance/list/create/');
        try {
          final res = await http.post(url, headers: headers, body: jsonData);
          print('Response status for ${element['uuid']}: ${res.statusCode}');
        } catch (e) {
          print('Error updating departure for ${element['uuid']}: $e');
        }
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("تم التسجيل بنجاح")));
      data.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  //=======================================================================
  Future<void> absentCar(List data, String uuid, BuildContext context) async {
    await getToken();
    try {
      final headers = {
        'accept': 'application/json, text/plain, */*',
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      };
      for (var element in data) {
        final jsonData = jsonEncode({
          "vehicle": element['uuid'],
          "status": uuid,
        });
        final url = Uri.parse(
            'https://seahorse-app-dy9b3.ondigitalocean.app/att/vehicle-attendance/list/create/');
        try {
          final res = await http.post(url, headers: headers, body: jsonData);
          print('Response status for ${element['uuid']}: ${res.statusCode}');
        } catch (e) {
          print('Error updating departure for ${element['uuid']}: $e');
        }
      }

      data.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

//=========================================================================
  Future<List> getDepartureCar() async {
    await getToken();
    await getUuidManager();
    List<Map> data = [];
    try {
      final headers = {
        'accept': 'application/json, text/plain, */*',
        'authorization': 'Bearer $accessToken',
        'origin': 'https://att.dr-khaled-kandil.com',
        'priority': 'u=1, i',
        'referer': 'https://att.dr-khaled-kandil.com/',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
      };

      final url = Uri.parse(
          'https://seahorse-app-dy9b3.ondigitalocean.app/att/vehicle-attendance/list/$uuidManager');

      final res = await http.get(url, headers: headers);
      if (res.statusCode == 200) {
        var protectedData = jsonDecode(utf8.decode(res.bodyBytes));
        for (var element in protectedData) {
          data.add({
            "name": element['vehicle']['beneficiary_name'],
            "uuid": element['uuid'],
            "time_out": element['status']['status'] == "Attended"
                ? element['time_out'] ?? 'No Time Out'
                : "null",
            "status": element['status']['status']
          });
        }
      }
    } catch (e) {
      print(e.toString());
    }
    return data;
  }

//=========================================================================
  Future<void> departureCar(List data) async {
    final headers = {
      'sec-ch-ua-platform': '"Windows"',
      'Authorization': 'Bearer $accessToken',
      'Referer': 'https://att.dr-khaled-kandil.com/',
      'sec-ch-ua':
          '"Google Chrome";v="129", "Not=A?Brand";v="8", "Chromium";v="129"',
      'sec-ch-ua-mobile': '?0',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json',
    };

    for (var element in data) {
      final data = '{"time_out":"${element['time_out']}"}';

      final url = Uri.parse(
          'https://seahorse-app-dy9b3.ondigitalocean.app/att/vehicle-attendance/object/${element['uuid']}/time-out/');

      final res = await http.put(url, headers: headers, body: data);
      final status = res.statusCode;
      if (status != 200) throw Exception('http.put error: statusCode= $status');

      print(res.body);
    }
  }
}
