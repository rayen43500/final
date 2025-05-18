import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/promotion_service.dart';
import '../services/cart_service.dart';
import '../widgets/product_rating_badge.dart';
import '../config/app_constants.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import 'orders_screen.dart';
import 'chat_screen.dart';
import '../theme/app_theme.dart' as app_theme;
import 'profile_screen.dart';
import '../services/local_review_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  
  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final PromotionService _promotionService = PromotionService();
  final CartService _cartService = CartService();
  
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  List<dynamic> _promotions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Définition des couleurs pour le thème BIN FLOW
  static const Color primaryColor = Color(0xFF3F51B5); // Bleu indigo
  static const Color accentColor = Color(0xFFFF9800); // Orange
  static const Color successColor = Color(0xFF4CAF50); // Vert
  static const Color lightTextColor = Color(0xFF757575); // Gris
  static const Color dividerColor = Color(0xFFE0E0E0); // Gris clair
  static const Color scaffoldBackgroundColor = Color(0xFFFAFAFA); // Blanc cassé

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      print('⭐ Début du chargement des données...');
      
      // Récupération des catégories
      final categories = await _categoryService.getCategories();
      print('📂 ${categories.length} catégories récupérées');
      bool categoriesFromTest = categories.any((cat) => cat['_id'].toString().startsWith('cat'));
      
      // Récupération des produits
      final products = await _productService.getProducts(limit: 20);
      print('📦 ${products.length} produits récupérés');
      bool productsFromTest = products.any((prod) => prod['_id'].toString().startsWith('test'));

      // Récupération des promotions
      final promotions = await _promotionService.getPromotions();
      print('🏷️ ${promotions.length} promotions récupérées');
      
      // Mise à jour de l'interface
      setState(() {
        _categories = categories;
        _products = products;
        _promotions = promotions;
        _isLoading = false;
        
        // Afficher un message selon l'origine des données
        if (categoriesFromTest || productsFromTest) {
          _showDataSourceMessage(categoriesFromTest, productsFromTest);
        }
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  // Afficher un message à l'utilisateur concernant la source des données
  void _showDataSourceMessage(bool categoriesFromTest, bool productsFromTest) {
    if (!mounted) return;
    
    String message = '';
    if (categoriesFromTest && productsFromTest) {
      message = 'Affichage de données de test (API non connectée)';
    } else if (categoriesFromTest) {
      message = 'Catégories: données de test, Produits: API';
    } else if (productsFromTest) {
      message = 'Produits: données de test, Catégories: API';
    }
    
    if (message.isNotEmpty) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  }

  // Nouvelle fonction pour charger plus de produits par catégorie
  Future<void> _loadProductsByCategory(String categoryId) async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getProducts(category: categoryId, limit: 20);
      
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _searchProducts() async {
    if (_searchQuery.isEmpty) {
      await _loadData();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _productService.searchProducts(_searchQuery);
      setState(() {
        _products = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            app_theme.AppTheme.buildLogo(height: 32),
            const SizedBox(width: 8),
            const Text(AppConstants.appName),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: AppConstants.orders,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrdersScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: AppConstants.cart,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user?['nom'] ?? 'Utilisateur',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(user?['email'] ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: primaryColor,
                child: Text(
                  (user?['nom'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: primaryColor,
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined, color: primaryColor),
              title: Text(AppConstants.home),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.eco_outlined, color: primaryColor),
              title: Text(AppConstants.categories),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.local_offer_outlined, color: primaryColor),
              title: Text(AppConstants.promotions),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Stack(
                children: [
                  Icon(Icons.chat_outlined, color: accentColor),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: successColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(AppConstants.chat),
              subtitle: Text(AppConstants.chatSubtitle),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag_outlined, color: primaryColor),
              title: Text(AppConstants.orders),
              selected: _selectedIndex == 3,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrdersScreen(),
                  ),
                );
              },
            ),
            Divider(color: dividerColor),
            ListTile(
              leading: Icon(Icons.person_outline, color: primaryColor),
              title: Text(AppConstants.profile),
              selected: _selectedIndex == 4,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: primaryColor),
              title: Text(AppConstants.logout),
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            label: 'Catégories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            label: 'Promotions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Panier',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex != 3 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartScreen()),
          );
        },
        label: const Text('Passer commande'),
        icon: const Icon(Icons.shopping_bag_outlined),
        backgroundColor: primaryColor,
      ) : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildCategoriesTab();
      case 2:
        return _buildPromotionsTab();
      case 3:
        return const CartScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bannière promotionnelle en haut
                if (_promotions.isNotEmpty)
                  _buildPromotionBanner(),
                
                // Barre de recherche et bouton de rafraîchissement
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      // Barre de recherche
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: scaffoldBackgroundColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher un produit...',
                                    hintStyle: TextStyle(color: lightTextColor),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                    _searchProducts();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bouton de rafraîchissement
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: primaryColor,
                        onPressed: () {
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Actualisation des données...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Indicateur de source de données (API ou Test)
                if (_isUsingTestData())
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Données de test affichées. API non connectée.',
                            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Catégories sous forme de grille
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppConstants.exploreByCategory,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoriesGrid(),
                    ],
                  ),
                ),
                
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                
                // Produits en vedette avec titre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConstants.popularProducts,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Les meilleurs produits sélectionnés pour vous',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeaturedProductsGrid(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Indicateur de chargement
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // Vérifier si nous utilisons des données de test
  bool _isUsingTestData() {
    if (_categories.isEmpty || _products.isEmpty) return false;
    
    bool hasTestCategories = _categories.any((cat) => cat['_id'].toString().startsWith('cat'));
    bool hasTestProducts = _products.any((prod) => prod['_id'].toString().startsWith('test'));
    
    return hasTestCategories || hasTestProducts;
  }

  // Widget pour la grille de catégories
  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text(
          'Aucune catégorie disponible',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.0,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculer le nombre de colonnes en fonction de la largeur disponible
              final double width = constraints.maxWidth;
              final int crossAxisCount = width > 600 ? 4 : (width > 400 ? 3 : 2);
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categories.length > 6 ? 6 : _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final colorName = category['colorName'] ?? 'blue';
                  final iconName = category['iconName'] ?? 'category';
                  
                  Color cardColor = _getCategoryColor(colorName);
                  IconData iconData = _getCategoryIcon(iconName);
                  
                  return InkWell(
                    onTap: () => _navigateToCategoryScreen(category),
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: cardColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cardColor.withOpacity(0.9),
                            cardColor.withOpacity(0.7)
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              category['nom'] ?? 'Catégorie',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category['productCount'] ?? '0'} produits',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          ),
          if (_categories.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: () {
                  _navigateToAllCategories();
                },
                icon: const Icon(Icons.grid_view, size: 18),
                label: const Text('Voir toutes les catégories'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Widget pour la grille de produits en vedette
  Widget _buildFeaturedProductsGrid() {
    if (_products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text(
          'Aucun produit disponible',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.0,
          ),
        ),
      );
    }

    final featuredProducts = _products.take(4).toList();

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculer le nombre de colonnes en fonction de la largeur disponible
            final double width = constraints.maxWidth;
            final int crossAxisCount = width > 600 ? 3 : 2;
            // Ajuster le ratio en fonction du nombre de colonnes
            final double childAspectRatio = width > 600 ? 0.8 : 0.7;
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                final isOnSale = product['prixPromo'] != null || product['prixFinal'] != null;
                final hasStock = (product['stock'] ?? 0) > 0;
                
                return InkWell(
                  onTap: () => _showProductDetails(product),
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image et badge promos
                        Expanded(
                          flex: 5,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8.0),
                                  topRight: Radius.circular(8.0),
                                ),
                                child: _buildProductImage(product),
                              ),
                              if (isOnSale)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5252), // AccentColor
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: const Text(
                                      'PROMO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!hasStock)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8.0),
                                        topRight: Radius.circular(8.0),
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE57373), // ErrorColor
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        child: const Text(
                                          'RUPTURE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Informations produit
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['nom'] ?? 'Produit',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                ProductRatingBadge(
                                  productId: product['_id'],
                                  size: 14,
                                  showCount: true,
                                ),
                                const SizedBox(height: 4),
                                _buildPriceSection(product),
                                const Spacer(),
                                // Bouton Ajouter au panier
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: hasStock ? () => _addToCart(product) : null,
                                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                                    label: const Text('Ajouter'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Boutons Détails et Avis clients côte à côte
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => _showProductDetails(product),
                                        child: const Text('Détails'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: primaryColor,
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () => _navigateToProductReviews(product),
                                        icon: const Icon(Icons.star, size: 14, color: Colors.amber),
                                        label: const Text('Avis'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.amber.shade800,
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        ),
        if (_products.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: () {
                _navigateToAllProducts();
              },
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Voir tous les produits'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // Widget pour la construction de l'image d'un produit
  Widget _buildProductImage(Map<String, dynamic> product) {
    final imageUrls = product['images'] as List<dynamic>?;
    final String imageUrl = imageUrls != null && imageUrls.isNotEmpty 
      ? imageUrls.first.toString()
      : 'https://via.placeholder.com/300x300?text=Produit';
    
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: scaffoldBackgroundColor,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: lightTextColor,
                size: 40,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: scaffoldBackgroundColor,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Widget pour l'affichage des prix
  Widget _buildPriceSection(Map<String, dynamic> product) {
    // Extraire les prix de manière sécurisée
    double regularPrice = 0.0;
    final priceValue = _getProductPrice(product, 'prix');
    if (priceValue != null) {
      regularPrice = priceValue;
    }
    
    // Calculer le prix final
    double finalPrice = regularPrice;
    final promoPrice = _getProductPrice(product, 'prixPromo');
    final finalListedPrice = _getProductPrice(product, 'prixFinal');
    
    if (finalListedPrice != null) {
      finalPrice = finalListedPrice;
    } else if (promoPrice != null) {
      finalPrice = promoPrice;
    }
    
    final bool isOnSale = finalPrice < regularPrice;
    final int discountPercent = isOnSale 
        ? ((1 - (finalPrice / regularPrice)) * 100).round() 
        : 0;
    
    return Row(
      children: [
        // Prix final
        Text(
          '${finalPrice.toStringAsFixed(2)} DT',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(width: 8),
        
        // Prix barré si promo
        if (isOnSale)
          Text(
            '${regularPrice.toStringAsFixed(2)} DT',
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Color(0xFF757575),
              fontSize: 12,
            ),
          ),
        
        // Pourcentage de réduction
        if (isOnSale && discountPercent > 0)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-$discountPercent%',
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // Récupérer le prix d'un produit de manière sécurisée
  double? _getProductPrice(Map<String, dynamic> product, String priceKey) {
    final dynamic price = product[priceKey];
    if (price == null) return null;
    
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      try {
        return double.parse(price);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  // Récupérer la couleur d'une catégorie
  Color _getCategoryColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.redAccent;
      case 'blue': return Colors.blueAccent;
      case 'green': return Colors.greenAccent[700]!;
      case 'purple': return Colors.purpleAccent;
      case 'orange': return Colors.orangeAccent;
      case 'teal': return Colors.tealAccent[700]!;
      case 'pink': return Colors.pinkAccent;
      case 'amber': return Colors.amberAccent;
      case 'indigo': return Colors.indigoAccent;
      default: return primaryColor;
    }
  }
  
  // Récupérer l'icône d'une catégorie
  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'face': return Icons.face;
      case 'medication': return Icons.medication;
      case 'spa': return Icons.spa;
      case 'fitness': return Icons.fitness_center;
      case 'baby': return Icons.child_care;
      case 'hygiene': return Icons.sanitizer;
      case 'heart': return Icons.favorite;
      case 'book': return Icons.menu_book;
      default: return Icons.category;
    }
  }
  
  // Navigation vers l'écran de catégorie
  void _navigateToCategoryScreen(Map<String, dynamic> category) {
    // Implémenter la navigation vers l'écran de catégorie
    print('Naviguer vers la catégorie: ${category['nom']}');
  }
  
  // Navigation vers toutes les catégories
  void _navigateToAllCategories() {
    // Implémenter la navigation vers toutes les catégories
    print('Naviguer vers toutes les catégories');
  }
  
  // Navigation vers tous les produits
  void _navigateToAllProducts() {
    // Implémenter la navigation vers tous les produits
    print('Naviguer vers tous les produits');
  }
  
  // Navigation vers le détail d'un produit
  void _navigateToProductDetail(Map<String, dynamic> product) {
    // Implémenter la navigation vers le détail du produit
    print('Naviguer vers le produit: ${product['nom']}');
  }

  // Navigation vers le détail d'un produit avec l'onglet avis sélectionné
  void _navigateToProductReviews(Map<String, dynamic> product) {
    _showReviewDialog(product);
  }

  // Fonction pour afficher le dialogue d'avis
  void _showReviewDialog(Map<String, dynamic> product) {
    final TextEditingController commentController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    double newRating = 0;
    bool isSubmitting = false;
    final LocalReviewService reviewService = LocalReviewService();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Votre avis sur ${product['nom']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Champ du nom
                      const Text(
                        'Votre nom:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Entrez votre nom',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Note
                      const Text(
                        'Votre note:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Sélection des étoiles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                newRating = index + 1.0;
                              });
                            },
                            // Permettre de sélectionner en glissant le doigt
                            onHorizontalDragUpdate: (details) {
                              final RenderBox box = context.findRenderObject() as RenderBox;
                              final localPosition = box.globalToLocal(details.globalPosition);
                              final starWidth = box.size.width / 5;
                              final starIndex = (localPosition.dx / starWidth).floor();
                              
                              if (starIndex >= 0 && starIndex < 5) {
                                setState(() {
                                  newRating = starIndex + 1.0;
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                index < newRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          newRating > 0 
                            ? 'Votre note: ${newRating.toStringAsFixed(0)}/5' 
                            : 'Sélectionnez une note',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Commentaire
                      const Text(
                        'Votre commentaire:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Partagez votre expérience...',
                          prefixIcon: const Icon(Icons.comment),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 24),
                      
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
                              onPressed: isSubmitting ? null : () async {
                                if (newRating == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Veuillez attribuer une note')),
                                  );
                                  return;
                                }
                                
                                if (nameController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Veuillez saisir votre nom')),
                                  );
                                  return;
                                }
                                
                                setState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  await reviewService.addReview(
                                    productId: product['_id'],
                                    userName: nameController.text,
                                    rating: newRating,
                                    comment: commentController.text,
                                  );
                                  
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Merci ! Votre avis a été ajouté avec succès'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erreur: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.amber.shade600,
                              ),
                              child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Publier'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        // Titre et description
        Container(
          padding: const EdgeInsets.all(16.0),
          color: scaffoldBackgroundColor.withOpacity(0.3),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.allCategories,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.categoriesDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Grille de catégories
        Expanded(
          child: _categories.isEmpty 
              ? const Center(child: Text('Aucune catégorie disponible'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculer le nombre de colonnes en fonction de la largeur disponible
                    final double width = constraints.maxWidth;
                    final int crossAxisCount = width > 800 ? 4 : (width > 600 ? 3 : 2);
                    
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _buildCategoryCard(category);
                      },
                    );
                  }
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final String name = category['nom'] ?? 'Catégorie';
    final String icon = category['iconName'] ?? 'category';
    final String color = category['colorName'] ?? 'blue';
    final int productCount = category['productCount'] ?? 0;

    return InkWell(
      onTap: () {
        if (category['_id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryScreen(
                categoryId: category['_id'],
                categoryName: name,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCategoryColor(color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(icon),
                size: 36,
                color: _getCategoryColor(color),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              productCount == 1 
                  ? '1 produit' 
                  : '$productCount produits',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsTab() {
    if (_promotions.isEmpty) {
      return const Center(
        child: Text('Aucune promotion disponible'),
      );
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _promotions.length,
        itemBuilder: (context, index) {
          final promotion = _promotions[index];
          return _buildPromotionCard(promotion);
        },
      ),
    );
  }

  Widget _buildPromotionCard(dynamic promotion) {
    final String name = promotion['nom'] ?? 'Promotion';
    final String description = promotion['description'] ?? '';
    final String code = promotion['codePromo'] ?? '';
    final dynamic reduction = promotion['valeurReduction'];
    final String imageUrl = promotion['image'] ?? 'https://via.placeholder.com/600x300?text=Promotion';
    final DateTime? endDate = promotion['dateFin'] != null 
        ? DateTime.tryParse(promotion['dateFin']) 
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: primaryColor.withOpacity(0.1),
                child: Center(
                  child: Icon(Icons.image_not_supported, size: 50, color: lightTextColor),
                ),
              ),
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et badge de réduction
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (reduction != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE57373),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          '-$reduction%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Description
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Date de fin
                if (endDate != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: Color(0xFF757575)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Valable jusqu\'au ${_formatDate(endDate)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Code promo
                if (code.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Code: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            // Logique pour copier le code
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Code $code copié')),
                            );
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Bouton pour appliquer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Naviguer vers les produits concernés
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryScreen(
                            categoryId: '',
                            categoryName: 'Produits en promotion',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Voir les produits'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final List<String> months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildOrdersTab() {
    return const OrdersScreen();
  }

  Widget _buildCartTab() {
    return const CartScreen();
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Text('Mon profil - À venir'),
    );
  }

  Widget _buildPromotionBanner() {
    if (_promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    final promotion = _promotions[0];
    final hasImage = promotion['image'] != null && promotion['image'].toString().isNotEmpty;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajuster la hauteur en fonction de la largeur disponible
        final double bannerHeight = constraints.maxWidth < 600 ? 120 : 160;
        final double fontSize = constraints.maxWidth < 600 ? 18 : 22;
        
        return Container(
          height: bannerHeight,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
                        gradient: LinearGradient(              begin: Alignment.topLeft,              end: Alignment.bottomRight,              colors: [                primaryColor,                accentColor,              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image de fond (si disponible)
              if (hasImage)
                Opacity(
                  opacity: 0.4,
                  child: Image.network(
                    promotion['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(),
                  ),
                ),
              
              // Contenu
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Titre de la promotion
                    Text(
                      promotion['nom'] ?? 'Offre spéciale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description (si disponible et si l'écran est assez grand)
                    if (promotion['description'] != null && constraints.maxWidth >= 400)
                      Text(
                        promotion['description'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: constraints.maxWidth < 600 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Bouton d'action
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 2; // Aller à l'onglet promotions
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth < 600 ? 12 : 20, 
                          vertical: constraints.maxWidth < 600 ? 6 : 10
                        ),
                        textStyle: TextStyle(
                          fontSize: constraints.maxWidth < 600 ? 12 : 14,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      child: const Text('Voir les offres'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    try {
      final productId = product['_id'];
      
      if (productId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ajouter ce produit au panier.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Afficher une SnackBar de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajout au panier...'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
      
      // Ajouter au panier avec la quantité par défaut de 1
      _cartService.addToCart(productId.toString(), 1, product).then((_) {
        // Afficher un message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product['nom']} ajouté au panier'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'VOIR PANIER',
                textColor: Colors.white,
                onPressed: () {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      }).catchError((error) {
        // Afficher un message d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      // Gérer les erreurs imprévues
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Afficher une fenêtre modale avec les détails du produit
  void _showProductDetails(Map<String, dynamic> product) {
    final String name = product['nom'] ?? 'Produit';
    final String description = product['description'] ?? 'Aucune description disponible.';
    final List<dynamic>? imageUrls = product['images'] as List<dynamic>?;
    final String imageUrl = imageUrls != null && imageUrls.isNotEmpty 
      ? imageUrls.first.toString()
      : 'https://via.placeholder.com/300x300?text=Produit';
    final double price = _getProductPrice(product, 'prix') ?? 0.0;
    final double finalPrice = _getProductPrice(product, 'prixFinal') ?? 
                              _getProductPrice(product, 'prixPromo') ?? 
                              price;
    final bool isOnSale = finalPrice < price;
    final bool hasStock = (product['stock'] ?? 0) > 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;
        
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec le nom du produit et le bouton de fermeture
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Image et prix - adaptatif selon la taille d'écran
              isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image centrée pour petit écran
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Prix et disponibilité
                      _buildProductDetailsPriceSection(
                        price: price,
                        finalPrice: finalPrice,
                        isOnSale: isOnSale,
                        hasStock: hasStock,
                        product: product
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Prix et disponibilité
                      Expanded(
                        child: _buildProductDetailsPriceSection(
                          price: price,
                          finalPrice: finalPrice,
                          isOnSale: isOnSale,
                          hasStock: hasStock,
                          product: product
                        ),
                      ),
                    ],
                  ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Bouton d'action
              if (hasStock)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _addToCart(product);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ajouter au panier',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Widget pour la section prix des détails produit
  Widget _buildProductDetailsPriceSection({
    required double price,
    required double finalPrice,
    required bool isOnSale,
    required bool hasStock,
    required Map<String, dynamic> product
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prix
        Row(
          children: [
            Text(
              '${finalPrice.toStringAsFixed(2)} DT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isOnSale ? Colors.red : const Color(0xFF212121),
              ),
            ),
            if (isOnSale) ...[
              const SizedBox(width: 8),
              Text(
                '${price.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Color(0xFF757575),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Disponibilité
        Row(
          children: [
            Icon(
              hasStock ? Icons.check_circle : Icons.cancel,
              color: hasStock ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              hasStock ? 'En stock' : 'Rupture de stock',
              style: TextStyle(
                color: hasStock ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Voir le produit complet
        InkWell(
          onTap: () {
            Navigator.pop(context);
            _navigateToProductDetail(product);
          },
          child: Text(
            'Voir la fiche produit complète',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
} 