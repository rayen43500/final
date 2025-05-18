class Order {
  final String id;
  final String date;
  final String clientName;
  final double montant;
  final String status;
  final List<OrderItem> produits;
  final String adresse;
  final String telephone;
  final String paiement;
  final String? livreurId;
  final String? livreurName;

  Order({
    required this.id,
    required this.date,
    required this.clientName,
    required this.montant,
    required this.status,
    required this.produits,
    required this.adresse,
    required this.telephone,
    required this.paiement,
    this.livreurId,
    this.livreurName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];
    if (json['produits'] != null) {
      if (json['produits'] is List) {
        items = List<OrderItem>.from(
          (json['produits'] as List).map((item) => OrderItem.fromJson(item)),
        );
      }
    }

    // Conversion sécurisée du montant en double
    double parsedMontant = 0.0;
    try {
      var rawMontant = json['total'] ?? json['montant'] ?? 0;
      if (rawMontant is int) {
        parsedMontant = rawMontant.toDouble();
      } else if (rawMontant is double) {
        parsedMontant = rawMontant;
      } else if (rawMontant is String) {
        parsedMontant = double.tryParse(rawMontant) ?? 0.0;
      }
    } catch (e) {
      print('Erreur de conversion du montant: $e');
      parsedMontant = 0.0;
    }

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      date: json['dateCreation'] ?? json['date'] ?? '',
      clientName: json['client']?['nom'] ?? json['client'] ?? json['clientName'] ?? '',
      montant: parsedMontant,
      status: json['statut'] ?? json['status'] ?? 'En attente',
      produits: items,
      adresse: json['adresseLivraison'] ?? json['adresse'] ?? '',
      telephone: json['client']?['telephone'] ?? json['telephone'] ?? '',
      paiement: json['methodePaiement'] ?? json['paiement'] ?? '',
      livreurId: json['livreur']?['_id'] ?? json['livreurId'],
      livreurName: json['livreur']?['nom'] ?? json['livreurName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'dateCreation': date,
      'client': {'nom': clientName, 'telephone': telephone},
      'total': montant,
      'statut': status,
      'produits': produits.map((item) => item.toJson()).toList(),
      'adresseLivraison': adresse,
      'methodePaiement': paiement,
      'livreur': livreurId != null ? {'_id': livreurId, 'nom': livreurName} : null,
    };
  }
  
  // Méthode pour créer une copie avec mise à jour de certains champs
  Order copyWith({
    String? status,
    String? livreurId,
    String? livreurName,
  }) {
    return Order(
      id: this.id,
      date: this.date,
      clientName: this.clientName,
      montant: this.montant,
      status: status ?? this.status,
      produits: this.produits,
      adresse: this.adresse,
      telephone: this.telephone,
      paiement: this.paiement,
      livreurId: livreurId ?? this.livreurId,
      livreurName: livreurName ?? this.livreurName,
    );
  }
}

class OrderItem {
  final String id;
  final String nom;
  final int quantite;
  final double prix;
  final String? image;

  OrderItem({
    required this.id,
    required this.nom,
    required this.quantite,
    required this.prix,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Conversion sécurisée de la quantité en int
    int parsedQuantite = 1;
    try {
      var rawQuantite = json['quantite'] ?? json['quantité'] ?? 1;
      if (rawQuantite is int) {
        parsedQuantite = rawQuantite;
      } else if (rawQuantite is String) {
        parsedQuantite = int.tryParse(rawQuantite) ?? 1;
      }
    } catch (e) {
      print('Erreur de conversion de la quantité: $e');
      parsedQuantite = 1;
    }

    // Conversion sécurisée du prix en double
    double parsedPrix = 0.0;
    try {
      var rawPrix = json['prix'] ?? json['prixUnitaire'] ?? 0;
      if (rawPrix is int) {
        parsedPrix = rawPrix.toDouble();
      } else if (rawPrix is double) {
        parsedPrix = rawPrix;
      } else if (rawPrix is String) {
        parsedPrix = double.tryParse(rawPrix) ?? 0.0;
      }
    } catch (e) {
      print('Erreur de conversion du prix: $e');
      parsedPrix = 0.0;
    }

    return OrderItem(
      id: json['produitId'] ?? json['_id'] ?? '',
      nom: json['nom'] ?? json['produit']?['nom'] ?? '',
      quantite: parsedQuantite,
      prix: parsedPrix,
      image: json['produit']?['image'] ?? json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produitId': id,
      'quantite': quantite,
      'prixUnitaire': prix,
      'nom': nom,
      'image': image,
    };
  }
} 