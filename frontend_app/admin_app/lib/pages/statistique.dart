import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';
import 'dart:math';

class StatistiquePage extends StatefulWidget {
  const StatistiquePage({super.key});

  @override
  State<StatistiquePage> createState() => _StatistiquePageState();
}

class _StatistiquePageState extends State<StatistiquePage> {
  final _authService = AuthService();
  final _statsService = StatsService();
  bool _isLoading = true;
  String _selectedPeriod = 'Semaine';
  final List<String> _periodOptions = ['Jour', 'Semaine', 'Mois', 'Année'];

  // Données pour les statistiques
  Map<String, dynamic> _statsData = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _statsService.getStats();
      
      setState(() {
        _statsData = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // Initialiser avec des valeurs par défaut en cas d'erreur
        _statsData = {
          'revenuTotal': 0,
          'revenuComparaison': 0,
          'commandesTotal': 0,
          'commandesComparaison': 0,
          'clientsTotal': 0,
          'clientsComparaison': 0,
          'vuesProduits': 0,
          'vuesComparaison': 0,
          'tauxConversion': 0,
          'tauxConversionComparaison': 0,
          'produitsBestSellers': [],
          'ventesMensuelles': [],
          'ventesParCategorie': [],
        };
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des statistiques: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: theme.colorScheme.primary,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              underline: Container(
                height: 0,
              ),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                }
              },
              items: _periodOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vue d\'ensemble',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isSmallScreen ? 2 : 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Revenu',
                          'DT${_statsData['revenuTotal'].toStringAsFixed(2)}',
                          _statsData['revenuComparaison'],
                          Icons.attach_money,
                          Colors.green,
                          theme,
                        ),
                        _buildStatCard(
                          'Commandes',
                          _statsData['commandesTotal'].toString(),
                          _statsData['commandesComparaison'],
                          Icons.shopping_cart,
                          Colors.blue,
                          theme,
                        ),
                        _buildStatCard(
                          'Nouveaux clients',
                          _statsData['clientsTotal'].toString(),
                          _statsData['clientsComparaison'],
                          Icons.people,
                          Colors.orange,
                          theme,
                        ),
                        _buildStatCard(
                          'Vues produits',
                          _statsData['vuesProduits'].toString(),
                          _statsData['vuesComparaison'],
                          Icons.visibility,
                          Colors.purple,
                          theme,
                        ),
                        _buildStatCard(
                          'Taux de conversion',
                          '${_statsData['tauxConversion']}%',
                          _statsData['tauxConversionComparaison'],
                          Icons.trending_up,
                          Colors.indigo,
                          theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Ventes mensuelles',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: _buildSalesChart(theme),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ventes par catégorie',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: _buildCategoryChart(theme),
                              ),
                            ],
                          ),
                        ),
                        if (!isSmallScreen) ...[
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Produits les plus vendus',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._buildBestSellersList(theme),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isSmallScreen) ...[
                      const SizedBox(height: 32),
                      Text(
                        'Produits les plus vendus',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildBestSellersList(theme),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showExportReportDialog(context);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Exporter le rapport'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    double comparison,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    final isPositive = comparison >= 0;
    final comparisonText = isPositive ? '+${comparison.toStringAsFixed(1)}%' : '${comparison.toStringAsFixed(1)}%';
    final comparisonColor = isPositive ? Colors.green : Colors.red;
    final comparisonIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  comparisonIcon,
                  color: comparisonColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  comparisonText,
                  style: TextStyle(
                    color: comparisonColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'vs ${_getPreviousPeriod()}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(ThemeData theme) {
    // Vérifier si les données sont disponibles
    if (_statsData['ventesMensuelles'] == null || _statsData['ventesMensuelles'].isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Aucune donnée de ventes disponible'),
          ),
        ),
      );
    }
    
    // Trouver la vente maximale pour calculer les pourcentages
    double maxSale = 0;
    try {
      maxSale = _statsData['ventesMensuelles']
          .map<double>((item) {
            // S'assurer que 'ventes' est convertible en double
            if (item['ventes'] == null) return 0.0;
            if (item['ventes'] is double) return item['ventes'] as double;
            if (item['ventes'] is int) return (item['ventes'] as int).toDouble();
            if (item['ventes'] is String) return double.tryParse(item['ventes'] as String) ?? 0.0;
            return 0.0;
          })
          .fold<double>(0, (previous, current) => current > previous ? current : previous);
    } catch (e) {
      print('Erreur lors du calcul de la vente maximale: $e');
      maxSale = 1.0; // Valeur par défaut pour éviter division par zéro
    }
    
    // Éviter division par zéro
    if (maxSale <= 0) maxSale = 1.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Évolution du chiffre d\'affaires',
                  style: theme.textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: DT${_calculateYearlyTotal().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _statsData['ventesMensuelles'].map<Widget>((item) {
                  // Extraire et convertir la valeur des ventes de manière sécurisée
                  double salesValue = 0;
                  try {
                    if (item['ventes'] is double) {
                      salesValue = item['ventes'] as double;
                    } else if (item['ventes'] is int) {
                      salesValue = (item['ventes'] as int).toDouble();
                    } else if (item['ventes'] is String) {
                      salesValue = double.tryParse(item['ventes'] as String) ?? 0.0;
                    }
                  } catch (e) {
                    print('Erreur lors de la conversion des ventes: $e');
                  }
                  
                  // Calculer le pourcentage par rapport au maximum
                  double percentage = salesValue / maxSale;
                  // Limiter le pourcentage entre 0 et 1
                  percentage = percentage.clamp(0.0, 1.0);
                  
                  // Calculer l'opacité de manière sécurisée (entre 0.6 et 1.0)
                  double opacity = 0.6 + (0.4 * percentage);
                  // S'assurer que l'opacité reste dans la plage 0.0-1.0
                  opacity = opacity.clamp(0.0, 1.0);
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 150 * percentage,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(opacity),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['mois'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(ThemeData theme) {
    // Verify if the data exists and has the right format
    if (_statsData['ventesParCategorie'] == null || _statsData['ventesParCategorie'].isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Aucune donnée disponible'),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Statistiques des commandes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._statsData['ventesParCategorie'].map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['categorie'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          item['valeur'].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _getProgressValue(item),
                      backgroundColor: Colors.grey.shade200,
                      color: _getStatColor(item['categorie'], theme),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Helper method to get color based on stat type
  Color _getStatColor(String category, ThemeData theme) {
    switch (category) {
      case 'Total des commandes':
        return Colors.blue;
      case 'Commandes livrées':
        return Colors.green;
      case 'Revenu total (DT)':
        return theme.colorScheme.primary;
      default:
        return Colors.orange;
    }
  }

  // Helper method to get a progress value between 0-1 for each stat
  double _getProgressValue(Map<String, dynamic> item) {
    // For the progress bar visualization
    String category = item['categorie'];
    
    // Convert to double if it's a string
    double value = item['valeur'] is String 
      ? double.tryParse(item['valeur']) ?? 0.0 
      : item['valeur'] is int 
        ? item['valeur'].toDouble() 
        : item['valeur'] ?? 0.0;
    
    double result = 0.0;    
    // Different logic for different categories
    switch (category) {
      case 'Total des commandes':
        // Cap at 100 for visualization
        result = value > 100 ? 1.0 : value / 100.0;
        break;
      case 'Commandes livrées':
        // Show as percentage of total orders
        final totalOrders = _statsData['ventesParCategorie']
            .firstWhere((stat) => stat['categorie'] == 'Total des commandes', 
                      orElse: () => {'valeur': 1})['valeur'];
        // Convertir totalOrders en double si c'est une chaîne
        double totalOrdersValue = totalOrders is String
            ? double.tryParse(totalOrders) ?? 1.0
            : totalOrders is int
                ? totalOrders.toDouble()
                : totalOrders ?? 1.0;
        
        result = totalOrdersValue > 0 ? value / totalOrdersValue : 0;
        break;
      case 'Revenu total (DT)':
        // Cap at 10000 DT for visualization
        result = value > 10000 ? 1.0 : value / 10000.0;
        break;
      default:
        result = 0.5; // Default value
    }
    
    // S'assurer que la valeur est dans la plage 0.0-1.0
    return result.clamp(0.0, 1.0);
  }

  List<Widget> _buildBestSellersList(ThemeData theme) {
    return _statsData['produitsBestSellers'].map<Widget>((product) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.medication,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['nom'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${product['ventes']} vendus • DT${product['revenu'].toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showExportReportDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.download,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Exporter le rapport'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisissez le format et la période pour l\'exportation du rapport.'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Format:'),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'PDF', label: Text('PDF')),
                      ButtonSegment(value: 'EXCEL', label: Text('Excel')),
                      ButtonSegment(value: 'CSV', label: Text('CSV')),
                    ],
                    selected: const {'PDF'},
                    onSelectionChanged: (Set<String> selection) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Période:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _periodOptions.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPeriod = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rapport exporté avec succès'),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Exporter'),
          ),
        ],
      ),
    );
  }

  String _getPreviousPeriod() {
    switch (_selectedPeriod) {
      case 'Jour':
        return 'hier';
      case 'Semaine':
        return 'semaine précédente';
      case 'Mois':
        return 'mois précédent';
      case 'Année':
        return 'année précédente';
      default:
        return 'période précédente';
    }
  }

  double _calculateYearlyTotal() {
    try {
      if (_statsData['ventesMensuelles'] == null || _statsData['ventesMensuelles'].isEmpty) {
        return 0.0;
      }
      
      return _statsData['ventesMensuelles']
        .map<double>((item) {
          // Conversion sécurisée des valeurs
          if (item['ventes'] == null) return 0.0;
          if (item['ventes'] is double) return item['ventes'] as double;
          if (item['ventes'] is int) return (item['ventes'] as int).toDouble();
          if (item['ventes'] is String) {
            return double.tryParse(item['ventes'] as String) ?? 0.0;
          }
          return 0.0;
        })
        .fold<double>(0.0, (double previous, double current) => previous + current);
    } catch (e) {
      print('Erreur dans _calculateYearlyTotal: $e');
      return 0.0;
    }
  }
}
