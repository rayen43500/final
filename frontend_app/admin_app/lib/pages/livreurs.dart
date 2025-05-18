import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/delivery_service.dart';
import '../models/delivery_person_model.dart';

class LivreursPage extends StatefulWidget {
  const LivreursPage({super.key});

  @override
  State<LivreursPage> createState() => _LivreursPageState();
}

class _LivreursPageState extends State<LivreursPage> {
  final _authService = AuthService();
  final _deliveryService = DeliveryService();
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'Tous';
  final List<String> _statusOptions = ['Tous', 'Disponible', 'En livraison', 'Inactif'];

  List<DeliveryPerson> _livreurs = [];

  @override
  void initState() {
    super.initState();
    _fetchLivreurs();
  }
  
  // Récupérer tous les livreurs
  Future<void> _fetchLivreurs() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Essayer d'abord la méthode getUsersWithRoleLivreur pour récupérer uniquement les utilisateurs livreurs
      final livreursData = await _deliveryService.getUsersWithRoleLivreur();
      
      setState(() {
        _livreurs = livreursData.map((json) => DeliveryPerson.fromJson(json)).toList();
        _isLoading = false;
      });
      
      if (_livreurs.isEmpty) {
        // Si aucun livreur n'est trouvé avec la première méthode, afficher un message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun livreur trouvé. Vous pouvez en ajouter un en cliquant sur le bouton +'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Si la première méthode échoue, essayer getAllDeliveryPersons
      try {
        final livreursData = await _deliveryService.getAllDeliveryPersons();
        
        setState(() {
          _livreurs = livreursData.map((json) => DeliveryPerson.fromJson(json)).toList();
          _isLoading = false;
        });
        
        if (_livreurs.isEmpty) {
          // Si aucun livreur n'est trouvé avec la deuxième méthode non plus, afficher un message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun livreur trouvé. Vous pouvez en ajouter un en cliquant sur le bouton +'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e2) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des livreurs: $e2'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLivreurs = _livreurs.where((livreur) {
      final matchesStatus = _selectedStatus == 'Tous' || livreur.status == _selectedStatus;
      final matchesSearch = livreur.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          livreur.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des livreurs'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un livreur...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusOptions.length,
                    itemBuilder: (context, index) {
                      final status = _statusOptions[index];
                      final isSelected = status == _selectedStatus;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStatus = status;
                              });
                            }
                          },
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLivreurs,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLivreurs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delivery_dining_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun livreur trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLivreurs.length,
                        itemBuilder: (context, index) {
                          final livreur = filteredLivreurs[index];
                          return _buildLivreurCard(livreur, theme, isSmallScreen);
                        },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddLivreurDialog();
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Dialogue pour ajouter un nouveau livreur
  void _showAddLivreurDialog() {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    String email = '';
    String telephone = '';
    String password = '';
    String confirmPassword = '';
    String zone = '';
    String vehicule = '';
    bool showPassword = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Créer un compte livreur'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Informations de base
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nom complet',
                          icon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          nom = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          icon: Icon(Icons.email),
                          hintText: 'Ex: exemple@gmail.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un email';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          email = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          icon: Icon(Icons.phone),
                          hintText: 'Ex: +216________',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un numéro de téléphone';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          telephone = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Informations complémentaires
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Zone de livraison',
                          icon: Icon(Icons.location_on),
                          hintText: 'Ex: Gabes',
                        ),
                        onSaved: (value) {
                          zone = value ?? '';
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Véhicule',
                          icon: Icon(Icons.directions_bike),
                          hintText: 'Ex: Voiture...',
                        ),
                        onSaved: (value) {
                          vehicule = value ?? '';
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Informations de compte
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Informations de connexion',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          icon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: !showPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un mot de passe';
                          }
                          if (value.length < 8) {
                            return 'Le mot de passe doit contenir au moins 8 caractères';
                          }
                          // Vérifier que le mot de passe contient au moins une lettre majuscule, une lettre minuscule, un chiffre et un caractère spécial
                          final hasUppercase = value.contains(RegExp(r'[A-Z]'));
                          final hasLowercase = value.contains(RegExp(r'[a-z]'));
                          final hasDigits = value.contains(RegExp(r'[0-9]'));
                          final hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
                          
