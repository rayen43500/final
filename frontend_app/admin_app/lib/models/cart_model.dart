class CartItem {
  final String id;
  final String produitId;
  final int quantite;
  final double prixUnitaire;
  final Map<String, dynamic>? produitDetails;

  CartItem({
    required this.id,
    required this.produitId,
    required this.quantite,
    required this.prixUnitaire,
    this.produitDetails,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? '',
      produitId: json['produitId'] ?? '',
      quantite: json['quantité'] ?? 0,
      prixUnitaire: double.parse((json['prixUnitaire'] ?? 0).toString()),
      produitDetails: json['produitId'] is Map ? json['produitId'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'produitId': produitId,
      'quantité': quantite,
      'prixUnitaire': prixUnitaire,
    };
  }

  // Obtenir le prix total pour cet article
  double get totalPrix => prixUnitaire * quantite;

  // Obtenir le nom du produit depuis les détails si disponible
  String get nomProduit {
    if (produitDetails != null && produitDetails!.containsKey('nom')) {
      return produitDetails!['nom'];
    }
    return 'Produit #$produitId';
  }

  // Obtenir l'image du produit depuis les détails si disponible
  String? get imageProduit {
    if (produitDetails != null && 
        produitDetails!.containsKey('images') && 
        produitDetails!['images'] is List && 
        (produitDetails!['images'] as List).isNotEmpty) {
      return produitDetails!['images'][0];
    }
    return null;
  }
}

class Cart {
  final String id;
  final String userId;
  final List<CartItem> produits;
  final double totalPrix;
  final String? codePromo;
  final double reduction;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? userDetails;

  Cart({
    required this.id,
    required this.userId,
    required this.produits,
    required this.totalPrix,
    this.codePromo,
    required this.reduction,
    required this.createdAt,
    required this.updatedAt,
    this.userDetails,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    List<CartItem> cartItems = [];
    if (json['produits'] != null) {
      cartItems = (json['produits'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList();
    }

    return Cart(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      produits: cartItems,
      totalPrix: double.parse((json['totalPrix'] ?? 0).toString()),
      codePromo: json['codePromo'],
      reduction: double.parse((json['réduction'] ?? 0).toString()),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      userDetails: json['userId'] is Map ? json['userId'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'produits': produits.map((item) => item.toJson()).toList(),
      'totalPrix': totalPrix,
      'codePromo': codePromo,
      'réduction': reduction,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Obtenir le prix total sans remise
  double get sousTotal {
    return produits.fold(0, (total, item) => total + item.totalPrix);
  }

  // Obtenir le montant de la remise
  double get montantReduction {
    return sousTotal * (reduction / 100);
  }

  // Obtenir le nombre total d'articles dans le panier
  int get nombreTotalArticles {
    return produits.fold(0, (total, item) => total + item.quantite);
  }

  // Vérifier si le panier est vide
  bool get estVide => produits.isEmpty;

  // Obtenir le nom du client depuis les détails si disponible
  String get nomClient {
    if (userDetails != null && userDetails!.containsKey('nom')) {
      return userDetails!['nom'];
    }
    return 'Client #$userId';
  }

  // Obtenir l'email du client depuis les détails si disponible
  String? get emailClient {
    if (userDetails != null && userDetails!.containsKey('email')) {
      return userDetails!['email'];
    }
    return null;
  }
} 