import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/api_config.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  bool _isLoading = true;
  User? _currentUser;
  String? _token;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  
  // Constructeur qui appelle le chargement de l'état d'authentification
  AuthProvider() {
    _loadAuthState();
  }

  // Charger l'état d'authentification au démarrage de l'application
  Future<void> _loadAuthState() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Obtenir le token via le service d'auth qui vérifie aussi sa validité
      final validToken = await _authService.getToken();
      
      if (validToken != null) {
        if (ApiConfig.enableDetailedLogs) {
          print('Token valide trouvé, vérification du rôle livreur');
        }
        
        // Vérifier que l'utilisateur est bien un livreur
        final isLivreur = await _authService.isAuthenticatedLivreur();
        
        if (isLivreur) {
          _token = validToken;
          _currentUser = await _authService.getCurrentUser();
          _isAuthenticated = true;
          
          if (ApiConfig.enableDetailedLogs) {
            print('Authentification réussie en tant que livreur: ${_currentUser?.nom}');
          }
        } else {
          if (ApiConfig.enableDetailedLogs) {
            print('Token valide mais utilisateur non livreur ou inactif');
          }
          
          _isAuthenticated = false;
          _currentUser = null;
          _token = null;
          _errorMessage = 'Accès non autorisé. Cette application est réservée aux livreurs.';
          
          // Nettoyer les données stockées
          await _authService.logout();
        }
      } else {
        if (ApiConfig.enableDetailedLogs) {
          print('Token invalide ou expiré, utilisateur non authentifié');
        }
        
        _isAuthenticated = false;
        _currentUser = null;
        _token = null;
      }
    } catch (e) {
      if (ApiConfig.enableDetailedLogs) {
        print('Erreur lors du chargement de l\'état d\'authentification: $e');
      }
      
      _errorMessage = 'Erreur lors de la vérification de l\'authentification';
      _isAuthenticated = false;
      _currentUser = null;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vérifier l'état d'authentification à la demande
  Future<bool> checkAuthentication() async {
    if (_isLoading) {
      // Attendre que le chargement initial soit terminé
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!_isAuthenticated) {
      // Tenter une vérification du token
      await _loadAuthState();
    }
    
    return _isAuthenticated;
  }

  // Connexion de l'utilisateur
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final response = await _authService.login(email, password);
      
      _token = response['token'];
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      
      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      _token = null;
      _errorMessage = e.toString();
      
      if (ApiConfig.enableDetailedLogs) {
        print('Erreur de connexion: $_errorMessage');
      }
      
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Déconnexion de l'utilisateur
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.logout();
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion: ${e.toString()}';
      
      if (ApiConfig.enableDetailedLogs) {
        print(_errorMessage);
      }
    } finally {
      _isAuthenticated = false;
      _currentUser = null;
      _token = null;
      _isLoading = false;
      
      notifyListeners();
    }
  }

  // Récupérer le token pour les requêtes API
  Future<String?> getToken() async {
    return await _authService.getToken();
  }
  
  // Raffraîchir les informations utilisateur
  Future<void> refreshUserInfo() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
      }
    } catch (e) {
      if (ApiConfig.enableDetailedLogs) {
        print('Erreur lors du rafraîchissement des informations utilisateur: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 