import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../widgets/product_rating_badge.dart';
import 'product_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();

  List<dynamic> _products = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMoreProducts = true;
  bool _isLoadingMore = false;
  String _sortBy = 'newest';
  RangeValues _priceRange = const RangeValues(0, 1000);
  double _maxPrice = 1000;
  bool _inStockOnly = false;
  bool _onSaleOnly = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 && !_isLoadingMore && _hasMoreProducts) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _page = 1;
    });

    try {
      final products = await _productService.getProducts(
        category: widget.categoryId,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        inStock: _inStockOnly,
        onSale: _onSaleOnly,
        sortBy: _sortBy,
        page: _page,
        limit: 20,
      );

      // Déterminer le prix maximum pour le filtre
      double maxPrice = 0;
      for (var product in products) {
        double price = double.parse(product['prix'].toString());
        if (price > maxPrice) maxPrice = price;
      }

      setState(() {
        _products = products;
        _isLoading = false;
        _hasMoreProducts = products.length == 20;
        if (maxPrice > 0) {
          _maxPrice = maxPrice * 1.2; // 20% de plus que le prix max
          _priceRange = RangeValues(0, _maxPrice);
        }
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

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    setState(() {
      _isLoadingMore = true;
      _page++;
    });

    try {
      final newProducts = await _productService.getProducts(
        category: widget.categoryId,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        inStock: _inStockOnly,
        onSale: _onSaleOnly,
        sortBy: _sortBy,
        page: _page,
        limit: 20,
      );

      setState(() {
        _products.addAll(newProducts);
        _isLoadingMore = false;
        _hasMoreProducts = newProducts.length == 20;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _applyFilters() async {
    await _loadProducts();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tri
                  const Text(
                    'Trier par',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSortOption(setStateModal, 'newest', 'Plus récents'),
                      _buildSortOption(setStateModal, 'price-asc', 'Prix croissant'),
                      _buildSortOption(setStateModal, 'price-desc', 'Prix décroissant'),
                      _buildSortOption(setStateModal, 'rating', 'Popularité'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Fourchette de prix
                  const Text(
                    'Fourchette de prix',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: _maxPrice,
                    divisions: 20,
                    labels: RangeLabels(
                      '${_priceRange.start.round()} DT',
                      '${_priceRange.end.round()} DT',
                    ),
                    onChanged: (values) {
                      setStateModal(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_priceRange.start.round()} DT'),
                        Text('${_priceRange.end.round()} DT'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Options supplémentaires
                  SwitchListTile(
                    title: const Text('Produits en stock uniquement'),
                    value: _inStockOnly,
                    onChanged: (value) {
                      setStateModal(() {
                        _inStockOnly = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Produits en promotion uniquement'),
                    value: _onSaleOnly,
                    onChanged: (value) {
                      setStateModal(() {
                        _onSaleOnly = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(StateSetter setStateModal, String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _sortBy == value,
      onSelected: (selected) {
        if (selected) {
          setStateModal(() {
            _sortBy = value;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProductGrid(),
    );
  }

  Widget _buildProductGrid() {
    if (_products.isEmpty) {
      return const Center(
        child: Text('Aucun produit dans cette catégorie'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${_products.length} produits',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextColor,
                ),
              ),
              const Spacer(),
              Text(
                _getSortText(),
                style: TextStyle(
                  color: AppTheme.lightTextColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, size: 20),
                onPressed: _showFilterDialog,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _isLoadingMore
                ? _products.length + 2
                : _products.length,
            itemBuilder: (context, index) {
              if (index >= _products.length) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final product = _products[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  String _getSortText() {
    switch (_sortBy) {
      case 'newest':
        return 'Plus récents';
      case 'price-asc':
        return 'Prix croissant';
      case 'price-desc':
        return 'Prix décroissant';
      case 'rating':
        return 'Popularité';
      default:
        return 'Tri par défaut';
    }
  }

  Widget _buildProductCard(dynamic product) {
    final id = product['_id'];
    final name = product['nom'];
    final price = product['prix'];
    final finalPrice = product['prixFinal'] ?? price;
    final imageUrl = product['images']?[0] ?? 'https://via.placeholder.com/150';
    final inStock = (product['stock'] ?? 0) > 0;
    final hasDiscount = finalPrice != price;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image et badge promo
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${((price - finalPrice) / price * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Informations produit
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ProductRatingBadge(
                    productId: id,
                    size: 12,
                    showCount: false,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$finalPrice DT',
                        style: TextStyle(
                          color: hasDiscount ? Colors.red : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 4),
                        Text(
                          '$price DT',
                          style: TextStyle(
                            color: AppTheme.lightTextColor,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: inStock
                          ? () async {
                              try {
                                await _cartService.addToCart(id, 1, product);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$name ajouté au panier')),
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
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(inStock ? 'Ajouter' : 'Rupture'),
                    ),
                  ),
                  // Bouton Avis clients
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productId: id,
                            initialTabIndex: 1, // Index de l'onglet des avis
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review, size: 14),
                    label: const Text('Avis clients'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 