import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/promotion_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../models/promotion_model.dart';
import '../services/auth_service.dart';

class AddPromotionPage extends StatefulWidget {
  const AddPromotionPage({super.key});

  @override
  State<AddPromotionPage> createState() => _AddPromotionPageState();
}

class _AddPromotionPageState extends State<AddPromotionPage> {
  final _formKey = GlobalKey<FormState>();
  final _promotionService = PromotionService();
  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Form fields
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codePromoController = TextEditingController();
  final _valeurReductionController = TextEditingController();
  
  String _selectedType = 'produit';
  String _selectedTypeReduction = 'pourcentage';
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 7));
  String? _selectedTargetId;
  String? _selectedTargetName;
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _codePromoController.dispose();
    _valeurReductionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load products and categories in parallel
      final productsFuture = _productService.getProducts(limit: 100);
      final categoriesFuture = _categoryService.getCategories();
      
      final results = await Future.wait([productsFuture, categoriesFuture]);
      
      setState(() {
        final productsResponse = results[0] as Map<String, dynamic>;
        _products = List<Map<String, dynamic>>.from(productsResponse['products']);
        _categories = List<Map<String, dynamic>>.from(results[1] as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _dateDebut : _dateFin,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
          // Ensure end date is after start date
          if (_dateFin.isBefore(_dateDebut)) {
            _dateFin = _dateDebut.add(const Duration(days: 1));
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }
  
  Future<void> _selectTarget(BuildContext context) async {
    final List<Map<String, dynamic>> items = _selectedType == 'produit' 
        ? _products 
        : _categories;
    
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucun ${_selectedType == 'produit' ? 'produit' : 'catégorie'} disponible')),
      );
      return;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sélectionner un ${_selectedType == 'produit' ? 'produit' : 'catégorie'}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['nom'] ?? 'Sans nom'),
                subtitle: Text(item['description'] ?? ''),
                onTap: () => Navigator.of(context).pop(item),
              );
            },
          ),
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedTargetId = result['_id'];
        _selectedTargetName = result['nom'];
      });
    }
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedTargetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une cible')),
      );
      return;
    }
    
    // Check if user has admin privileges
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null || currentUser['role'] != 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous n\'avez pas les droits d\'administrateur nécessaires pour créer une promotion')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final promotionData = {
        'nom': _nomController.text,
        'description': _descriptionController.text,
        'type': _selectedType,
        'cible': _selectedTargetId,
        'typeReduction': _selectedTypeReduction,
        'valeurReduction': double.parse(_valeurReductionController.text),
        'dateDebut': _dateDebut.toIso8601String(),
        'dateFin': _dateFin.toIso8601String(),
        'codePromo': _codePromoController.text.isNotEmpty ? _codePromoController.text.toUpperCase() : null,
        'isActive': true,
      };
      
      await _promotionService.createPromotion(promotionData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion créée avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création de la promotion: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une promotion'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations de base',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la promotion',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codePromoController,
                      decoration: const InputDecoration(
                        labelText: 'Code promo (optionnel)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: SUMMER2023',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Type de promotion',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'produit',
                          child: Text('Produit'),
                        ),
                        DropdownMenuItem(
                          value: 'categorie',
                          child: Text('Catégorie'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                            _selectedTargetId = null;
                            _selectedTargetName = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectTarget(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Cible',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTargetName ?? 'Sélectionner',
                              style: TextStyle(
                                color: _selectedTargetName == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Réduction',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTypeReduction,
                      decoration: const InputDecoration(
                        labelText: 'Type de réduction',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pourcentage',
                          child: Text('Pourcentage'),
                        ),
                        DropdownMenuItem(
                          value: 'montant',
                          child: Text('Montant fixe'),
                        ),
                        DropdownMenuItem(
                          value: 'livraison',
                          child: Text('Livraison gratuite'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTypeReduction = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedTypeReduction != 'livraison')
                      TextFormField(
                        controller: _valeurReductionController,
                        decoration: InputDecoration(
                          labelText: _selectedTypeReduction == 'pourcentage'
                              ? 'Pourcentage de réduction'
                              : 'Montant de réduction (DT)',
                          border: const OutlineInputBorder(),
                          suffixText: _selectedTypeReduction == 'pourcentage'
                              ? '%'
                              : 'DT',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une valeur';
                          }
                          
                          final number = double.tryParse(value);
                          if (number == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          
                          if (_selectedTypeReduction == 'pourcentage' && (number <= 0 || number > 100)) {
                            return 'Le pourcentage doit être entre 0 et 100';
                          }
                          
                          if (_selectedTypeReduction == 'montant' && number <= 0) {
                            return 'Le montant doit être supérieur à 0';
                          }
                          
                          return null;
                        },
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Période',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date de début',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_dateDebut),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date de fin',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_dateFin),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Créer la promotion'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 