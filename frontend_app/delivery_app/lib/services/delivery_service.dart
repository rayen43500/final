import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/delivery_model.dart';
import '../utils/token_manager.dart';

class DeliveryService {
  String get baseUrl => ApiConfig.getBaseUrl();
  
  // Récupérer les commandes assignées au livreur
  Future<List<Delivery>> getDeliveryPersonOrders() async {
    try {
      print('🚚 [API] Tentative de récupération des livraisons...');
      
      final token = await TokenManager.getToken();
      
      if (token == null) {
        print('🚫 [API] Échec: Token non trouvé');
        throw Exception('Non authentifié');
      }
      
      final requestUrl = '$baseUrl${ApiConfig.deliveryOrdersEndpoint}';
      print('🔗 [API] URL de requête: $requestUrl');
      
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('📡 [API] Statut de réponse: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ [API] Réponse réussie');
        final jsonData = json.decode(response.body);
        print('📄 [API] Données reçues: ${response.body.substring(0, min(100, response.body.length))}...');
        
        if (jsonData['success'] == true) {
          final List<dynamic> commandesData = jsonData['commandes'] ?? [];
          
          print('📦 [API] Nombre de commandes reçues: ${commandesData.length}');
          
          if (commandesData.isEmpty) {
            return [];
          }
          
          return commandesData.map((item) => Delivery.fromJson(item)).toList();
        } else {
          print('❌ [API] Échec avec message: ${jsonData['message']}');
          throw Exception(jsonData['message'] ?? 'Erreur lors de la récupération des livraisons');
        }
      } else if (response.statusCode == 401) {
        print('🔒 [API] Non autorisé (401)');
        throw Exception('Non autorisé');
      } else {
        print('⚠️ [API] Erreur HTTP: ${response.statusCode}');
        print('⚠️ [API] Corps de la réponse: ${response.body}');
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 [API] Exception: $e');
      if (ApiConfig.enableDetailedLogs) {
        print('Erreur lors de la récupération des livraisons: $e');
      }
      rethrow;
    }
  }
  
  // Mettre à jour le statut d'une livraison
  Future<bool> updateDeliveryStatus(String deliveryId, String status) async {
    try {
      print('🚚 [API] Tentative de mise à jour du statut pour la livraison $deliveryId...');
      
      final token = await TokenManager.getToken();
      
      if (token == null) {
        print('🚫 [API] Échec: Token non trouvé');
        throw Exception('Non authentifié');
      }
      
      final requestUrl = '$baseUrl${ApiConfig.updateOrderStatusEndpoint.replaceAll('{id}', deliveryId)}';
      print('🔗 [API] URL de requête: $requestUrl');
      print('📝 [API] Nouveau statut demandé: $status');
      
      // Convertir le statut frontend en statut backend
      String backendStatus = status;
      if (status == 'En cours') {
        backendStatus = 'Expédiée';
        print('🔄 [API] Conversion du statut: "En cours" -> "Expédiée"');
      }
      
      // Inspecter l'objet status envoyé
      final bodyJson = json.encode({"status": backendStatus});
      print('📦 [API] Corps de la requête: $bodyJson');
      
      final response = await http.put(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: bodyJson,
      );
      
      print('📡 [API] Statut de réponse: ${response.statusCode}');
      print('📄 [API] Corps de la réponse: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ [API] Mise à jour réussie');
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      } else {
        print('⚠️ [API] Erreur HTTP: ${response.statusCode}');
        print('⚠️ [API] Corps de la réponse: ${response.body}');
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 [API] Exception: $e');
      if (ApiConfig.enableDetailedLogs) {
        print('Erreur lors de la mise à jour du statut: $e');
      }
      return false;
    }
  }
  
  // Méthode pour tester la connexion à l'API
  Future<bool> testApiConnection() async {
    try {
      print('🔍 [API] Test de connexion à l\'API...');
      
      final response = await http.get(Uri.parse('$baseUrl${ApiConfig.statusEndpoint}'));
      
      print('📡 [API] Statut de réponse: ${response.statusCode}');
      print('📄 [API] Corps de la réponse: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('💥 [API] Erreur de connexion: $e');
      return false;
    }
  }
} 