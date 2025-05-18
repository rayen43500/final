import 'package:flutter/material.dart';
import '../services/category_service.dart';
import 'package:flutter/foundation.dart';

class CategoriePage extends StatefulWidget {
  const CategoriePage({super.key});

  @override
  State<CategoriePage> createState() => _CategoriePageState();
}

class _CategoriePageState extends State<CategoriePage> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _categories = [];
  String? _errorMessage;

  // Icônes pour les catégories
  final Map<String, IconData> iconMap = {
    'devices': Icons.devices,
    'headphones': Icons.headphones,
    'computer': Icons.computer,
    'watch': Icons.watch,
    'speaker': Icons.speaker,
    'home': Icons.home,
    'phone_android': Icons.phone_android,
    'tv': Icons.tv,
    'camera_alt': Icons.camera_alt,
    'videogame_asset': Icons.videogame_asset,
    'sports_esports': Icons.sports_esports,
    'memory': Icons.memory,
  };
  
  // Couleurs pour les catégories
  final Map<String, Color> colorMap = {
    'blue': Colors.blue,
    'red': Colors.red,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'teal': Colors.teal,
    'pink': Colors.pink,
    'amber': Colors.amber,
    'indigo': Colors.indigo,
    'cyan': Colors.cyan,
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoriesData = await _categoryService.getCategories();
      
      // Convertir les données du backend en format compatible avec l'interface
      final List<Map<String, dynamic>> formattedCategories = [];
      
      for (var category in categoriesData) {
        // Sélectionner une couleur par défaut basée sur le nom
        final colorName = category['colorName'] ?? _getDefaultColorName(category['nom']);
        final Color color = colorMap[colorName] ?? Colors.blue;
        
        // Sélectionner une icône par défaut basée sur le nom
        final iconName = category['iconName'] ?? _getDefaultIconName(category['nom']);
        final IconData icon = iconMap[iconName] ?? Icons.category;
        
        formattedCategories.add({
          'id': category['_id'],
          'nom': category['nom'],
          'description': category['description'] ?? 'Aucune description',
          'icon': icon,
          'iconName': iconName,
          'couleur': color,
          'colorName': colorName,
          'produits': category['productCount'] ?? 0,
          'actif': category['isActive'] ?? true,
          'slug': category['slug'],
          'parentCategory': category['parentCategory'],
        });
      }
      
      setState(() {
        _categories = formattedCategories;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des catégories: $e');
      }
      setState(() {
        _errorMessage = 'Impossible de charger les catégories. Veuillez réessayer.';
        _isLoading = false;
      });
    }
  }

  // Déterminer une couleur par défaut basée sur le nom de la catégorie
  String _getDefaultColorName(String categoryName) {
    final colorNames = colorMap.keys.toList();
    final nameHash = categoryName.hashCode.abs() % colorNames.length;
    return colorNames[nameHash];
  }
  
  // Déterminer une icône par défaut basée sur le nom de la catégorie
  String _getDefaultIconName(String categoryName) {
    final iconNames = iconMap.keys.toList();
    final nameHash = categoryName.hashCode.abs() % iconNames.length;
    return iconNames[nameHash];
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _categories.where((category) {
      return category['nom'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          category['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'Actualiser',
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une catégorie...',
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
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red.shade400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadCategories,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : filteredCategories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune catégorie trouvée',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCategories,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isSmallScreen ? 1 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isSmallScreen ? 2 : 1.5,
                              ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = filteredCategories[index];
                                return _buildCategoryCard(category, theme);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditCategoryDialog(context);
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, ThemeData theme) {
    final isActive = category['actif'];
    final color = category['couleur'];
    final iconData = category['icon'] as IconData;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showCategoryDetailDialog(context, category);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    radius: 24,
                    child: Icon(
                      iconData,
                      color: color,
                      size: 24,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showAddEditCategoryDialog(context, category: category);
                          } else if (value == 'toggle') {
                            await _toggleCategoryStatus(category);
                          } else if (value == 'delete') {
                            _showDeleteConfirmDialog(context, category);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  isActive ? Icons.toggle_off : Icons.toggle_on,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(isActive ? 'Désactiver' : 'Activer'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                category['nom'],
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                category['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category['produits']} produits',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleCategoryStatus(Map<String, dynamic> category) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Appeler l'API pour changer le statut
      await _categoryService.updateCategory(
        category['id'],
        {'actif': !category['actif']},
      );
      
      // Mettre à jour localement
      setState(() {
        final index = _categories.indexWhere((c) => c['id'] == category['id']);
        if (index != -1) {
          _categories[index]['actif'] = !category['actif'];
        }
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catégorie ${category['nom']} ${category['actif'] ? 'désactivée' : 'activée'}'),
            duration: const Duration(seconds: 2),
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
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCategoryDetailDialog(BuildContext context, Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category['nom']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category['description'],
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Slug',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category['slug'] ?? 'Non défini',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Statistiques',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nombre de produits:',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${category['produits']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Statut:',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  category['actif'] ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: category['actif'] ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
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
              _showAddEditCategoryDialog(context, category: category);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showAddEditCategoryDialog(BuildContext context, {Map<String, dynamic>? category}) {
    final isEditing = category != null;
    final TextEditingController nameController = TextEditingController(text: isEditing ? category['nom'] : '');
    final TextEditingController descriptionController = TextEditingController(text: isEditing ? category['description'] : '');
    bool isActive = isEditing ? category['actif'] : true;
    String selectedColorName = isEditing ? (category['colorName'] ?? 'blue') : 'blue';
    String selectedIconName = isEditing ? (category['iconName'] ?? 'category') : 'category';
    
    Color selectedColor = colorMap[selectedColorName] ?? Colors.blue;
    IconData selectedIcon = iconMap[selectedIconName] ?? Icons.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Modifier la catégorie' : 'Ajouter une catégorie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la catégorie',
                      hintText: 'Ex: Électronique',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Ex: Smartphones, tablettes et autres appareils électroniques',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text('Couleur'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: colorMap.entries.map((entry) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedColorName = entry.key;
                            selectedColor = entry.value;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: entry.value,
                          radius: 16,
                          child: selectedColorName == entry.key
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icône'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: iconMap.entries.map((entry) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedIconName = entry.key;
                            selectedIcon = entry.value;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedIconName == entry.key
                                ? selectedColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: selectedIconName == entry.key
                                ? Border.all(
                                    color: selectedColor,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            entry.value,
                            color: selectedIconName == entry.key ? selectedColor : Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Catégorie active'),
                    value: isActive,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          isActive = value;
                        });
                      }
                    },
                    contentPadding: EdgeInsets.zero,
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
                onPressed: () async {
                  // Valider et sauvegarder les changements
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Le nom de la catégorie est requis')),
                    );
                    return;
                  }

                  try {
                    setState(() {
                      _isLoading = true;
                    });

                    final categoryData = {
                      'nom': name,
                      'description': description,
                      'iconName': selectedIconName,
                      'colorName': selectedColorName,
                      'actif': isActive,
                    };

                    if (isEditing) {
                      // Mettre à jour la catégorie existante
                      await _categoryService.updateCategory(category!['id'], categoryData);
                      
                      // Mettre à jour localement
                      final index = _categories.indexWhere((c) => c['id'] == category['id']);
                      if (index != -1) {
                        _categories[index]['nom'] = name;
                        _categories[index]['description'] = description;
                        _categories[index]['iconName'] = selectedIconName;
                        _categories[index]['icon'] = selectedIcon;
                        _categories[index]['colorName'] = selectedColorName;
                        _categories[index]['couleur'] = selectedColor;
                        _categories[index]['actif'] = isActive;
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Catégorie mise à jour avec succès')),
                        );
                      }
                    } else {
                      // Ajouter une nouvelle catégorie
                      final newCategory = await _categoryService.createCategory(categoryData);
                      
                      // Ajouter à la liste locale
                      _categories.add({
                        'id': newCategory['_id'],
                        'nom': name,
                        'description': description,
                        'iconName': selectedIconName,
                        'icon': selectedIcon,
                        'colorName': selectedColorName,
                        'couleur': selectedColor,
                        'produits': 0,
                        'actif': isActive,
                        'slug': newCategory['slug'],
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Catégorie ajoutée avec succès')),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la catégorie "${category['nom']}" ? Cette action est irréversible et supprimera également tous les liens avec les produits associés.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                setState(() {
                  _isLoading = true;
                });
                
                // Appeler l'API pour supprimer la catégorie
                await _categoryService.deleteCategory(category['id']);
                
                // Mettre à jour localement
                setState(() {
                  _categories.removeWhere((item) => item['id'] == category['id']);
                  _isLoading = false;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Catégorie "${category['nom']}" supprimée'),
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
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
}
