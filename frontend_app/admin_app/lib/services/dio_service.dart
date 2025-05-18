import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class DioService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = Duration(seconds: ApiConfig.connectTimeout);
    _dio.options.receiveTimeout = Duration(seconds: ApiConfig.receiveTimeout);
    _dio.options.responseType = ResponseType.json;
    
    // Ajout de logs pour le débogage
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
    
    // Ajouter un intercepteur pour les headers d'authentification
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Récupérer le token et l'ajouter aux headers
          final token = await _getToken();
          print('Token récupéré: ${token != null ? 'Oui' : 'Non'}');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          print('Requête: ${options.method} ${options.baseUrl}${options.path}');
          print('Headers: ${options.headers}');
          print('Data: ${options.data}');
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Gérer les erreurs (ex: token expiré)
          print('Erreur Dio: ${e.type} - ${e.message}');
          print('Statut: ${e.response?.statusCode}');
          print('Données de réponse: ${e.response?.data}');
          if (e.response?.statusCode == 401) {
            // Implémenter la logique de refresh token si nécessaire
            print('Unauthorized - Token may be expired');
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Récupérer le token d'authentification
  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  // Méthode GET
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Méthode POST
  Future<Response> post(String path, dynamic data) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Méthode PUT
  Future<Response> put(String path, dynamic data) async {
    try {
      print('PUT request to: $path');
      print('Data: $data');
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Méthode DELETE
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Gestion des erreurs
  void _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        print('Connection timeout');
        break;
      case DioExceptionType.sendTimeout:
        print('Send timeout');
        break;
      case DioExceptionType.receiveTimeout:
        print('Receive timeout');
        break;
      case DioExceptionType.badResponse:
        print('Bad response: ${e.response?.statusCode} - ${e.response?.data}');
        break;
      case DioExceptionType.cancel:
        print('Request cancelled');
        break;
      default:
        print('Error: ${e.message}');
        break;
    }
  }
} 