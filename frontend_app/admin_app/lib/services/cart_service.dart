import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class CartService {
  final AuthService _authService = AuthService();
  final String baseUrl = ApiConfig.baseUrl;
  final _logger = Logger();

  // Récupérer le panier d'un utilisateur spécifique
  Future<Map<String, dynamic>> getUserCart(String userId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/cart/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Panier récupéré avec succès pour l\'utilisateur: $userId');
        return data;
      } else {
        _logger.e('Échec de récupération du panier: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de récupération du panier: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getUserCart: $e');
      rethrow;
    }
  }

  // Récupérer tous les paniers (avec pagination)
  Future<Map<String, dynamic>> getAllCarts({
    int page = 1,
    int limit = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final queryParams = <String, String>{};
      if (page > 0) queryParams['page'] = page.toString();
      if (limit > 0) queryParams['limit'] = limit.toString();
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sortOrder'] = sortOrder;

      final uri = Uri.parse('$baseUrl/api/cart').replace(queryParameters: queryParams);
      _logger.i('Récupération des paniers: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Paniers récupérés avec succès. Total: ${data['total'] ?? 0}');
        return data;
      } else {
        _logger.e('Échec de récupération des paniers: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de récupération des paniers: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getAllCarts: $e');
      rethrow;
    }
  }

  // Ajouter un produit au panier d'un utilisateur
  Future<Map<String, dynamic>> addToCart(String userId, String produitId, int quantite) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'produitId': produitId,
          'quantite': quantite,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Produit ajouté au panier avec succès');
        return data;
      } else {
        _logger.e('Échec d\'ajout au panier: ${response.statusCode} - ${response.body}');
        throw Exception('Échec d\'ajout au panier: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans addToCart: $e');
      rethrow;
    }
  }

  // Mettre à jour la quantité d'un produit dans le panier
  Future<Map<String, dynamic>> updateCartItem(String userId, String produitId, int quantite) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/cart/$userId/$produitId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'quantité': quantite,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Quantité mise à jour avec succès');
        return data;
      } else {
        _logger.e('Échec de mise à jour du panier: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de mise à jour du panier: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans updateCartItem: $e');
      rethrow;
    }
  }

  // Supprimer un produit du panier
  Future<Map<String, dynamic>> removeFromCart(String userId, String produitId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart/$userId/$produitId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Produit supprimé du panier avec succès');
        return data;
      } else {
        _logger.e('Échec de suppression du produit: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de suppression du produit: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans removeFromCart: $e');
      rethrow;
    }
  }

  // Vider le panier
  Future<Map<String, dynamic>> clearCart(String userId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Panier vidé avec succès');
        return data;
      } else {
        _logger.e('Échec de vidage du panier: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de vidage du panier: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans clearCart: $e');
      rethrow;
    }
  }

  // Appliquer un code promo au panier
  Future<Map<String, dynamic>> applyCoupon(String userId, String code) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/$userId/coupon'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Code promo appliqué avec succès');
        return data;
      } else {
        _logger.e('Échec d\'application du code promo: ${response.statusCode} - ${response.body}');
        throw Exception('Échec d\'application du code promo: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans applyCoupon: $e');
      rethrow;
    }
  }

  // Obtenir les paniers abandonnés
  Future<List<dynamic>> getAbandonedCarts({int days = 7}) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/cart/abandoned?days=$days'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Paniers abandonnés récupérés avec succès');
        return data['carts'] ?? [];
      } else {
        _logger.e('Échec de récupération des paniers abandonnés: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de récupération des paniers abandonnés: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getAbandonedCarts: $e');
      rethrow;
    }
  }
} 