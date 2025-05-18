import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/delivery_model.dart';
import '../services/delivery_service.dart';
import '../config/api_config.dart';
import '../utils/token_manager.dart';
import 'login_screen.dart';
import 'delivery_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Delivery> _deliveries = [];
  String _filterStatus = 'Tous';
  bool _isLoading = true;
  final DeliveryService _deliveryService = DeliveryService();
  
  // Liste des statuts pour le filtre
  final List<String> _statusFilters = ['Tous', 'En attente', 'En cours', 'Livrée', 'Annulée'];

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }
  
  // Charger les livraisons du livreur
  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Récupérer les livraisons depuis l'API
      final deliveries = await _deliveryService.getDeliveryPersonOrders();
      
      setState(() {
        _deliveries = deliveries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des livraisons: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Filtrer les livraisons en fonction du statut sélectionné
  List<Delivery> get _filteredDeliveries {
    if (_filterStatus == 'Tous') {
      return _deliveries;
    }
    return _deliveries.where((delivery) => 
      delivery.status.toLowerCase() == _filterStatus.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Espace Livreur'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton de test de connexion
          IconButton(
            icon: const Icon(Icons.wifi, color: Colors.white),
            tooltip: 'Tester API',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test de connexion en cours...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              final bool isConnected = await _deliveryService.testApiConnection();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isConnected ? 'Connexion OK' : 'Échec de connexion'),
                    backgroundColor: isConnected ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Configuration',
            onPressed: _showConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: user == null 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _buildBody(user, size),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.lightTextColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Livraisons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(user, Size size) {
    switch (_selectedIndex) {
      case 0:
        return _buildDeliveriesTab(size);
      case 1:
        return _buildMapTab();
      case 2:
        return _buildHistoryTab();
      case 3:
        return _buildProfileTab(user);
      default:
        return _buildDeliveriesTab(size);
    }
  }

  // Onglet Livraisons
  Widget _buildDeliveriesTab(Size size) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          // En-tête avec statistiques
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Statistiques de livraison
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        size,
                        '${_deliveries.where((d) => d.status == 'En attente').length}',
                        'En attente',
                        Icons.access_time,
                      ),
                      _buildStatCard(
                        size,
                        '${_deliveries.where((d) => d.status == 'En cours').length}',
                        'En cours',
                        Icons.delivery_dining,
                      ),
                      _buildStatCard(
                        size,
                        '${_deliveries.where((d) => d.status == 'Livrée').length}',
                        'Livrées',
                        Icons.check_circle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Filtres par statut
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemBuilder: (context, index) {
                  final status = _statusFilters[index];
                  final isSelected = _filterStatus == status;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = status;
                        });
                      },
                      backgroundColor: AppTheme.secondaryColor,
                      selectedColor: AppTheme.primaryColor.withAlpha(51),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.darkTextColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      checkmarkColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Liste des livraisons
          Expanded(
            child: _filteredDeliveries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: AppTheme.lightTextColor.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'Tous' 
                              ? 'Aucune livraison à effectuer'
                              : 'Aucune livraison $_filterStatus',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.lightTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredDeliveries.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final delivery = _filteredDeliveries[index];
                      return _buildDeliveryCard(delivery);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Carte des statistiques
  Widget _buildStatCard(Size size, String value, String label, IconData icon) {
    return Container(
      width: size.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Carte de livraison
  Widget _buildDeliveryCard(Delivery delivery) {
    final String statusEmoji = Delivery.getStatusEmoji(delivery.status);
    final bool isUrgent = delivery.status == 'En attente' && 
                         DateTime.now().difference(delivery.orderDate).inHours < 2;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgent ? AppTheme.warningColor.withAlpha(51) : Colors.transparent,
          width: isUrgent ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap: () async {
          // Navigation vers les détails de la livraison
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDetailsScreen(delivery: delivery),
            ),
          );
          
          // Si le statut a été mis à jour, recharger les livraisons
          if (result == true) {
            _loadDeliveries();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut et heure
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        statusEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        delivery.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(delivery.status),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    delivery.getElapsedTime(),
                    style: const TextStyle(
                      color: AppTheme.lightTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Informations client
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor,
                    radius: 20,
                    child: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: AppTheme.lightTextColor),
                            const SizedBox(width: 4),
                            Text(
                              delivery.phone,
                              style: const TextStyle(
                                color: AppTheme.lightTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppTheme.lightTextColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                delivery.address,
                                style: const TextStyle(
                                  color: AppTheme.lightTextColor,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Détails de la commande
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Commande',
                        style: TextStyle(
                          color: AppTheme.lightTextColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${delivery.items.length} article${delivery.items.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paiement',
                        style: TextStyle(
                          color: AppTheme.lightTextColor,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            delivery.isPaid ? Icons.check_circle : Icons.money,
                            size: 16,
                            color: delivery.isPaid ? AppTheme.successColor : AppTheme.warningColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            delivery.isPaid ? 'Payé' : 'À percevoir',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: delivery.isPaid ? AppTheme.successColor : AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: AppTheme.lightTextColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${delivery.total.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Tag urgent si nécessaire
              if (isUrgent) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.priority_high,
                        size: 14,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'URGENT',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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

  // Onglet Carte
  Widget _buildMapTab() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 80,
                color: AppTheme.lightTextColor.withAlpha(128),
              ),
              const SizedBox(height: 16),
              const Text(
                'Carte des livraisons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La fonction de carte sera disponible prochainement',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.lightTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Onglet Historique
  Widget _buildHistoryTab() {
    // Filtrer seulement les livraisons terminées (statut "Livrée")
    final List<Delivery> completedDeliveries = _deliveries
        .where((delivery) => delivery.status == 'Livrée')
        .toList();
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      color: AppTheme.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de l'onglet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historique de Livraisons',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${completedDeliveries.length} livraison${completedDeliveries.length > 1 ? 's' : ''} terminée${completedDeliveries.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Livraisons terminées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
          ),
          
          Expanded(
            child: completedDeliveries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: AppTheme.lightTextColor.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune livraison terminée',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.lightTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: completedDeliveries.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final delivery = completedDeliveries[index];
                      return _buildHistoryDeliveryCard(delivery);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDeliveryCard(Delivery delivery) {
    final String statusEmoji = Delivery.getStatusEmoji(delivery.status);
    final String formattedDate = DateFormat('dd/MM/yyyy').format(delivery.orderDate);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(delivery.status).withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  statusEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.clientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${delivery.items.length} article${delivery.items.length > 1 ? 's' : ''} • ${delivery.total.toStringAsFixed(2)} DT',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(delivery.status).withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delivery.status,
                    style: TextStyle(
                      color: _getStatusColor(delivery.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Onglet Profil
  Widget _buildProfileTab(user) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Photo de profil et nom
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withAlpha(51),
            child: Text(
              user.nom.isNotEmpty ? user.nom.substring(0, 1).toUpperCase() : 'L',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.nom,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user.role,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 32),
          
          // Informations personnelles
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildProfileInfoCard(
            icon: Icons.email,
            title: 'Email',
            value: user.email,
          ),
          
          const SizedBox(height: 12),
          
          _buildProfileInfoCard(
            icon: Icons.phone,
            title: 'Téléphone',
            value: user.telephone,
          ),
          
          const SizedBox(height: 32),
          
          // Statistiques
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatisticCard(
                  value: '${_deliveries.where((d) => d.status == 'Livrée').length}',
                  label: 'Livraisons complétées',
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatisticCard(
                  value: '4.8/5',
                  label: 'Note moyenne',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Boutons d'action
          OutlinedButton.icon(
            onPressed: () {
              // Action de modification du profil
            },
            icon: const Icon(Icons.edit),
            label: const Text('Modifier le profil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextButton.icon(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout, color: AppTheme.errorColor),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatisticCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Mettre à jour le statut d'une livraison
  Future<void> _updateDeliveryStatus(String deliveryId, String status) async {
    try {
      final success = await _deliveryService.updateDeliveryStatus(deliveryId, status);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: $status'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Recharger les livraisons après mise à jour
        _loadDeliveries();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Échec de la mise à jour du statut'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Afficher les détails de configuration
  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration API'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('URL de base: ${ApiConfig.baseUrl}'),
              const SizedBox(height: 8),
              Text('Endpoint livraisons: ${ApiConfig.deliveryOrdersEndpoint}'),
              const SizedBox(height: 8),
              Text('Endpoint statut: ${ApiConfig.statusEndpoint}'),
              const SizedBox(height: 16),
              const Text('Jetons d\'authentification:'),
              FutureBuilder<String?>(
                future: TokenManager.getToken(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}');
                  }
                  final token = snapshot.data;
                  return Text(
                    token == null ? 'Aucun token trouvé' : 'Token: ${token.substring(0, min(20, token.length))}...',
                    style: TextStyle(
                      color: token == null ? Colors.red : Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
} 