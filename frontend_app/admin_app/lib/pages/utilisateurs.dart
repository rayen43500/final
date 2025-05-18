import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class UtilisateursPage extends StatefulWidget {
  const UtilisateursPage({super.key});

  @override
  State<UtilisateursPage> createState() => _UtilisateursPageState();
}

class _UtilisateursPageState extends State<UtilisateursPage> {
  final _authService = AuthService();
  final _userService = UserService();
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'Tous';
  final List<String> _roles = ['Tous', 'Admin', 'Client'];

  List<User> _utilisateurs = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }
  
  // Récupérer tous les utilisateurs
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final usersData = await _userService.getAllUsers();
      
      setState(() {
        _utilisateurs = usersData.map((json) => User.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des utilisateurs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _utilisateurs.where((user) {
      final matchesRole = _selectedRole == 'Tous' || user.role == _selectedRole;
      final matchesSearch = user.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton de rafraîchissement
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
            tooltip: 'Rafraîchir',
          ),
        ],
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
                    hintText: 'Rechercher un utilisateur...',
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
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      final isSelected = role == _selectedRole;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(role),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedRole = role;
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun utilisateur trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserCard(user, theme, isSmallScreen);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditUserDialog(context);
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserCard(User user, ThemeData theme, bool isSmallScreen) {
    // Couleur basée sur le statut
    final isActive = user.isActive;
    final statusColor = isActive ? Colors.green : Colors.red;
    final roleColor = user.role == 'Admin' ? Colors.deepPurple : Colors.blue;

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
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    _getInitials(user.nom),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                              user.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.role,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: roleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user.telephone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
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
                  Icons.calendar_today,
                  'Inscrit le',
                  user.dateInscription,
                ),
                _buildInfoItem(
                  Icons.shopping_cart,
                  'Commandes',
                  user.commandes.toString(),
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () {
                        _showUserDetailsDialog(context, user);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        _showAddEditUserDialog(context, user: user);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.block_outlined),
                      onPressed: () {
                        _toggleUserStatus(user);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: isActive ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        _showDeleteConfirmationDialog(user);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.red,
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

  void _toggleUserStatus(User user) {
    final newStatus = !user.isActive;
    
    // Montrer un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Appeler l'API
    _userService.toggleUserStatus(user.id, newStatus)
      .then((_) {
        // Fermer l'indicateur de chargement
        Navigator.pop(context);
        
        // Mettre à jour l'interface
        setState(() {
          final index = _utilisateurs.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _utilisateurs[index] = user.copyWith(
              isActive: newStatus,
              status: newStatus ? 'Actif' : 'Inactif'
            );
          }
        });
        
        // Afficher un message de confirmation
        final statusText = newStatus ? 'activé' : 'désactivé';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.nom} est maintenant $statusText'),
            backgroundColor: newStatus ? Colors.green : Colors.red,
          ),
        );
      })
      .catchError((error) {
        // Fermer l'indicateur de chargement
        Navigator.pop(context);
        
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
  }

  void _showUserDetailsDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de ${user.nom}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('ID', user.id),
              _buildDetailItem('Nom', user.nom),
              _buildDetailItem('Email', user.email),
              _buildDetailItem('Téléphone', user.telephone),
              _buildDetailItem('Adresse', user.adresse),
              _buildDetailItem('Date d\'inscription', user.dateInscription),
              _buildDetailItem('Rôle', user.role),
              _buildDetailItem('Statut', user.status),
              _buildDetailItem('Actif', user.isActive ? 'Oui' : 'Non'),
              _buildDetailItem('Vérifié', user.isVerified ? 'Oui' : 'Non'),
              _buildDetailItem('Nombre de commandes', user.commandes.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditUserDialog(context, user: user);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditUserDialog(BuildContext context, {User? user}) {
    final isEditing = user != null;
    
    // Si on édite, on initialise avec les valeurs existantes
    final TextEditingController nameController = TextEditingController(text: isEditing ? user.nom : '');
    final TextEditingController emailController = TextEditingController(text: isEditing ? user.email : '');
    final TextEditingController phoneController = TextEditingController(text: isEditing ? user.telephone : '');
    final TextEditingController addressController = TextEditingController(text: isEditing ? user.adresse : '');
    
    String selectedRole = isEditing ? user.role : 'Client';
    bool isActive = isEditing ? user.isActive : true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifier l\'utilisateur' : 'Ajouter un utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Ex: exemple@gmail.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: 'Ex: +216________',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    hintText: 'Ex: TUNIS',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                  ),
                  items: ['Admin', 'Client'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Compte actif'),
                  value: isActive,
                  onChanged: (value) {
                    if (value != null) {
                      isActive = value;
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Vérifier les champs obligatoires
                if (nameController.text.isEmpty || emailController.text.isEmpty || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs obligatoires'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Fermer le dialogue
                Navigator.pop(context);
                
                // Montrer un indicateur de chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                // Préparer les données
                final userData = {
                  'nom': nameController.text,
                  'email': emailController.text,
                  'telephone': phoneController.text,
                  'adresse': addressController.text,
                  'role': selectedRole,
                  'isActive': isActive,
                };
                
                // Appeler l'API
                if (isEditing) {
                  // Mettre à jour l'utilisateur existant
                  _userService.updateUser(user.id, userData)
                    .then((updatedUser) {
                      // Fermer l'indicateur de chargement
                      Navigator.pop(context);
                      
                      // Mettre à jour l'interface
                      setState(() {
                        final index = _utilisateurs.indexWhere((u) => u.id == user.id);
                        if (index != -1) {
                          _utilisateurs[index] = User.fromJson(updatedUser);
                        }
                      });
                      
                      // Afficher un message de confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Utilisateur mis à jour avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    })
                    .catchError((error) {
                      // Fermer l'indicateur de chargement
                      Navigator.pop(context);
                      
                      // Afficher un message d'erreur
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                } else {
                  // Ajouter un nouvel utilisateur
                  _userService.createUser(userData)
                    .then((newUser) {
                      // Fermer l'indicateur de chargement
                      Navigator.pop(context);
                      
                      // Mettre à jour l'interface
                      setState(() {
                        _utilisateurs.add(User.fromJson(newUser));
                      });
                      
                      // Afficher un message de confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Utilisateur créé avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    })
                    .catchError((error) {
                      // Fermer l'indicateur de chargement
                      Navigator.pop(context);
                      
                      // Afficher un message d'erreur
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                }
              },
              child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDeleteConfirmationDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur ${user.nom} ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Montrer un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Appeler l'API
              _userService.deleteUser(user.id)
                .then((_) {
                  // Fermer l'indicateur de chargement
                  Navigator.pop(context);
                  
                  // Mettre à jour l'interface
                  setState(() {
                    _utilisateurs.removeWhere((u) => u.id == user.id);
                  });
                  
                  // Afficher un message de confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.nom} a été supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                })
                .catchError((error) {
                  // Fermer l'indicateur de chargement
                  Navigator.pop(context);
                  
                  // Afficher un message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}';
    } else if (name.length >= 2) {
      return name.substring(0, 2);
    } else {
      return name;
    }
  }
}