                          if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
                            return 'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial';
                          }
                          
                          return null;
                        },
                        onSaved: (value) {
                          password = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          icon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: !showPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez confirmer le mot de passe';
                          }
                          // Nous utiliserons un contrôleur d'édition pour valider que les deux mots de passe sont identiques
                          return null;
                        },
                        onSaved: (value) {
                          confirmPassword = value!;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      
                      // Vérifier que les mots de passe correspondent
                      if (password != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Les mots de passe ne correspondent pas'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      try {
                        Navigator.of(context).pop();
                        
                        // Afficher un indicateur de chargement
                        setState(() {
                          _isLoading = true;
                        });
                        
                        final livreurData = {
                          'nom': nom,
                          'email': email,
                          'telephone': telephone,
                          'password': password,
                          'role': 'Livreur',
                          'zone': zone,
                          'vehicule': vehicule,
                        };
                        
                        // Utiliser le service pour créer un livreur
                        await _deliveryService.createDeliveryPerson(livreurData);
                        
                        // Recharger la liste des livreurs
                        await _fetchLivreurs();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Compte livreur créé avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la création du compte livreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Créer le compte'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildLivreurCard(DeliveryPerson livreur, ThemeData theme, bool isSmallScreen) {
    Color statusColor;
    switch (livreur.status) {
      case 'Disponible':
        statusColor = Colors.green;
        break;
      case 'En livraison':
        statusColor = Colors.blue;
        break;
      case 'Inactif':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(livreur.photo),
                  onBackgroundImageError: (_, __) {},
                  child: Container(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              livreur.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              livreur.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            livreur.zone.isNotEmpty ? livreur.zone : 'Non définie',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.directions_bike_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            livreur.vehicule.isNotEmpty ? livreur.vehicule : 'Non défini',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  Icons.delivery_dining,
                  'Livraisons',
                  livreur.livraisons.toString(),
                ),
                _buildInfoItem(
                  Icons.star,
                  'Évaluation',
                  '${livreur.rating} / 5',
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {
                        // Ouvrir l'application téléphone avec le numéro précomposé
                        // On simule juste une action pour le moment
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Appel à ${livreur.nom} (${livreur.telephone})'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        _showEditLivreurDialog(livreur);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade700,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (value) async {
                        if (value == 'toggle_status') {
                          await _toggleLivreurStatus(livreur);
                        } else if (value == 'delete') {
                          await _deleteLivreur(livreur);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Row(
                            children: [
                              Icon(
                                livreur.isActive ? Icons.person_off : Icons.person,
                                color: livreur.isActive ? Colors.red : Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(livreur.isActive ? 'Désactiver' : 'Activer'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Supprimer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Dialogue pour modifier un livreur
  void _showEditLivreurDialog(DeliveryPerson livreur) {
    final formKey = GlobalKey<FormState>();
    String nom = livreur.nom;
    String email = livreur.email;
    String telephone = livreur.telephone;
    String zone = livreur.zone;
    String vehicule = livreur.vehicule;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier ${livreur.nom}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: nom,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      icon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      nom = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      icon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un email';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      email = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: telephone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      icon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un numéro de téléphone';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      telephone = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: zone,
                    decoration: const InputDecoration(
                      labelText: 'Zone',
                      icon: Icon(Icons.location_on),
                    ),
                    onSaved: (value) {
                      zone = value ?? '';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: vehicule,
                    decoration: const InputDecoration(
                      labelText: 'Véhicule',
                      icon: Icon(Icons.directions_bike),
                    ),
                    onSaved: (value) {
                      vehicule = value ?? '';
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  
                  try {
                    Navigator.of(context).pop();
                    
                    // Afficher un indicateur de chargement
                    setState(() {
                      _isLoading = true;
                    });
                    
                    final livreurData = {
                      'nom': nom,
                      'email': email,
                      'telephone': telephone,
                      'zone': zone,
                      'vehicule': vehicule,
                    };
                    
                    await _deliveryService.updateDeliveryPerson(livreur.id, livreurData);
                    
                    // Recharger la liste des livreurs
                    await _fetchLivreurs();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Livreur mis à jour avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    setState(() {
                      _isLoading = false;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la mise à jour du livreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        );
      },
    );
  }
  
  // Activer/désactiver un livreur
  Future<void> _toggleLivreurStatus(DeliveryPerson livreur) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final newStatus = !livreur.isActive;
      
      await _deliveryService.updateDeliveryPerson(
        livreur.id,
        {'isActive': newStatus},
      );
      
      // Recharger la liste des livreurs
      await _fetchLivreurs();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Livreur ${newStatus ? 'activé' : 'désactivé'} avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du changement de statut: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Supprimer un livreur
  Future<void> _deleteLivreur(DeliveryPerson livreur) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le livreur ${livreur.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        await _deliveryService.deleteDeliveryPerson(livreur.id);
        
        // Recharger la liste des livreurs
        await _fetchLivreurs();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livreur supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression du livreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
