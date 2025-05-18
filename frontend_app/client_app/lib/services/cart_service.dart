import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'local_cart_service.dart';

class CartService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  final LocalCartService _localCartService = LocalCartService();

  // Obtenir le panier local
  Future<List<Map<String, dynamic>>> getCart() async {
    return await _localCartService.getCart();
  }

  // Ajouter un produit au panier local
  Future<void> addToCart(String productId, int quantity, Map<String, dynamic> product) async {
    await _localCartService.addToCart(productId, quantity, product);
  }

  // Mettre à jour la quantité d'un produit dans le panier local
  Future<void> updateQuantity(String productId, int quantity) async {
    await _localCartService.updateQuantity(productId, quantity);
  }

  // Supprimer un produit du panier local
  Future<void> removeFromCart(String productId) async {
    await _localCartService.removeFromCart(productId);
  }

  // Vider le panier local
  Future<void> clearCart() async {
    await _localCartService.clearCart();
  }

  // Calculer le total du panier local
  Future<double> calculateTotal() async {
    return await _localCartService.calculateTotal();
  }

  // Synchroniser le panier avec le backend lors de la commande
  Future<Map<String, dynamic>> syncCartWithBackend() async {
    try {
      final token = await _authService.getToken();
      final localCart = await _localCartService.getCart();

      // Préparer les données pour la synchronisation
      final items = localCart.map((item) => {
        'produitId': item['produitId'],
        'quantite': item['quantite']
      }).toList();

      // Envoyer les données au backend
      final response = await http.post(
        Uri.parse('$baseUrl/panier'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'items': items,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Échec de la synchronisation du panier: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Erreur syncCartWithBackend: $e');
      throw Exception('Erreur: $e');
    }
  }

  Future<Map<String, dynamic>> applyPromoCode(String code) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/panier/coupon'),
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
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to apply promo code');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 