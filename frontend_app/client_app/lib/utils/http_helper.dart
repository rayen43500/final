import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HttpHelper {
  // Récupérer le token d'authentification des préférences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Méthode GET
  Future<HttpResponse> get(String url) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('Error in GET request: $e');
      throw HttpException('Failed to perform GET request: $e');
    }
  }

  // Méthode POST
  Future<HttpResponse> post(String url, dynamic data) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      print('Error in POST request: $e');
      throw HttpException('Failed to perform POST request: $e');
    }
  }

  // Méthode PUT
  Future<HttpResponse> put(String url, dynamic data) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      print('Error in PUT request: $e');
      throw HttpException('Failed to perform PUT request: $e');
    }
  }

  // Méthode DELETE
  Future<HttpResponse> delete(String url) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('Error in DELETE request: $e');
      throw HttpException('Failed to perform DELETE request: $e');
    }
  }

  // Traiter la réponse
  HttpResponse _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        data = response.body;
      }
      return HttpResponse(
        statusCode: response.statusCode,
        data: data,
      );
    } else {
      dynamic errorData;
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        errorData = response.body;
      }
      throw HttpException(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
        data: errorData,
      );
    }
  }
}

class HttpResponse {
  final int statusCode;
  final dynamic data;

  HttpResponse({
    required this.statusCode,
    required this.data,
  });
}

class HttpException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  HttpException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
} 