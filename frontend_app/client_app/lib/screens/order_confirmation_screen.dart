import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:intl/intl.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderConfirmationScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String orderId = order['_id'] ?? 'N/A';
    final String date = order['createdAt'] != null
        ? DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(order['createdAt']))
        : 'N/A';
    final double total = order['total'] != null
        ? double.parse(order['total'].toString())
        : 0.0;
    final String status = order['status'] ?? 'En attente';
    final String address = order['adresse'] ?? 'N/A';
    final String paymentMethod = _getPaymentMethodName(order['methodePaiement'] ?? 'N/A');
    final List<dynamic> items = order['items'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de commande'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et checkmark
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Commande confirmée',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Merci pour votre achat!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Détails de la commande
            _buildInfoSection(
              title: 'Détails de la commande',
              children: [
                _buildInfoRow('Numéro de commande:', orderId),
                _buildInfoRow('Date:', date),
                _buildInfoRow('Statut:', status),
                _buildInfoRow('Adresse de livraison:', address),
                _buildInfoRow('Méthode de paiement:', paymentMethod),
              ],
            ),
            const SizedBox(height: 24),

            // Récapitulatif des produits
            if (items.isNotEmpty) ...[
              const Text(
                'Produits commandés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map((item) => _buildProductItem(item)).toList(),
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 8),
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
                  Text(
                    '$total DT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Boutons d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Naviguer vers la liste des commandes
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Voir mes commandes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.lightTextColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final product = item['produit'];
    final quantity = item['quantite'] ?? 1;
    final price = product != null ? double.parse(product['prix'].toString()) : 0.0;
    final name = product != null ? product['nom'] ?? 'Produit' : 'Produit';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          if (product != null && product['images'] != null && (product['images'] as List).isNotEmpty)
            Image.network(
              product['images'][0],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            )
          else
            Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image_not_supported)),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Quantité: $quantity',
                  style: TextStyle(
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${price * quantity} DT',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'card':
        return 'Carte de crédit';
      case 'paypal':
        return 'PayPal';
      case 'cod':
        return 'Paiement à la livraison';
      default:
        return method;
    }
  }
} 