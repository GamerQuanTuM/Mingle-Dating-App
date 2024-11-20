import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:client/core/debug.dart';
import 'package:http/http.dart' as http;

abstract class ServerConstant {
  static const int _serverPort = 8000;
  static const String _productionUrl = "https://your-production-url.com";
  // static const String _devMachineIpLocal = "10.0.2.2";
  static const String _devMachineIp = "192.168.0.101";

  static String get baseUrl {
    if (const bool.fromEnvironment('dart.vm.product')) {
      // Debug.print('Using production URL');
      return _productionUrl;
    }

    // Development URL
    if (kIsWeb) {
      // Debug.print('Using Web development URL');
      return "http://localhost:$_serverPort";
    }
    try {
      switch (Platform.operatingSystem) {
        case 'android':
          // Debug.print('Using Android development URL');
          // return "http://$_devMachineIp:$_serverPort";
          return "http://localhost:$_serverPort";
        case 'ios':
          // Debug.print('Using iOS development URL');
          return "http://127.0.0.1:$_serverPort";
        case 'windows':
          // Debug.print('Using Windows development URL');
          return "http://localhost:$_serverPort";
        default:
          // Debug.print('Using default development URL');
          return "http://localhost:$_serverPort";
      }
    } catch (e) {
      // Debug.print('Error determining platform: $e');
      // Debug.print('Falling back to default development URL');
      return "http://localhost:$_serverPort";
    }
  }

  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      // Debug.print('Attempting to connect to: $url');

      final client = http.Client();
      try {
        final response = await client.get(url).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Debug.print('Connection timeout');
            return http.Response('Timeout', 408);
          },
        );

        // Debug.print('Connection test response: ${response.statusCode}');
        return response.statusCode == 200;
      } finally {
        client.close();
      }
    } catch (e) {
      // Debug.print('Error testing connection: $e');
      return false;
    }
  }
}
