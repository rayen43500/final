import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      _isLoading = true;
      
      // Nettoyer les données utilisateur potentiellement corrompues
      final cleaned = await _authService.cleanupUserData();
      if (cleaned) {
        print('📝 Données utilisateur nettoyées');
      }
      
      // Obtenir le token via le service d'auth qui vérifie aussi sa validité
      final validToken = await _authService.getToken();
      final userStr = await _storage.read(key: 'user');
      
      if (validToken != null && userStr != null) {
        print('📝 Token valide trouvé, utilisateur authentifié');
        _token = validToken;
        _user = json.decode(userStr);
        _isAuthenticated = true;
      } else {
        print('📝 Token invalide ou expiré, utilisateur non authentifié');
        _isAuthenticated = false;
        _user = null;
        _token = null;
        
        // Nettoyer les données stockées si nécessaire
        if (validToken == null && await _storage.read(key: 'token') != null) {
          await _storage.delete(key: 'token');
          await _storage.delete(key: 'refreshToken');
          await _storage.delete(key: 'user');
        }
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'état d\'authentification: $e');
      _isAuthenticated = false;
      _user = null;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuthentication() async {
    if (_isLoading) {
      // Attendre que le chargement initial soit terminé
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!_isAuthenticated) {
      // Vérifier d'abord la connectivité au serveur
      final isServerReachable = await _authService.checkServerConnectivity();
      if (!isServerReachable) {
        print('📡 Serveur inaccessible, utilisation des données locales si disponibles');
        // Essayer de récupérer les informations utilisateur locales
        final userStr = await _storage.read(key: 'user');
        final token = await _storage.read(key: 'token');
        
        if (userStr != null && token != null) {
          try {
            _user = json.decode(userStr);
            _token = token;
            _isAuthenticated = true;
            notifyListeners();
            print('🔄 Authentification basée sur les données locales');
            return true;
          } catch (e) {
            print('❌ Erreur lors de la récupération des données locales: $e');
          }
        }
        return false;
      }
      
      // Tenter une vérification du token
      return await _loadAuthState().then((_) => _isAuthenticated);
    }
    
    return _isAuthenticated;
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _authService.login(email, password);
      
      _token = response['token'];
      _user = response['user'];
      _isAuthenticated = true;

      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'user', value: json.encode(_user));

      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      _token = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      _isAuthenticated = false;
      _user = null;
      _token = null;
      
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'user');
      
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name, String telephone) async {
    try {
      await _authService.register(email, password, name, telephone);
      // Ne pas connecter automatiquement l'utilisateur après l'inscription
      // L'utilisateur devra se connecter manuellement
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _authService.refreshToken(refreshToken);
      
      _token = response['token'];
      await _storage.write(key: 'token', value: _token);
      
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      _token = null;
      
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'refreshToken');
      await _storage.delete(key: 'user');
      
      notifyListeners();
      rethrow;
    }
  }
} 