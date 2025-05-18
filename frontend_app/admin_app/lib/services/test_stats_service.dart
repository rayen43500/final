import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class TestStatsService {
  final AuthService _authService = AuthService();
  final String baseUrl = ApiConfig.baseUrl;
  final String apiPath = '/api/statistics';
  final _logger = Logger();

  // Récupérer toutes les statistiques de test avec filtrage
  Future<Map<String, dynamic>> getAllTestStats({
    String? testName,
    String? testType,
    String? module,
    String? environment,
    bool? success,
    String? startDate,
    String? endDate,
    String sort = '-executionDate',
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Construire l'URL avec les paramètres de requête
      final queryParams = <String, String>{};
      if (testName != null) queryParams['testName'] = testName;
      if (testType != null) queryParams['testType'] = testType;
      if (module != null) queryParams['module'] = module;
      if (environment != null) queryParams['environment'] = environment;
      if (success != null) queryParams['success'] = success.toString();
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      queryParams['sort'] = sort;
      queryParams['limit'] = limit.toString();
      queryParams['page'] = page.toString();

      final uri = Uri.parse('$baseUrl$apiPath/tests').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des statistiques: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Erreur dans getAllTestStats: $e');
      rethrow;
    }
  }

  // Créer une nouvelle statistique de test
  Future<Map<String, dynamic>> createTestStat(Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$apiPath/tests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la création de la statistique: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Erreur dans createTestStat: $e');
      rethrow;
    }
  }

  // Récupérer une statistique spécifique
  Future<Map<String, dynamic>> getTestStatById(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$apiPath/tests/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération de la statistique: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Erreur dans getTestStatById: $e');
      rethrow;
    }
  }

  // Mettre à jour une statistique
  Future<Map<String, dynamic>> updateTestStat(String id, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await http.put(
        Uri.parse('$baseUrl$apiPath/tests/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la mise à jour de la statistique: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Erreur dans updateTestStat: $e');
      rethrow;
    }
  }

  // Supprimer une statistique
  Future<void> deleteTestStat(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl$apiPath/tests/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la suppression de la statistique: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Erreur dans deleteTestStat: $e');
      rethrow;
    }
  }

  // Obtenir des rapports agrégés
  Future<Map<String, dynamic>> getTestReports({
    String? module,
    String? startDate,
    String? endDate,
    String groupBy = 'testName',
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Construire l'URL avec les paramètres de requête
      final queryParams = <String, String>{};
      if (module != null) queryParams['module'] = module;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      queryParams['groupBy'] = groupBy;

      final uri = Uri.parse('$baseUrl$apiPath/reports').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des rapports: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Erreur dans getTestReports: $e');
      rethrow;
    }
  }

  // Comparer les performances entre deux périodes
  Future<Map<String, dynamic>> compareTestPerformance({
    String? testName,
    String? module,
    required String firstPeriodStart,
    required String firstPeriodEnd,
    required String secondPeriodStart,
    required String secondPeriodEnd,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Construire l'URL avec les paramètres de requête
      final queryParams = <String, String>{};
      if (testName != null) queryParams['testName'] = testName;
      if (module != null) queryParams['module'] = module;
      queryParams['firstPeriodStart'] = firstPeriodStart;
      queryParams['firstPeriodEnd'] = firstPeriodEnd;
      queryParams['secondPeriodStart'] = secondPeriodStart;
      queryParams['secondPeriodEnd'] = secondPeriodEnd;

      final uri = Uri.parse('$baseUrl$apiPath/compare').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la comparaison des performances: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Erreur dans compareTestPerformance: $e');
      rethrow;
    }
  }
} 