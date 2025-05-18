import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/delivery_model.dart';
import '../theme/app_theme.dart';
import '../services/delivery_service.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final Delivery delivery;

  const DeliveryDetailsScreen({
    Key? key,
    required this.delivery,
  }) : super(key: key);

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  late String _currentStatus;
  final List<String> _statusOptions = ['En attente', 'En cours', 'Livrée', 'Annulée'];
  bool _isUpdating = false;
  final DeliveryService _deliveryService = DeliveryService();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.delivery.status;
  }

  // Obtenir une couleur en fonction du statut
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
        return Colors.orange;
      case 'en cours':
        return Colors.blue;
      case 'livrée':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      default:
        return AppTheme.darkTextColor;
    }
  }
  
  // Mettre à jour le statut de la livraison
  Future<void> _updateDeliveryStatus() async {
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final success = await _deliveryService.updateDeliveryStatus(
        widget.delivery.id, 
        _currentStatus
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Statut mis à jour: $_currentStatus'),
              backgroundColor: _getStatusColor(_currentStatus),
            ),
          );
        }
        
        // Revenir à l'écran précédent après une mise à jour réussie
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true); // Retourne true pour indiquer une mise à jour réussie
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec de la mise à jour du statut'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          setState(() {
            _isUpdating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Détails de la livraison'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Action pour appeler le client
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appel au client...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec le statut
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        Delivery.getStatusEmoji(_currentStatus),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statut actuel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _currentStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.delivery.isPaid ? 'Payé' : 'À percevoir',
                          style: TextStyle(
                            color: widget.delivery.isPaid
                                ? Colors.white
                                : Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        'Date',
                        DateFormat('dd/MM/yyyy').format(widget.delivery.orderDate),
                        Icons.calendar_today,
                      ),
                      _buildInfoItem(
                        'Distance',
                        '${widget.delivery.distance.toStringAsFixed(1)} km',
                        Icons.directions_car,
                      ),
                      _buildInfoItem(
                        'Durée estimée',
                        '${widget.delivery.estimatedTime} min',
                        Icons.timer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Informations client
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                            const Text(                        'Informations Client',                        style: TextStyle(                          fontSize: 20,                          fontWeight: FontWeight.w600,                          color: AppTheme.darkTextColor,                        ),                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                            radius: 25,
                            child: Text(
                              widget.delivery.clientName.isNotEmpty
                                  ? widget.delivery.clientName.substring(0, 1).toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.delivery.clientName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.delivery.phone,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.darkTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Commandé ${widget.delivery.getElapsedTime().toLowerCase()}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.darkTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.call,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: () {
                              // Action pour appeler le client
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Appel au client...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Adresse de livraison',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.lightTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.delivery.address,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.directions,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: () {
                              // Action pour ouvrir les directions sur la carte
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ouverture de la carte...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Articles de la commande
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                            const Text(                        'Produits',                        style: TextStyle(                          fontSize: 20,                          fontWeight: FontWeight.w600,                          color: AppTheme.darkTextColor,                        ),                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: widget.delivery.items.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = widget.delivery.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.medical_services_outlined,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${item.price.toStringAsFixed(2)} DT x ${item.quantity}',
                                        style: const TextStyle(
                                          color: AppTheme.lightTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.total.toStringAsFixed(2)} DT',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${widget.delivery.total.toStringAsFixed(2)} DT',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.delivery.notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.delivery.notes,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkTextColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                    const Text(                    'Mettre à jour le statut',                    style: TextStyle(                      fontSize: 20,                      fontWeight: FontWeight.w600,                      color: AppTheme.darkTextColor,                    ),                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statusOptions.length,
                      itemBuilder: (context, index) {
                        final status = _statusOptions[index];
                        final isSelected = _currentStatus == status;
                        final color = _getStatusColor(status);
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _currentStatus = status;
                                });
                              }
                            },
                            backgroundColor: Colors.white,
                            selectedColor: color.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? color : AppTheme.darkTextColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            avatar: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: color,
                                    size: 18,
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? color : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUpdating 
                            ? null 
                            : () {
                              Navigator.pop(context);
                            },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Retour'),
                          style: OutlinedButton.styleFrom(                            foregroundColor: AppTheme.primaryColor,                            side: const BorderSide(color: AppTheme.primaryColor),                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),                            shape: RoundedRectangleBorder(                              borderRadius: BorderRadius.circular(8.0),                            ),                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating 
                            ? null 
                            : _updateDeliveryStatus,
                          icon: _isUpdating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                          label: Text(_isUpdating ? 'Mise à jour...' : 'Enregistrer'),
                          style: AppTheme.primaryButtonStyle,
                        ),
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
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 