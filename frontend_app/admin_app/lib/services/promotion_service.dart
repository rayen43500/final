import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class PromotionService {
  final AuthService _authService = AuthService();
  final String baseUrl = ApiConfig.baseUrl;
  final _logger = Logger();

  // Récupérer toutes les promotions
  Future<List<dynamic>> getAllPromotions() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/promotions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Promotions récupérées: ${data.length} promotions');
        return data;
      } else {
        throw Exception('Échec de récupération des promotions: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getAllPromotions: $e');
      return [];
    }
  }

  // Récupérer une promotion par son ID
  Future<Map<String, dynamic>> getPromotionById(String id) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/promotions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec de récupération de la promotion: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getPromotionById: $e');
      rethrow;
    }
  }

  // Créer une nouvelle promotion
  Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> promotionData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      _logger.i('Token d\'authentification: $token');
      _logger.i('Création de promotion: ${json.encode(promotionData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/promotions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(promotionData),
      );

      _logger.i('Réponse du serveur: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['promotion'];
      } else {
        _logger.e('Échec de création de la promotion: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de création de la promotion: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans createPromotion: $e');
      rethrow;
    }
  }

  // Mettre à jour une promotion
  Future<Map<String, dynamic>> updatePromotion(String id, Map<String, dynamic> promotionData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      _logger.i('Mise à jour de promotion: ${json.encode(promotionData)}');

      final response = await http.put(
        Uri.parse('$baseUrl/api/promotions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(promotionData),
      );

      _logger.i('Réponse du serveur: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['promotion'];
      } else {
        _logger.e('Échec de mise à jour de la promotion: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de mise à jour de la promotion: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans updatePromotion: $e');
      rethrow;
    }
  }

  // Supprimer une promotion
  Future<bool> deletePromotion(String id) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/promotions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _logger.i('Réponse du serveur: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        _logger.e('Échec de suppression de la promotion: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de suppression de la promotion: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans deletePromotion: $e');
      rethrow;
    }
  }

  // Appliquer un code promo à un produit
  Future<Map<String, dynamic>> applyPromoCode(String productId, String promoCode) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/promotions/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': productId,
          'promoCode': promoCode,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec d\'application du code promo: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans applyPromoCode: $e');
      rethrow;
    }
  }
} 