import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart' as theme;

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  Map<String, dynamic> _order = {};
  bool _isLoading = true;
  bool _isCancelling = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final order = await _orderService.getOrderDetails(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des détails de la commande: $e';
        _isLoading = false;
      });
    }
  }

  // Formatter une date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Annuler une commande
  Future<void> _cancelOrder() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler la commande'),
          content: const Text('Êtes-vous sûr de vouloir annuler cette commande ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isCancelling = true;
                });
                
                try {
                  await _orderService.cancelOrder(widget.orderId);
                  
                  setState(() {
                    _isCancelling = false;
                    // Mettre à jour le statut de la commande dans l'état local
                    _order = {
                      ..._order,
                      'statut': 'Annulé',
                      'raisonAnnulation': 'Annulé par le client'
                    };
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Commande annulée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() {
                    _isCancelling = false;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'annulation: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  // Obtenir la couleur et l'icône pour un statut donné
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'en préparation':
        return {
          'color': Colors.blue,
          'icon': Icons.inventory,
          'background': Colors.blue.withOpacity(0.1),
        };
      case 'expédié':
        return {
          'color': Colors.orange,
          'icon': Icons.local_shipping,
          'background': Colors.orange.withOpacity(0.1),
        };
      case 'livré':
        return {
          'color': Colors.green,
          'icon': Icons.check_circle,
          'background': Colors.green.withOpacity(0.1),
        };
      case 'annulé':
        return {
          'color': Colors.red,
          'icon': Icons.cancel,
          'background': Colors.red.withOpacity(0.1),
        };
      case 'en attente de paiement':
        return {
          'color': Colors.purple,
          'icon': Icons.payment,
          'background': Colors.purple.withOpacity(0.1),
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.info,
          'background': Colors.grey.withOpacity(0.1),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(_order['statut'] ?? '');
    final bool canCancel = !_isCancelling && 
        (_order['statut'] == 'En préparation' || _order['statut'] == 'En attente de paiement');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${_order['numero'] ?? ''}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty 
              ? _buildErrorWidget() 
              : _buildOrderDetails(statusInfo, canCancel),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Oups! Une erreur est survenue',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> statusInfo, bool canCancel) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut de la commande avec icône et couleur
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusInfo['background'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    statusInfo['icon'],
                    color: statusInfo['color'],
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _order['statut'] ?? 'Statut inconnu',
                    style: TextStyle(
                      color: statusInfo['color'],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(_order['statut'] ?? ''),
                    style: TextStyle(
                      color: statusInfo['color'].withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informations de la commande
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails de la commande',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('N° de commande', _order['numero'] ?? '-'),
                    _buildInfoRow('Date de commande', _formatDate(_order['date'] ?? '')),
                    if (_order['dateLivraison'] != null) 
                      _buildInfoRow('Livraison prévue', _formatDate(_order['dateLivraison'])),
                    _buildInfoRow('Statut de paiement', _order['paymentStatus'] ?? 'Non spécifié'),
                    _buildInfoRow('Méthode de paiement', _order['methodePaiement'] ?? 'Non spécifié'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Adresse de livraison
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Adresse de livraison',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _order['adresseLivraison'] ?? 'Adresse non spécifiée',
                      style: const TextStyle(fontSize: 15),
                    ),
                    if (_order['livreur'] != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Livreur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _order['livreur']['nom'] ?? 'Non assigné',
                        style: const TextStyle(fontSize: 15),
                      ),
                      if (_order['livreur']['telephone'] != null)
                        Text(
                          _order['livreur']['telephone'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des produits
            const Text(
              'Produits',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: (_order['produits'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final produit = (_order['produits'] as List)[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image du produit
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: produit['images'] != null &&
                                    (produit['images'] as List).isNotEmpty
                                ? Image.network(
                                    produit['images'][0],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Détails du produit
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                produit['nom'] ?? 'Produit inconnu',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prix unitaire: ${produit['prix'].toStringAsFixed(2)} DT',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quantité: ${produit['quantite']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sous-total: ${(produit['prix'] * produit['quantite']).toStringAsFixed(2)} DT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
            
            const SizedBox(height: 24),
            
            // Récapitulatif des coûts
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Récapitulatif',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sous-total'),
                        Text('${_order['total']?.toStringAsFixed(2) ?? "0.00"} DT'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${_order['total']?.toStringAsFixed(2) ?? "0.00"} DT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton d'annulation si possible
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cancelOrder,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler la commande'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Méthode pour créer une ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Obtenir une description détaillée du statut
  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'en préparation':
        return 'Votre commande est en cours de préparation dans notre entrepôt.';
      case 'expédié':
        return 'Votre commande a été expédiée et est en cours d\'acheminement.';
      case 'livré':
        return 'Votre commande a été livrée avec succès.';
      case 'annulé':
        return 'Cette commande a été annulée.';
      case 'en attente de paiement':
        return 'Nous attendons la confirmation de votre paiement.';
      default:
        return 'Statut de la commande.';
    }
  }
} 