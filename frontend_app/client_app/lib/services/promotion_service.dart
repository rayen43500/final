import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class PromotionService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getPromotions() async {
    try {
      // URL de l'API
      print('📍 Requête promotions: $baseUrl/promotions');
      
      // Récupérer le token si disponible
      final token = await _authService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      // Effectuer la requête
      final response = await http.get(
        Uri.parse('$baseUrl/promotions'),
        headers: headers,
      );

      // Analyser la réponse
      print('📊 Statut réponse promotions: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Identifier le format de la réponse pour extraction correcte
        List<dynamic> promotionsList = [];
        
        if (responseData is List) {
          // Format 1: La réponse est directement une liste de promotions
          promotionsList = responseData;
        } else if (responseData is Map) {
          // Format 2: La réponse est un objet avec une clé spécifique
          if (responseData.containsKey('promotions')) {
            promotionsList = responseData['promotions'] as List;
          } else if (responseData.containsKey('data')) {
            promotionsList = responseData['data'] as List;
          } else {
            // Format 3: Structure inconnue, chercher des listes
            for (var key in responseData.keys) {
              if (responseData[key] is List) {
                promotionsList = responseData[key] as List;
                print('🔍 Liste trouvée dans la clé: $key');
                break;
              }
            }
          }
        }
        
        // Vérifier si on a trouvé des promotions
        print('🏷️ ${promotionsList.length} promotions trouvées dans la réponse');
        
        if (promotionsList.isNotEmpty) {
          return promotionsList;
        }
      }
      
      // Si on arrive ici, c'est qu'on n'a pas pu extraire de promotions ou qu'il y a eu une erreur
      print('⚠️ Aucune promotion trouvée ou erreur ${response.statusCode}, utilisation des données de test');
      return _getTestPromotions();
      
    } catch (e) {
      print('❌ Erreur dans getPromotions: $e');
      return _getTestPromotions();
    }
  }
  
  // Promotions de test pour le débogage
  List<dynamic> _getTestPromotions() {
    return [
      {
        '_id': 'promo1',
        'nom': 'Offre de bienvenue',
        'description': 'Profitez de 15% de réduction sur votre première commande',
        'codePromo': 'WELCOME15',
        'valeurReduction': 15,
        'dateFin': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'image': 'https://via.placeholder.com/600x300?text=Offre+de+bienvenue',
      },
      {
        '_id': 'promo2',
        'nom': 'Soldes d\'été',
        'description': 'Jusqu\'à 30% de réduction sur les produits solaires',
        'codePromo': 'SUMMER30',
        'valeurReduction': 30,
        'dateFin': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
        'image': 'https://via.placeholder.com/600x300?text=Soldes+d\'été',
      },
    ];
  }

  Future<Map<String, dynamic>> getPromotionById(String id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/promotions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load promotion');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getProductPromotions(String productId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/promotions/product/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load product promotions');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> applyPromoCode(String productId, String code) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/promotions/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': productId,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to apply promo code');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 