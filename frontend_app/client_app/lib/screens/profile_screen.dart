import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart' as theme;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  late TabController _tabController;
  
  // Contrôleurs pour l'édition du profil
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Contrôleurs pour le changement de mot de passe
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Clés pour les formulaires
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  
  // Pour cacher/montrer les mots de passe
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    
    // Vérifier la connectivité au serveur
    _checkServerConnectivity();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si nous sommes en mode hors ligne
      final isOffline = await _authService.isOfflineMode();
      if (isOffline) {
        print('Application en mode hors ligne');
        await _authService.updateUserMode('hors_ligne');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mode hors ligne activé - Les modifications seront sauvegardées localement'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Détails',
                onPressed: () {
                  _showApiConfigDialog();
                },
              ),
            ),
          );
        }
      } else {
        print('Application en mode connecté');
        await _authService.updateUserMode('connecté');
      }
      
      final userData = await _authService.getCurrentUser();
      
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de récupérer vos informations. Utilisation du mode hors ligne.'),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Créer un profil utilisateur minimal au lieu de rediriger vers la connexion
          final offlineData = {
            '_id': 'offline_user',
            'nom': 'Utilisateur',
            'email': 'utilisateur@example.com',
            'telephone': '',
            'adresse': '',
            'mode': 'hors_ligne'
          };
          
          setState(() {
            _userData = offlineData;
            _isLoading = false;
          });
          
          // Initialiser les contrôleurs avec les données minimales
          _nameController.text = 'Utilisateur';
          _emailController.text = 'utilisateur@example.com';
          _phoneController.text = '';
          _addressController.text = '';
          
          return;
        }
      } else {
        // Vérifier spécifiquement si l'ID utilisateur est disponible
        if (userData['_id'] == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Données utilisateur incomplètes. Mode hors ligne activé.'),
                backgroundColor: Colors.orange,
              ),
            );
            
            // Créer un profil utilisateur minimal avec les données disponibles
            final minimalUserData = {
              '_id': 'offline_user',
              'nom': userData['nom'] ?? 'Utilisateur',
              'email': userData['email'] ?? 'utilisateur@example.com',
              'telephone': userData['telephone'] ?? '',
              'adresse': userData['adresse'] ?? '',
              'mode': 'hors_ligne'
            };
            
            setState(() {
              _userData = minimalUserData;
              _isLoading = false;
            });
            
            // Initialiser les contrôleurs avec les données disponibles
            _nameController.text = (minimalUserData['nom'] ?? '').toString();
            _emailController.text = (minimalUserData['email'] ?? '').toString();
            _phoneController.text = (minimalUserData['telephone'] ?? '').toString();
            _addressController.text = (minimalUserData['adresse'] ?? '').toString();
            
            return;
          }
        } else {
          setState(() {
            _userData = userData;
            _isLoading = false;
          });
          
          // Initialiser les contrôleurs avec les données utilisateur
          _nameController.text = (userData['nom'] ?? '').toString();
          _emailController.text = (userData['email'] ?? '').toString();
          _phoneController.text = (userData['telephone'] ?? '').toString();
          _addressController.text = (userData['adresse'] ?? '').toString();
        }
      }
    } catch (e) {
      print('Erreur lors du chargement du profil: $e');
      
      // Créer un profil utilisateur minimal en cas d'erreur
      final offlineUserData = {
        '_id': 'offline_user',
        'nom': 'Utilisateur (hors ligne)',
        'email': 'utilisateur@example.com',
        'telephone': '',
        'adresse': '',
        'mode': 'erreur'
      };
      
      setState(() {
        _userData = offlineUserData;
        _isLoading = false;
      });
      
      // Initialiser les contrôleurs avec les données minimales
      _nameController.text = 'Utilisateur (hors ligne)';
      _emailController.text = 'utilisateur@example.com';
      _phoneController.text = '';
      _addressController.text = '';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode hors ligne activé suite à une erreur: ${e.toString().split(':').first}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _userData?['_id'];
      if (userId == null) {
        // Au lieu de lever une exception, afficher un message et essayer de récupérer les informations utilisateur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID utilisateur non disponible. Tentative de récupération des informations...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        // Tenter de recharger les données utilisateur
        await _loadUserData();
        
        // Vérifier à nouveau si l'ID est disponible
        if (_userData?['_id'] == null) {
          throw Exception('Impossible de récupérer l\'ID utilisateur. Veuillez vous reconnecter.');
        }
      }
      
      final userData = {
        'nom': _nameController.text,
        'telephone': _phoneController.text,
        'adresse': _addressController.text,
      };
      
      // Vérifier si nous sommes en mode hors ligne
      if (_userData?['mode'] == 'hors_ligne' || _userData?['mode'] == 'anonyme' || _userData?['mode'] == 'erreur') {
        // En mode hors ligne, mettre à jour uniquement les données locales
        final updatedUserData = await _authService.updateUserDataLocally(userData);
        
        setState(() {
          _userData = updatedUserData;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour localement (mode hors ligne)'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }
      
      // Mode en ligne - essayer de mettre à jour via l'API
      final updatedUser = await _authService.updateUserProfile(_userData!['_id'], userData);
      
      setState(() {
        _userData = updatedUser;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // En cas d'erreur, essayer de mettre à jour localement
      try {
        final userData = {
          'nom': _nameController.text,
          'telephone': _phoneController.text,
          'adresse': _addressController.text,
        };
        
        final updatedUserData = await _authService.updateUserDataLocally(userData);
        
        setState(() {
          _userData = updatedUserData;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profil mis à jour localement (erreur de connexion: ${e.toString().split(':').first})'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (localError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la mise à jour du profil: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }
    
    // Vérifier que les nouveaux mots de passe correspondent
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les nouveaux mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _userData?['_id'];
      if (userId == null) {
        // Au lieu de lever une exception, afficher un message et essayer de récupérer les informations utilisateur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID utilisateur non disponible. Tentative de récupération des informations...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        // Tenter de recharger les données utilisateur
        await _loadUserData();
        
        // Vérifier à nouveau si l'ID est disponible
        if (_userData?['_id'] == null) {
          throw Exception('Impossible de récupérer l\'ID utilisateur. Veuillez vous reconnecter.');
        }
      }
      
      final success = await _authService.changePassword(
        _userData!['_id'],
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success && mounted) {
        // Réinitialiser les champs
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
        );
      }
    }
  }

  Future<void> _checkServerConnectivity() async {
    final isConnected = await _authService.checkServerConnectivity();
    if (!isConnected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de se connecter au serveur. Mode hors ligne activé.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Détails',
            onPressed: () {
              _showApiConfigDialog();
            },
          ),
        ),
      );
    }
  }
  
  void _showApiConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configuration de l\'API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL actuelle: ${_authService.baseUrl}'),
            SizedBox(height: 10),
            Text('Si vous avez des problèmes de connexion:'),
            SizedBox(height: 5),
            Text('1. Vérifiez que le serveur est en cours d\'exécution'),
            Text('2. Vérifiez que l\'URL est correcte'),
            Text('3. Vérifiez votre connexion internet'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Méthode pour tenter de se reconnecter au serveur
  Future<void> _attemptReconnection() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Vérifier la connectivité au serveur
      final isConnected = await _authService.checkServerConnectivity();
      
      if (isConnected) {
        // Mettre à jour le mode
        await _authService.updateUserMode('connecté');
        
        // Recharger les données utilisateur
        await _loadUserData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion au serveur établie avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible de se connecter au serveur'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Détails',
                onPressed: () {
                  _showApiConfigDialog();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la tentative de reconnexion: ${e.toString().split(':').first}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Sécurité'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _userData == null
          ? const Center(child: Text('Veuillez vous connecter pour voir votre profil'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildSecurityTab(),
              ],
            ),
    );
  }
  
  Widget _buildProfileTab() {
    final bool isOfflineMode = _userData?['mode'] == 'hors_ligne' || 
                              _userData?['mode'] == 'anonyme' || 
                              _userData?['mode'] == 'erreur';
    
    return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // En-tête du profil avec avatar
                  Center(
                    child: Column(
                      children: [
                Stack(
                  children: [
                    CircleAvatar(
                          radius: 50,
                      backgroundColor: theme.AppTheme.primaryColor,
                      child: Text(
                        (_userData?['nom'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isOfflineMode)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.cloud_off,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userData?['nom'] ?? 'Utilisateur',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          _userData?['email'] ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                if (isOfflineMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                        Text(
                                'Mode hors ligne',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isLoading ? null : _attemptReconnection,
                          icon: Icon(Icons.refresh, size: 16),
                          label: Text('Tenter de se reconnecter'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
          
          // Formulaire d'édition du profil
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _profileFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Informations personnelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        if (isOfflineMode)
                          Tooltip(
                            message: 'Les modifications seront sauvegardées localement',
                            child: Icon(Icons.info_outline, color: Colors.orange),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // L'email ne peut pas être modifié
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.AppTheme.primaryColor,
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Enregistrer les modifications'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Options supplémentaires
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                  ListTile(
                  leading: const Icon(Icons.shopping_bag, color: theme.AppTheme.primaryColor),
                    title: const Text('Mes commandes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                    Navigator.pushNamed(context, '/orders');
                    },
                  ),
                const Divider(height: 1),
                  ListTile(
                  leading: const Icon(Icons.location_on, color: theme.AppTheme.primaryColor),
                  title: const Text('Mes adresses de livraison'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité à venir')),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bouton de déconnexion
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Déconnexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Changer votre mot de passe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pour protéger votre compte, utilisez un mot de passe fort et unique',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                    },
                  ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: _obscureCurrentPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre mot de passe actuel';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: _obscureNewPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nouveau mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                    },
                  ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez confirmer votre nouveau mot de passe';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.AppTheme.primaryColor,
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text('Mettre à jour le mot de passe'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Informations de sécurité supplémentaires
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conseils de sécurité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSecurityTip(
                    icon: Icons.lock,
                    title: 'Mot de passe fort',
                    description: 'Utilisez une combinaison de lettres, chiffres et caractères spéciaux',
                  ),
                  const SizedBox(height: 12),
                  _buildSecurityTip(
                    icon: Icons.refresh,
                    title: 'Changement régulier',
                    description: 'Changez votre mot de passe périodiquement pour plus de sécurité',
                          ),
                  const SizedBox(height: 12),
                  _buildSecurityTip(
                    icon: Icons.devices,
                    title: 'Appareils connectés',
                    description: 'Déconnectez-vous des appareils publics après utilisation',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 