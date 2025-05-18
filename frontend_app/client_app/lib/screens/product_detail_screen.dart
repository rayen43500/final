import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../services/promotion_service.dart';
import '../widgets/product_reviews.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final int initialTabIndex;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final PromotionService _promotionService = PromotionService();

  Map<String, dynamic>? _product;
  List<dynamic> _promotions = [];
  bool _isLoading = true;
  int _quantity = 1;
  String? _promoCode;
  double _finalPrice = 0;
  double _originalPrice = 0;
  double _discount = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadProductDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final product = await _productService.getProductById(widget.productId);
      final promotions = await _promotionService.getProductPromotions(widget.productId);

      setState(() {
        _product = product;
        _promotions = promotions['promotions'] ?? [];
        _originalPrice = double.parse(product['prix'].toString());
        _finalPrice = double.parse(product['prixFinal']?.toString() ?? product['prix'].toString());
        _discount = _originalPrice - _finalPrice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du produit: $e')),
        );
      }
    }
  }

  Future<void> _applyPromoCode() async {
    if (_promoCode == null || _promoCode!.isEmpty) {
      return;
    }

    try {
      final result = await _promotionService.applyPromoCode(widget.productId, _promoCode!);
      
      setState(() {
        _finalPrice = double.parse(result['reducedPrice'].toString());
        _discount = double.parse(result['discount'].toString());
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code promo appliqué avec succès')),
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

  Future<void> _addToCart() async {
    if (_product == null) return;

    try {
      await _cartService.addToCart(widget.productId, _quantity, _product!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_product!['nom']} ajouté au panier')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?['nom'] ?? 'Détails du produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart screen
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.description),
              text: 'Détails',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Avis',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProductContent(),
    );
  }

  Widget _buildProductContent() {
    if (_product == null) {
      return const Center(child: Text('Produit non trouvé'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Onglet Détails du produit
        _buildProductDetails(),
        
        // Onglet Avis clients
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ProductReviews(
            productId: widget.productId,
            showAddReview: true,
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    final inStock = (_product!['stock'] ?? 0) > 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du produit
          SizedBox(
            height: 300,
            width: double.infinity,
            child: PageView.builder(
              itemCount: (_product!['images'] as List?)?.length ?? 1,
              itemBuilder: (context, index) {
                return Image.network(
                  (_product!['images'] as List?)?.isNotEmpty == true
                      ? _product!['images'][index]
                      : 'https://via.placeholder.com/600x600?text=Pas+d\'image',
                  fit: BoxFit.cover,
                );
              },
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge promotion
                if (_discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '-${(_discount / _originalPrice * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Nom du produit
                Text(
                  _product!['nom'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Catégorie
                Text(
                  'Catégorie: ${(_product!['categoryId'] as Map<String, dynamic>?)?['nom'] ?? 'Non catégorisé'}',
                  style: TextStyle(
                    color: AppTheme.lightTextColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Prix
                Row(
                  children: [
                    Text(
                      '$_finalPrice DT',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _discount > 0 ? Colors.red : AppTheme.primaryColor,
                      ),
                    ),
                    if (_discount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$_originalPrice DT',
                        style: TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Disponibilité
                Row(
                  children: [
                    Icon(
                      inStock ? Icons.check_circle : Icons.cancel,
                      color: inStock ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      inStock ? 'En stock' : 'Rupture de stock',
                      style: TextStyle(
                        color: inStock ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _product!['description'] ?? 'Aucune description disponible',
                  style: TextStyle(
                    color: AppTheme.darkTextColor,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Code promo
                const Text(
                  'Avez-vous un code promo?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Entrez votre code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          _promoCode = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quantité
                const Text(
                  'Quantité',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _quantity > 1
                          ? () {
                              setState(() {
                                _quantity--;
                              });
                            }
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightTextColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _quantity < (_product!['stock'] ?? 0)
                          ? () {
                              setState(() {
                                _quantity++;
                              });
                            }
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Bouton Ajouter au panier
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: inStock ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      inStock ? 'Ajouter au panier' : 'Indisponible',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                
                // Bouton pour voir les avis (sur l'onglet détails)
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _tabController.animateTo(1); // Basculer vers l'onglet des avis
                    },
                    icon: const Icon(Icons.star, color: Colors.amber),
                    label: const Text('Voir ou ajouter un avis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.amber.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 