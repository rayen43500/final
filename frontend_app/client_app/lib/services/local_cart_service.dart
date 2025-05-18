import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalCartService {
  static const String _cartKey = 'local_cart';

  // Ajouter un produit au panier local
  Future<void> addToCart(String productId, int quantity, Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();
    
    // Vérifier si le produit existe déjà dans le panier
    final existingItemIndex = cart.indexWhere((item) => item['produitId'] == productId);
    
    if (existingItemIndex != -1) {
      // Mettre à jour la quantité si le produit existe déjà
      cart[existingItemIndex]['quantite'] += quantity;
    } else {
      // Ajouter un nouvel élément au panier
      cart.add({
        'produitId': productId,
        'quantite': quantity,
        'produit': product,
      });
    }
    
    await prefs.setString(_cartKey, json.encode(cart));
  }

  // Obtenir le panier local
  Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    
    if (cartJson == null) {
      return [];
    }
    
    final List<dynamic> cartData = json.decode(cartJson);
    return cartData.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // Mettre à jour la quantité d'un produit
  Future<void> updateQuantity(String productId, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();
    
    final itemIndex = cart.indexWhere((item) => item['produitId'] == productId);
    if (itemIndex != -1) {
      cart[itemIndex]['quantite'] = quantity;
      await prefs.setString(_cartKey, json.encode(cart));
    }
  }

  // Supprimer un produit du panier
  Future<void> removeFromCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await getCart();
    
    cart.removeWhere((item) => item['produitId'] == productId);
    await prefs.setString(_cartKey, json.encode(cart));
  }

  // Vider le panier
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  // Calculer le total du panier
  Future<double> calculateTotal() async {
    final cart = await getCart();
    double total = 0;
    
    for (var item in cart) {
      final product = item['produit'];
      final quantity = item['quantite'];
      final price = product['prixPromo'] ?? product['prix'];
      total += price * quantity;
    }
    
    return total;
  }
} 