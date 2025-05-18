import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../config/theme.dart';
import 'order_confirmation_screen.dart';
import '../services/local_cart_service.dart';
import 'dart:convert';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final LocalCartService _localCartService = LocalCartService();
  
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _newAddressController = TextEditingController();
  
  String? _selectedAddress;
  String? _selectedPaymentMethod = 'card';
  String? _notes;
  bool _isLoading = false;
  List<String> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _checkCartContent();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _newAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    // TODO: Charger les adresses depuis le service utilisateur
    setState(() {
      _addresses = [
        '4100 mednine sud, mednine',
      ];
      
      if (_addresses.isNotEmpty) {
        _selectedAddress = _addresses[0];
      }
    });
  }

  Future<void> _checkCartContent() async {
    try {
      final cart = await _localCartService.getCart();
      print('Contenu du panier: ${json.encode(cart)}');
      if (cart.isEmpty) {
        print('Le panier est vide, ajout d\'un produit de test');
        // Ajouter un produit de test si le panier est vide
        await _localCartService.addToCart(
          '64a1c199e7dc21c538461bc3', // ID de produit factice
          1, 
          {
            '_id': '64a1c199e7dc21c538461bc3',
            'nom': 'Produit test',
            'prix': 99.99,
            'description': 'Produit de test'
          }
        );
        print('Produit test ajouté au panier');
        
        // Vérifier que le produit a bien été ajouté
        final updatedCart = await _localCartService.getCart();
        print('Panier après ajout: ${json.encode(updatedCart)}');
        
        if (updatedCart.isEmpty) {
          print('ERREUR: Le produit n\'a pas été ajouté au panier!');
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification du panier: $e');
    }
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une adresse'),
        content: TextField(
          controller: _newAddressController,
          decoration: const InputDecoration(
            hintText: 'Entrez votre adresse complète',
            labelText: 'Adresse de livraison',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newAddressController.text.trim().isNotEmpty) {
                setState(() {
                  _addresses.add(_newAddressController.text.trim());
                  _selectedAddress = _newAddressController.text.trim();
                  _newAddressController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null || _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Passer la commande directement avec les données du panier local
      final order = await _orderService.createOrder(
        address: _selectedAddress!,
        paymentMethod: _selectedPaymentMethod!,
        notes: _notesController.text,
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(order: order),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la commande: $e')),
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
        title: const Text('Finalisation de la commande'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Adresse de livraison
                  const Text(
                    'Adresse de livraison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAddressSelector(),
                  const SizedBox(height: 24),

                  // Méthode de paiement
                  const Text(
                    'Méthode de paiement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentMethodSelector(),
                  const SizedBox(height: 24),

                  // Notes
                  const Text(
                    'Notes (optionnel)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Instructions spéciales pour la livraison',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAddressSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_addresses.isEmpty)
              const Text('Aucune adresse enregistrée')
            else
              Column(
                children: _addresses.map((address) {
                  return RadioListTile<String>(
                    title: Text(address),
                    value: address,
                    groupValue: _selectedAddress,
                    onChanged: (value) {
                      setState(() {
                        _selectedAddress = value;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une adresse'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text('Carte de crédit'),
            subtitle: const Text('Visa, Mastercard, etc.'),
            value: 'card',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('PayPal'),
            value: 'paypal',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Paiement à la livraison'),
            value: 'cod',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              FutureBuilder<double>(
                future: _cartService.calculateTotal(),
                builder: (context, snapshot) {
                  final total = snapshot.data ?? 0.0;
                  return Text(
                    '$total DT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirmer la commande',
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