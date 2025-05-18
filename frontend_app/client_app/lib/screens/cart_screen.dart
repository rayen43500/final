import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  List<Map<String, dynamic>>? _cart;
  bool _isLoading = true;
  String? _promoCode;
  bool _isApplyingPromo = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cart = await _cartService.getCart();
      setState(() {
        _cart = cart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du panier: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(String productId, int quantity) async {
    try {
      await _cartService.updateQuantity(productId, quantity);
      await _loadCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _removeFromCart(String productId) async {
    try {
      await _cartService.removeFromCart(productId);
      await _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé du panier')),
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

  Future<void> _clearCart() async {
    try {
      await _cartService.clearCart();
      await _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panier vidé')),
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

  Future<void> _applyPromoCode() async {
    if (_promoCode == null || _promoCode!.isEmpty) {
      return;
    }

    setState(() {
      _isApplyingPromo = true;
    });

    try {
      await _cartService.applyPromoCode(_promoCode!);
      await _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code promo appliqué avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() {
        _isApplyingPromo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (_cart != null && _cart!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCart,
              tooltip: 'Vider le panier',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCartContent(),
      bottomNavigationBar: _cart != null && _cart!.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildCartContent() {
    if (_cart == null || _cart!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.lightTextColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Votre panier est vide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ajoutez des produits pour commencer vos achats',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Retour aux produits'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cart!.length,
            itemBuilder: (context, index) {
              final item = _cart![index];
              final produit = item['produit'];
              final quantity = item['quantite'];
              final prix = double.parse(produit['prix'].toString());
              final prixPromo = produit['prixPromo'] != null ? double.parse(produit['prixPromo'].toString()) : null;
              final prixFinal = prixPromo ?? prix;
              final discount = prix - prixFinal;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image du produit
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          produit['images']?[0] ?? 'https://via.placeholder.com/80x80?text=Produit',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Détails du produit
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              produit['nom'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$prixFinal DT',
                                  style: TextStyle(
                                    color: discount > 0 ? Colors.red : AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (discount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '$prix DT',
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppTheme.lightTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Contrôles de quantité
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: quantity > 1
                                      ? () => _updateQuantity(produit['_id'], quantity - 1)
                                      : null,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 20,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _updateQuantity(produit['_id'], quantity + 1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 20,
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeFromCart(produit['_id']),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Code promo
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Code promo',
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
                onPressed: _isApplyingPromo ? null : _applyPromoCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isApplyingPromo
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Appliquer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_cart == null) return const SizedBox.shrink();
    
    double totalOriginal = 0;
    double total = 0;
    
    for (var item in _cart!) {
      final produit = item['produit'];
      final quantity = item['quantite'];
      final prix = double.parse(produit['prix'].toString());
      final prixPromo = produit['prixPromo'] != null ? double.parse(produit['prixPromo'].toString()) : null;
      final prixFinal = prixPromo ?? prix;
      
      totalOriginal += prix * quantity;
      total += prixFinal * quantity;
    }
    
    final discount = totalOriginal - total;
    final hasDiscount = discount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDiscount)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sous-total:',
                    style: TextStyle(
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                  Text(
                    '$totalOriginal DT',
                    style: TextStyle(
                      color: AppTheme.lightTextColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '$total DT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: hasDiscount ? Colors.red : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cart!.isEmpty ? null : () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const CheckoutScreen())
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Passer commande',
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
  }
} 