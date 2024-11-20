import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:social_heart/core/server_constant.dart';

class HttpService {
  late int statusCode;
  late dynamic response;

  HttpService();

  Future<void> post(
      String url, Map<String, String>? headers, Object body) async {
    final res = await http.post(
      Uri.parse("${ServerConstant.baseUrl}$url"),
      headers: headers,
      body: jsonEncode(body),
    );

    statusCode = res.statusCode;
    response = jsonDecode(res.body);
  }

  Future<void> put(
      String url, Map<String, String>? headers, Object body) async {
    final res = await http.put(
      Uri.parse("${ServerConstant.baseUrl}$url"),
      headers: headers,
      body: jsonEncode(body),
    );

    statusCode = res.statusCode;
    response = jsonDecode(res.body);
  }

  Future<void> get(String url, Map<String, String>? headers) async {
    final res = await http.get(
      Uri.parse("${ServerConstant.baseUrl}$url"),
      headers: headers,
    );

    statusCode = res.statusCode;
    response = jsonDecode(res.body);
  }

  Future<void> patch(
      String url, Map<String, String>? headers, Object body) async {
    final res = await http.patch(
      Uri.parse("${ServerConstant.baseUrl}$url"),
      headers: headers,
      body: jsonEncode(body),
    );

    statusCode = res.statusCode;
    response = jsonDecode(res.body);
  }

  Future<void> delete(
      String url, Map<String, String>? headers, Object body) async {
    final res = await http.delete(
      Uri.parse("${ServerConstant.baseUrl}$url"),
      headers: headers,
      body: jsonEncode(body),
    );

    statusCode = res.statusCode;
    response = jsonDecode(res.body);
  }
}
