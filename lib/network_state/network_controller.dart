import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkController {
  static final Connectivity _connectivity = Connectivity();

  // Stream for connection status
  static Stream<bool> get connectionStream async* {
    await for (var result in _connectivity.onConnectivityChanged) {
      // تحقق مما إذا كان الاتصال غير موجود
      yield !result.contains(ConnectivityResult.none);
    }
  }

  // Function to check current connection
  static Future<bool> isConnection() async {
    var result = await _connectivity.checkConnectivity();

    return !result.contains(ConnectivityResult.none);
  }
}
