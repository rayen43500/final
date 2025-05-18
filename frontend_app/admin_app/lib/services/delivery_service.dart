import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class DeliveryService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, lineLength: 80),
  );

  // Récupérer tous les livreurs
  Future<List<dynamic>> getAllDeliveryPersons() async {
    try {
      // Récupérer le token d'authentification
      final token = await _authService.getToken();
      
      if (token == null) {
        _logger.e('Token d\'authentification non trouvé');
        throw Exception('Authentification requise. Veuillez vous reconnecter.');
      }
      
      _logger.i('Récupération de tous les livreurs');
      
      // Appel à l'API pour récupérer tous les livreurs
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/delivery-persons'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      _logger.i('Statut de réponse: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        
        _logger.i('Données reçues: ${response.body.substring(0, min(100, response.body.length))}...');
        
        // Adapter le parsing en fonction de la structure de réponse
        if (data is List) {
          _logger.i('${data.length} livreurs récupérés avec succès');
          return data;
        } else if (data['deliveryPersons'] != null) {
          _logger.i('${data['deliveryPersons'].length} livreurs récupérés avec succès');
          return data['deliveryPersons'];
        } else {
          _logger.w('Format de réponse inattendu, utilisation des données locales');
          return _getTestDeliveryPersons();
        }
      } else {
        _logger.e('Erreur API: ${response.statusCode} ${response.body}');
        return _getTestDeliveryPersons(); // Pour le développement en attendant l'API
      }
    } catch (e) {
      _logger.e('Exception lors de la récupération des livreurs: $e');
      return _getTestDeliveryPersons(); // Pour le développement en attendant l'API
    }
  }
  
  // Récupérer un livreur par son ID
  Future<Map<String, dynamic>> getDeliveryPersonById(String livreurId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        _logger.e('Token d\'authentification non trouvé');
        throw Exception('Authentification requise. Veuillez vous reconnecter.');
      }
      
      _logger.i('Récupération des détails du livreur: $livreurId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/delivery-persons/$livreurId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        
        // Adapter le parsing en fonction de la structure de réponse
        if (data is Map<String, dynamic>) {
          _logger.i('Détails du livreur récupérés avec succès');
          return data;
        } else if (data['deliveryPerson'] != null) {
          _logger.i('Détails du livreur récupérés avec succès');
          return data['deliveryPerson'];
        } else {
          _logger.w('Format de réponse inattendu: ${response.body}');
          throw Exception('Format de réponse inattendu');
        }
      } else {
        _logger.e('Erreur API: ${response.statusCode} ${response.body}');
        throw Exception('Erreur lors de la récupération des détails du livreur');
      }
    } catch (e) {
      _logger.e('Exception lors de la récupération des détails du livreur: $e');
      rethrow;
    }
  }
  
  // Créer un nouveau livreur
  Future<Map<String, dynamic>> createDeliveryPerson(Map<String, dynamic> livreurData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        _logger.e('Token d\'authentification non trouvé');
        throw Exception('Authentification requise. Veuillez vous reconnecter.');
      }
      
      _logger.i('Création d\'un nouveau compte livreur: ${livreurData['nom']}');
      
      // S'assurer que nous envoyons les bons champs selon le modèle du livreur
      Map<String, dynamic> requestData = {
        'nom': livreurData['nom'],
        'email': livreurData['email'],
        'telephone': livreurData['telephone'],
        'motDePasse': livreurData['password'],
        'role': 'Livreur',
        'isActive': true,
      };
      
      // Ajouter les champs optionnels s'ils sont présents
      if (livreurData['zone'] != null && livreurData['zone'].toString().isNotEmpty) {
        requestData['zone'] = livreurData['zone'];
      }
      
      if (livreurData['vehicule'] != null && livreurData['vehicule'].toString().isNotEmpty) {
        requestData['vehicule'] = livreurData['vehicule'];
      }
      
      _logger.i('Données envoyées: $requestData');
      
      // Utiliser l'endpoint d'enregistrement pour créer un nouvel utilisateur avec rôle de livreur
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        
        _logger.i('Compte livreur créé avec succès');
        
        if (data['user'] != null) {
          return data['user'];
        } else {
          return data;
        }
      } else {
        _logger.e('Erreur API: ${response.statusCode} ${response.body}');
        throw Exception('Erreur lors de la création du compte livreur: ${_getErrorMessage(response)}');
      }
    } catch (e) {
      _logger.e('Exception lors de la création du livreur: $e');
      rethrow;
    }
  }
  
  // Mettre à jour un livreur
  Future<Map<String, dynamic>> updateDeliveryPerson(String livreurId, Map<String, dynamic> livreurData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        _logger.e('Token d\'authentification non trouvé');
        throw Exception('Authentification requise. Veuillez vous reconnecter.');
      }
      
      _logger.i('Mise à jour du livreur: $livreurId');
      
      // Adapter les données pour correspondre à l'API
      Map<String, dynamic> requestData = {
        'name': livreurData['name'] ?? livreurData['nom'],
        'email': livreurData['email'],
        'phone': livreurData['phone'] ?? livreurData['telephone'],
      };
      
      // Si le statut est fourni, l'inclure dans la requête
      if (livreurData['isActive'] != null) {
        requestData['isActive'] = livreurData['isActive'];
      }
      
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/delivery-persons/$livreurId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        
        _logger.i('Livreur mis à jour avec succès');
        
        if (data['deliveryPerson'] != null) {
          return data['deliveryPerson'];
        } else {
          return data;
        }
      } else {
        _logger.e('Erreur API: ${response.statusCode} ${response.body}');
        throw Exception('Erreur lors de la mise à jour du livreur: ${_getErrorMessage(response)}');
      }
    } catch (e) {
      _logger.e('Exception lors de la mise à jour du livreur: $e');
      rethrow;
    }
  }
  
  // Supprimer un livreur
  Future<bool> deleteDeliveryPerson(String livreurId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        _logger.e('Token d\'authentification non trouvé');
        throw Exception('Authentification requise. Veuillez vous reconnecter.');
      }
      
      _logger.i('Suppression du livreur: $livreurId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/delivery-persons/$livreurId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logger.i('Livreur supprimé avec succès');
        return true;
      } else {
        _logger.e('Erreur API: ${response.statusCode} ${response.body}');
        throw Exception('Erreur lors de la suppression du livreur: ${_getErrorMessage(response)}');
      }
    } catch (e) {
      _logger.e('Exception lors de la suppression du livreur: $e');
      rethrow;
    }
  }
  
  // Récupérer les utilisateurs avec le rôle livreur
  Future<List<dynamic>> getUsersWithRoleLivreur() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        _logger.e('Token d\'authentification non trouvé');
        throw Exception('Authentification requise. Veuillez vous reconnecter.');
      }
      
      _logger.i('Récupération des utilisateurs avec rôle livreur');
      
      // Appel à l'API pour récupérer les utilisateurs avec le rôle 'livreur'
      // Utiliser un endpoint plus spécifique ou ajouter un filtre par rôle
      final response = await http.get(
        Uri.parse('$baseUrl/api/users?role=Livreur'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      _logger.i('Statut de réponse: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        
        _logger.i('Données reçues: ${response.body.substring(0, min(100, response.body.length))}...');
        
        List<dynamic> livreurs = [];
        
        // Adapter le parsing en fonction de la structure de réponse
        if (data is List) {
          // Filtrer pour ne garder que les utilisateurs qui ont le rôle 'Livreur' (avec majuscule comme dans les données)
          livreurs = data.where((user) => user['role'] == 'Livreur').toList();
          _logger.i('${livreurs.length} utilisateurs livreurs récupérés avec succès');
          
          // Mapper les champs pour correspondre au modèle DeliveryPerson
          return livreurs.map((livreur) => _mapUserToDeliveryPerson(livreur)).toList();
        } else if (data['users'] != null) {
          // Filtrer pour ne garder que les utilisateurs qui ont le rôle 'Livreur'
          livreurs = (data['users'] as List).where((user) => user['role'] == 'Livreur').toList();
          _logger.i('${livreurs.length} utilisateurs livreurs récupérés avec succès');
          
          // Mapper les champs pour correspondre au modèle DeliveryPerson
          return livreurs.map((livreur) => _mapUserToDeliveryPerson(livreur)).toList();
        } else {
          _logger.w('Format de réponse inattendu, utilisation des données locales');
          return _getTestDeliveryPersons();
        }
      } else {
        _logger.e('Erreur API: ${response.statusCode} ${response.body}');
        return _getTestDeliveryPersons(); // Pour le développement en attendant l'API
      }
    } catch (e) {
      _logger.e('Exception lors de la récupération des utilisateurs livreurs: $e');
      return _getTestDeliveryPersons(); // Pour le développement en attendant l'API
    }
  }
  
  // Fonction utilitaire pour convertir un utilisateur en livreur
  Map<String, dynamic> _mapUserToDeliveryPerson(Map<String, dynamic> user) {
    // Transformation des données utilisateur en données de livreur
    return {
      '_id': user['_id'],
      'name': user['nom'],
      'phone': user['telephone'],
      'email': user['email'],
      'status': user['isActive'] == true ? 'Disponible' : 'Inactif',
      'livraisons': user['livraisons'] ?? 0,
      'rating': user['rating'] ?? 0.0,
      'zone': user['zone'] ?? '',
      'vehicule': user['vehicule'] ?? '',
      'photo': user['photo'] ?? 'https://picsum.photos/200/300',
      'isActive': user['isActive'] ?? true,
      'createdAt': user['createdAt'],
      'updatedAt': user['updatedAt'],
    };
  }
  
  // Extraire le message d'erreur d'une réponse HTTP
  String _getErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['message'] ?? data['error'] ?? 'Erreur inconnue';
    } catch (e) {
      return 'Erreur de serveur: ${response.statusCode}';
    }
  }
  
  // Fonction utilitaire pour limiter la longueur d'une chaîne
  int min(int a, int b) => a < b ? a : b;
  
  // Données de test pour le développement
  List<dynamic> _getTestDeliveryPersons() {
    return [
      {
        '_id': 'L001',
        'name': 'Pierre Dubois',
        'phone': '+33 6 12 34 56 78',
        'email': 'pierre.dubois@example.com',
        'status': 'Disponible',
        'livraisons': 128,
        'rating': 4.8,
        'zone': 'Paris Centre',
        'vehicule': 'Vélo électrique',
        'photo': 'https://picsum.photos/200/300',
        'isActive': true,
      },
      {
        '_id': 'L002',
        'name': 'Marie Lambert',
        'phone': '+33 6 23 45 67 89',
        'email': 'marie.lambert@example.com',
        'status': 'En livraison',
        'livraisons': 95,
        'rating': 4.6,
        'zone': 'Paris Nord',
        'vehicule': 'Scooter',
        'photo': 'https://picsum.photos/200/300',
        'isActive': true,
      },
      {
        '_id': 'L003',
        'name': 'Julien Moreau',
        'phone': '+33 6 34 56 78 90',
        'email': 'julien.moreau@example.com',
        'status': 'Disponible',
        'livraisons': 210,
        'rating': 4.9,
        'zone': 'Paris Sud',
        'vehicule': 'Voiture électrique',
        'photo': 'https://picsum.photos/200/300',
        'isActive': true,
      },
      {
        '_id': 'L004',
        'name': 'Sophie Martin',
        'phone': '+33 6 45 67 89 01',
        'email': 'sophie.martin@example.com',
        'status': 'Inactif',
        'livraisons': 45,
        'rating': 4.2,
        'zone': 'Paris Ouest',
        'vehicule': 'Vélo',
        'photo': 'https://picsum.photos/200/300',
        'isActive': false,
      },
      {
        '_id': 'L005',
        'name': 'Antoine Legrand',
        'phone': '+33 6 56 78 90 12',
        'email': 'antoine.legrand@example.com',
        'status': 'En livraison',
        'livraisons': 173,
        'rating': 4.7,
        'zone': 'Paris Centre',
        'vehicule': 'Moto',
        'photo': 'https://picsum.photos/200/300',
        'isActive': true,
      },
    ];
  }

  // Récupérer les livreurs pour assigner à une commande
  Future<List<dynamic>> getLivreursForAssignment() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        print('❌ Token d\'authentification non trouvé');
        throw Exception('Authentification requise. Veuillez vous reconnecter.');
      }
      
      print('🔍 Récupération de tous les utilisateurs avec rôle livreur');
      
      // Récupérer tous les utilisateurs avec le rôle livreur - sans filtrer par disponibilité
      final response = await http.get(
        Uri.parse('$baseUrl/api/users?role=Livreur'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('📊 Statut de réponse: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        
        print('📦 Données reçues avec succès');
        
        List<dynamic> livreurs = [];
        
        // Adapter le parsing en fonction de la structure de réponse
        if (data is List) {
          // Filtrer pour ne garder que les utilisateurs avec rôle Livreur
          livreurs = data.where((user) => user['role'] == 'Livreur').toList();
        } else if (data['users'] != null) {
          // Filtrer pour ne garder que les utilisateurs avec rôle Livreur
          livreurs = (data['users'] as List).where((user) => user['role'] == 'Livreur').toList();
        } else {
          print('⚠️ Format de réponse inattendu, utilisation des données de test');
          return _getTestDeliveryPersons();
        }
        
        print('✅ ${livreurs.length} utilisateurs avec rôle livreur récupérés');
        
        // Transformer les données pour le format attendu dans l'UI
        return livreurs.map((user) => {
          '_id': user['_id'],
          'name': user['nom'] ?? '',
          'phone': user['telephone'] ?? '',
          'isActive': user['isActive'] ?? true,
          'status': user['isActive'] == true ? 'Disponible' : 'Indisponible',
        }).toList();
      } else {
        print('⚠️ Échec de récupération des utilisateurs, utilisation des données de test');
        return _getTestDeliveryPersons();
      }
    } catch (e) {
      print('❌ Exception lors de la récupération des livreurs: $e');
      print('⚠️ Utilisation des données de test');
      return _getTestDeliveryPersons();
    }
  }
} 