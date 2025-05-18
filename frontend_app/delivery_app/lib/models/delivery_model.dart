import 'package:intl/intl.dart';

class Delivery {
  final String id;
  final String userId;
  final String clientName;
  final String address;
  final String phone;
  final String status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final List<DeliveryItem> items;
  final double total;
  final String paymentStatus;
  final bool isPaid;
  final String notes;
  final double distance;
  final int estimatedTime; // en minutes
  final String livreurId;

  Delivery({
    required this.id,
    required this.userId,
    required this.clientName,
    required this.address,
    required this.phone,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.items,
    required this.total,
    required this.paymentStatus,
    required this.isPaid,
    this.notes = '',
    this.distance = 0.0,
    this.estimatedTime = 0,
    required this.livreurId,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    List<DeliveryItem> itemsList = [];
    if (json['produits'] != null) {
      itemsList = List<DeliveryItem>.from(
        json['produits'].map((item) => DeliveryItem.fromJson(item)),
      );
    }

    // Parse dates safely
    DateTime? orderDate;
    try {
      orderDate = json['dateCommande'] != null 
          ? DateTime.parse(json['dateCommande']) 
          : DateTime.now();
    } catch (e) {
      orderDate = DateTime.now();
    }

    DateTime? deliveryDate;
    try {
      deliveryDate = json['dateLivraison'] != null 
          ? DateTime.parse(json['dateLivraison']) 
          : null;
    } catch (e) {
      deliveryDate = null;
    }

    // Map backend status to frontend status
    String status = 'En attente';
    if (json['statut'] != null) {
      switch (json['statut']) {
        case 'En attente':
          status = 'En attente';
          break;
        case 'Expédiée':
          status = 'En cours';
          break;
        case 'Livrée':
          status = 'Livrée';
          break;
        case 'Annulée':
          status = 'Annulée';
          break;
      }
    }

    bool isPaid = json['paymentStatus'] == 'Payée';

    return Delivery(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      clientName: json['userName'] ?? 'Client',
      address: json['adresseLivraison'] ?? '',
      phone: json['userPhone'] ?? '',
      status: status,
      orderDate: orderDate,
      deliveryDate: deliveryDate,
      items: itemsList,
      total: json['total']?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] ?? 'En attente',
      isPaid: isPaid,
      notes: json['notes'] ?? '',
      livreurId: json['livreurId'] ?? '',
      // Default values for fields not in backend
      distance: json['distance']?.toDouble() ?? calculateRandomDistance(),
      estimatedTime: json['estimatedTime'] ?? calculateEstimatedTime(json['distance']?.toDouble() ?? calculateRandomDistance()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'adresseLivraison': address,
      'statut': status,
      'dateCommande': orderDate.toIso8601String(),
      'dateLivraison': deliveryDate?.toIso8601String(),
      'produits': items.map((item) => item.toJson()).toList(),
      'total': total,
      'paymentStatus': paymentStatus,
      'livreurId': livreurId,
      'notes': notes,
    };
  }

  // Helper method to generate random distance for demo
  static double calculateRandomDistance() {
    return (1 + (6 - 1) * (DateTime.now().millisecond / 999)).roundToDouble();
  }
  
  // Helper method to estimate delivery time based on distance
  static int calculateEstimatedTime(double distance) {
    // Assume average speed of 20 km/h in city traffic
    return (distance * 3).round();
  }

  // Méthode pour obtenir une couleur en fonction du statut
  static String getStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
        return '⏳';
      case 'en cours':
        return '🚚';
      case 'livrée':
        return '✅';
      case 'annulée':
        return '❌';
      default:
        return '📦';
    }
  }

  // Cette méthode sera remplacée par un appel API réel
  static List<Delivery> getDummyData({String? livreurId}) {
    final dummyData = [
      Delivery(
        id: 'DEL001',
        userId: 'USER001',
        clientName: 'Ahmed Benali',
        address: '15 Rue des Oliviers, Tunis',
        phone: '+21698765432',
        status: 'En attente',
        orderDate: DateTime.now().subtract(const Duration(hours: 5)),
        items: [
          DeliveryItem(
            id: 'PROD001',
            name: 'Paracétamol 500mg',
            quantity: 2,
            price: 5.99,
          ),
          DeliveryItem(
            id: 'PROD002',
            name: 'Sirop pour la toux',
            quantity: 1,
            price: 12.50,
          ),
        ],
        total: 24.48,
        paymentStatus: 'En attente',
        isPaid: false,
        distance: 3.2,
        estimatedTime: 15,
        livreurId: 'LIVREUR001',
      ),
      Delivery(
        id: 'DEL002',
        userId: 'USER002',
        clientName: 'Fatima Zahra',
        address: '7 Avenue Habib Bourguiba, Sousse',
        phone: '+21655443322',
        status: 'En cours',
        orderDate: DateTime.now().subtract(const Duration(hours: 3)),
        items: [
          DeliveryItem(
            id: 'PROD003',
            name: 'Vitamine C',
            quantity: 1,
            price: 8.75,
          ),
          DeliveryItem(
            id: 'PROD004',
            name: 'Masque facial',
            quantity: 5,
            price: 2.99,
          ),
        ],
        total: 23.70,
        paymentStatus: 'Payée',
        isPaid: true,
        distance: 1.8,
        estimatedTime: 10,
        livreurId: 'LIVREUR002',
      ),
      Delivery(
        id: 'DEL003',
        userId: 'USER003',
        clientName: 'Mohammed Khairi',
        address: '22 Rue Ibn Khaldoun, Sfax',
        phone: '+21699887766',
        status: 'Livrée',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        deliveryDate: DateTime.now().subtract(const Duration(hours: 6)),
        items: [
          DeliveryItem(
            id: 'PROD005',
            name: 'Thermomètre digital',
            quantity: 1,
            price: 15.99,
          ),
        ],
        total: 15.99,
        paymentStatus: 'Payée',
        isPaid: true,
        distance: 4.5,
        estimatedTime: 20,
        livreurId: 'LIVREUR001',
      ),
      Delivery(
        id: 'DEL004',
        userId: 'USER004',
        clientName: 'Leila Trabelsi',
        address: '9 Rue de Marseille, Tunis',
        phone: '+21693456789',
        status: 'Annulée',
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        items: [
          DeliveryItem(
            id: 'PROD006',
            name: 'Crème hydratante',
            quantity: 1,
            price: 22.50,
          ),
          DeliveryItem(
            id: 'PROD007',
            name: 'Huile essentielle',
            quantity: 2,
            price: 17.99,
          ),
        ],
        total: 58.48,
        paymentStatus: 'Annulée',
        isPaid: false,
        distance: 2.7,
        estimatedTime: 12,
        livreurId: 'LIVREUR002',
      ),
      Delivery(
        id: 'DEL005',
        userId: 'USER005',
        clientName: 'Karim Benzema',
        address: '3 Rue de Paris, Tunis',
        phone: '+21699123456',
        status: 'En attente',
        orderDate: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          DeliveryItem(
            id: 'PROD008',
            name: 'Gel antibactérien',
            quantity: 3,
            price: 4.50,
          ),
        ],
        total: 13.50,
        paymentStatus: 'En attente',
        isPaid: false,
        distance: 2.1,
        estimatedTime: 8,
        livreurId: 'LIVREUR001',
      ),
    ];
    
    // Filter by livreurId if provided
    if (livreurId != null) {
      return dummyData.where((delivery) => delivery.livreurId == livreurId).toList();
    }
    
    return dummyData;
  }
  
  // Formater la date pour l'affichage
  String getFormattedDate() {
    return DateFormat('dd/MM/yyyy HH:mm').format(orderDate);
  }
  
  // Obtenir le temps écoulé depuis la commande
  String getElapsedTime() {
    final now = DateTime.now();
    final difference = now.difference(orderDate);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}

class DeliveryItem {
  final String id;
  final String name;
  final int quantity;
  final double price;

  DeliveryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      id: json['produitId'] ?? '',
      name: json['nomProduit'] ?? 'Produit',
      quantity: json['quantité'] ?? 0,
      price: json['prixUnitaire']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produitId': id,
      'quantité': quantity,
      'prixUnitaire': price,
    };
  }

  double get total => quantity * price;
} 