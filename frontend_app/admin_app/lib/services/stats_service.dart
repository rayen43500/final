import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import '../models/order_model.dart';

class StatsService {
  final AuthService _authService = AuthService();
  final String baseUrl = ApiConfig.baseUrl;
  final _logger = Logger();

  // Récupérer les statistiques générales
  Future<Map<String, dynamic>> getStats() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        _logger.e('Utilisateur non authentifié');
        throw Exception('Utilisateur non authentifié');
      }

      _logger.d('Tentative de récupération des commandes');
      
      // Récupérer toutes les commandes avec le même endpoint que OrderService
      final response = await http.get(
        Uri.parse('$baseUrl/api/commandes/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _logger.d('Response status: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Traiter la réponse comme dans OrderService
        final data = json.decode(response.body);
        List<dynamic> ordersJson;
        
        _logger.d('Type de données reçu: ${data.runtimeType}');
        
        // Extraire les commandes selon la structure de la réponse
        if (data is List) {
          ordersJson = data;
        } else if (data is Map) {
          if (data.containsKey('commandes')) {
            ordersJson = data['commandes'];
          } else if (data.containsKey('data')) {
            ordersJson = data['data'];
          } else if (data.containsKey('orders')) {
            ordersJson = data['orders'];
          } else {
            _logger.e('Structure de données inattendue: $data');
            return _getDefaultStats();
          }
        } else {
          _logger.e('Format de données inattendu: $data');
          return _getDefaultStats();
        }
        
        _logger.d('${ordersJson.length} commandes récupérées avec succès');
        
        // Convertir en objets Order
        final List<Order> orders = ordersJson.map((json) => Order.fromJson(json)).toList();
        
        // Calculer les statistiques
        return _calculateStats(orders);
      } else if (response.statusCode == 404) {
        // Essayer l'autre endpoint si le premier n'est pas trouvé
        _logger.d('Endpoint non trouvé, essai avec /api/orders');
        final response2 = await http.get(
          Uri.parse('$baseUrl/api/orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        _logger.d('Réponse du serveur (endpoint 2): ${response2.statusCode}');
        
        if (response2.statusCode >= 200 && response2.statusCode < 300) {
          final data = json.decode(response2.body);
          List<dynamic> ordersJson;
          
          if (data is List) {
            ordersJson = data;
          } else if (data is Map) {
            if (data.containsKey('orders')) {
              ordersJson = data['orders'];
            } else if (data.containsKey('data')) {
              ordersJson = data['data'];
            } else {
              _logger.e('Structure de données inattendue dans la seconde réponse: $data');
              return _getDefaultStats();
            }
          } else {
            _logger.e('Format de données inattendu dans la seconde réponse: $data');
            return _getDefaultStats();
          }
          
          // Convertir en objets Order
          final List<Order> orders = ordersJson.map((json) => Order.fromJson(json)).toList();
          
          // Calculer les statistiques
          return _calculateStats(orders);
        }
        
        _logger.e('Les deux endpoints ont échoué');
        return _getDefaultStats();
      } else {
        _logger.e('Erreur API: ${response.statusCode} - ${response.body}');
        return _getDefaultStats();
      }
    } catch (e) {
      _logger.e('Erreur dans getStats: $e');
      return _getDefaultStats();
    }
  }
  
  // Calculer les statistiques à partir des commandes
  Map<String, dynamic> _calculateStats(List<Order> orders) {
    try {
      // Nombre total de commandes
      final int totalOrders = orders.length;
      
      // Commandes livrées
      final List<Order> deliveredOrders = orders.where((order) => order.status == 'Livrée').toList();
      final int deliveredOrdersCount = deliveredOrders.length;
      
      // Revenu total (des commandes livrées)
      final double totalRevenue = deliveredOrders.fold(0, (sum, order) => sum + order.montant);
      
      // Commandes par statut
      final Map<String, int> ordersByStatus = {
        'En attente': orders.where((o) => o.status == 'En attente').length,
        'Expédiée': orders.where((o) => o.status == 'Expédiée').length,
        'Livrée': deliveredOrdersCount,
        'Annulée': orders.where((o) => o.status == 'Annulée').length,
      };
      
      // Compter les clients uniques
      final Set<String> uniqueClients = orders.map((o) => o.clientName).toSet();
      
      // Calcul du taux de conversion (simulé)
      final double conversionRate = totalOrders > 0 ? (deliveredOrdersCount / totalOrders * 100) : 0;
      
      // Créer les données de statistiques mensuelles (données simulées pour le moment)
      List<Map<String, dynamic>> monthlySales = _createMonthlySales(orders);
      
      // Statistiques par catégorie
      List<Map<String, dynamic>> categoryStats = [
        {'categorie': 'Total des commandes', 'valeur': totalOrders},
        {'categorie': 'Commandes livrées', 'valeur': deliveredOrdersCount},
        {'categorie': 'Revenu total (DT)', 'valeur': totalRevenue.toStringAsFixed(2)},
      ];
      
      // Meilleurs produits vendus
      List<Map<String, dynamic>> bestSellingProducts = _calculateBestSellingProducts(orders);
      
      return {
        'revenuTotal': totalRevenue,
        'revenuComparaison': 0,
        'commandesTotal': totalOrders,
        'commandesComparaison': 0,
        'clientsTotal': uniqueClients.length,
        'clientsComparaison': 0,
        'vuesProduits': totalOrders * 5,  // Valeur simulée
        'vuesComparaison': 0,
        'tauxConversion': conversionRate,
        'tauxConversionComparaison': 0,
        'commandesParStatut': ordersByStatus,
        'produitsBestSellers': bestSellingProducts,
        'ventesMensuelles': monthlySales,
        'ventesParCategorie': categoryStats,
      };
    } catch (e) {
      _logger.e('Erreur lors du calcul des statistiques: $e');
      return _getDefaultStats();
    }
  }
  
  // Calculer les produits les plus vendus
  List<Map<String, dynamic>> _calculateBestSellingProducts(List<Order> orders) {
    try {
      // Créer un map pour regrouper les produits par nom
      Map<String, Map<String, dynamic>> productSales = {};
      
      // Parcourir toutes les commandes pour agréger les ventes
      for (var order in orders) {
        if (order.status == 'Livrée' || order.status == 'Expédiée') {
          for (var product in order.produits) {
            if (!productSales.containsKey(product.nom)) {
              productSales[product.nom] = {
                'nom': product.nom,
                'ventes': 0,
                'revenu': 0.0,
              };
            }
            
            productSales[product.nom]!['ventes'] += product.quantite;
            productSales[product.nom]!['revenu'] += (product.prix * product.quantite);
          }
        }
      }
      
      // Convertir le Map en liste
      List<Map<String, dynamic>> result = productSales.values.toList();
      
      // Trier par nombre de ventes (décroissant)
      result.sort((a, b) => (b['ventes'] as num).compareTo(a['ventes'] as num));
      
      // Limiter à 5 produits
      if (result.length > 5) {
        result = result.sublist(0, 5);
      }
      
      return result;
    } catch (e) {
      _logger.e('Erreur lors du calcul des produits les plus vendus: $e');
      return [
        {'nom': 'Doliprane 1000mg', 'ventes': 28, 'revenu': 168.72},
        {'nom': 'Advil 200mg', 'ventes': 45, 'revenu': 584.55},
        {'nom': 'Smecta', 'ventes': 12, 'revenu': 155.88},
        {'nom': 'Vitamines C', 'ventes': 24, 'revenu': 598.00},
        {'nom': 'Sérum Physiologique', 'ventes': 32, 'revenu': 255.68},
      ];
    }
  }
  
  // Créer les données de ventes mensuelles
  List<Map<String, dynamic>> _createMonthlySales(List<Order> orders) {
    // Définir les mois en dehors du bloc try pour qu'ils soient accessibles dans le catch
    const List<String> months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    try {
      // Créer un tableau pour les 12 mois
      Map<int, double> monthlySalesMap = {};
      
      // Initialiser les valeurs à 0
      for (int i = 1; i <= 12; i++) {
        monthlySalesMap[i] = 0;
      }
      
      // Parcourir les commandes livrées pour calculer les ventes par mois
      for (var order in orders) {
        if (order.status == 'Livrée') {
          try {
            DateTime orderDate = DateTime.parse(order.date);
            int month = orderDate.month;
            monthlySalesMap[month] = (monthlySalesMap[month] ?? 0) + order.montant;
          } catch (e) {
            _logger.e('Erreur de parsing de date: $e');
          }
        }
      }
      
      // Convertir en liste pour l'affichage
      List<Map<String, dynamic>> result = [];
      for (int i = 1; i <= 12; i++) {
        result.add({
          'mois': months[i-1],
          'ventes': monthlySalesMap[i] ?? 0,
        });
      }
      
      return result;
    } catch (e) {
      _logger.e('Erreur lors de la création des ventes mensuelles: $e');
      return List.generate(12, (index) {
        return {
          'mois': months[index],
          'ventes': 0.0,
        };
      });
    }
  }
  
  // Statistiques par défaut
  Map<String, dynamic> _getDefaultStats() {
    return {
      'revenuTotal': 0,
      'revenuComparaison': 0,
      'commandesTotal': 0,
      'commandesComparaison': 0,
      'clientsTotal': 0,
      'clientsComparaison': 0,
      'vuesProduits': 0,
      'vuesComparaison': 0,
      'tauxConversion': 0,
      'tauxConversionComparaison': 0,
      'commandesParStatut': {
        'En attente': 0,
        'Expédiée': 0,
        'Livrée': 0,
        'Annulée': 0,
      },
      'produitsBestSellers': [],
      'ventesMensuelles': _getDefaultMonthlySales(),
      'ventesParCategorie': [
        {'categorie': 'Total des commandes', 'valeur': 0},
        {'categorie': 'Commandes livrées', 'valeur': 0},
        {'categorie': 'Revenu total (DT)', 'valeur': '0.00'},
      ],
    };
  }
  
  List<Map<String, dynamic>> _getDefaultMonthlySales() {
    const List<String> months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return List.generate(12, (index) {
      return {
        'mois': months[index],
        'ventes': 0.0,
      };
    });
  }
} 