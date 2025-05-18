import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/promotion_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../models/promotion_model.dart';
import 'add_promotion.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  final _authService = AuthService();
  final _promotionService = PromotionService();
  final _productService = ProductService();
  final _categoryService = CategoryService();
  
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedType = 'Tous';
  final List<String> _typeOptions = ['Tous', 'pourcentage', 'montant', 'livraison'];
  
  List<Promotion> _promotions = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null || currentUser['role'] != 'Admin') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous n\'avez pas les droits d\'administrateur nécessaires pour accéder à cette page')),
        );
        Navigator.of(context).pop();
      }
      return;
    }
    _loadPromotions();
  }

  // Charger les promotions depuis le backend
  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _promotionService.getAllPromotions();
      List<Promotion> promotions = data
          .map((item) => Promotion.fromJson(item))
          .toList();
      
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  // Chargement des produits 
  Future<void> _loadProducts() async {
    try {
      final response = await _productService.getProducts(limit: 100);
      setState(() {
        _products = List<Map<String, dynamic>>.from(response['products']);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des produits: $e')),
        );
      }
    }
  }

  // Chargement des catégories
  Future<void> _loadCategories() async {
    try {
      final data = await _categoryService.getCategories();
      setState(() {
        _categories = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des catégories: $e')),
        );
      }
    }
  }

  // Suppression d'une promotion
  Future<void> _deletePromotion(String id) async {
    try {
      final result = await _promotionService.deletePromotion(id);
      if (result) {
        setState(() {
          _promotions.removeWhere((promo) => promo.id == id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promotion supprimée avec succès')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  // Toggle l'état actif d'une promotion
  Future<void> _togglePromotionStatus(Promotion promo) async {
    try {
      final updatedPromo = await _promotionService.updatePromotion(
        promo.id,
        {'isActive': !promo.isActive},
      );
      
      setState(() {
        final index = _promotions.indexWhere((p) => p.id == promo.id);
        if (index != -1) {
          _promotions[index] = Promotion.fromJson(updatedPromo);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promotion ${updatedPromo['isActive'] ? 'activée' : 'désactivée'} avec succès',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  // Navigation vers la page d'ajout de promotion
  Future<void> _navigateToAddPromotion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPromotionPage()),
    );
    
    if (result == true) {
      _loadPromotions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPromotions = _promotions.where((promo) {
      final matchesType = _selectedType == 'Tous' || promo.typeReduction == _selectedType;
      final matchesSearch = (promo.codePromo?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
          (promo.description?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
          promo.nom.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des promotions'),
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
                    hintText: 'Rechercher une promotion...',
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
                    itemCount: _typeOptions.length,
                    itemBuilder: (context, index) {
                      final type = _typeOptions[index];
                      final isSelected = type == _selectedType;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedType = type;
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
                : filteredPromotions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune promotion trouvée',
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
                        itemCount: filteredPromotions.length,
                        itemBuilder: (context, index) {
                          final promo = filteredPromotions[index];
                          return _buildPromoCard(promo, theme, isSmallScreen);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPromotion,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPromoCard(Promotion promo, ThemeData theme, bool isSmallScreen) {
    final bool isActive = promo.isActive;
    final now = DateTime.now();
    final dateDebut = promo.dateDebut;
    final dateFin = promo.dateFin;
    final bool isExpired = dateFin.isBefore(now);
    final bool isUpcoming = dateDebut.isAfter(now);
    
    Color statusColor;
    String statusText;
    
    if (!isActive) {
      statusColor = Colors.grey;
      statusText = 'Inactif';
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expiré';
    } else if (isUpcoming) {
      statusColor = Colors.orange;
      statusText = 'À venir';
    } else {
      statusColor = Colors.green;
      statusText = 'Actif';
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo.description ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPromoDetails(promo, theme),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Utilisations: ${promo.utilisations}/${promo.limiteUtilisations}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        // Logique pour modifier la promotion
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off),
                      onPressed: () {
                        _togglePromotionStatus(promo);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: isActive ? theme.colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        _showDeleteConfirmation(promo);
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

  void _showDeleteConfirmation(Promotion promo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la promotion "${promo.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePromotion(promo.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoDetails(Promotion promo, ThemeData theme) {
    Color typeColor;
    IconData typeIcon;

    switch (promo.typeReduction) {
      case 'pourcentage':
        typeColor = Colors.blue;
        typeIcon = Icons.percent;
        break;
      case 'montant':
        typeColor = Colors.green;
        typeIcon = Icons.euro;
        break;
      case 'livraison':
        typeColor = Colors.orange;
        typeIcon = Icons.local_shipping;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.tag;
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        Chip(
          avatar: Icon(
            typeIcon,
            size: 16,
            color: typeColor,
          ),
          label: Text(
            '${promo.typeReduction} ${promo.typeReduction == 'pourcentage' ? '${promo.valeurReduction}%' : promo.typeReduction == 'montant' ? '${promo.valeurReduction}DT' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          backgroundColor: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Chip(
          avatar: Icon(
            Icons.date_range,
            size: 16,
            color: Colors.purple,
          ),
          label: Text(
            '${promo.dateDebutFormatted} - ${promo.dateFinFormatted}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          backgroundColor: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  DateTime _parseDate(String date) {
    try {
      final parts = date.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      // Fallback for when the date is already a DateTime
      return DateTime.now();
    }
  }
}
