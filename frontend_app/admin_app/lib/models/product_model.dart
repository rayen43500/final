// Modèle de produit
class Product {
  final String id;
  final String nom;
  final double prix;
  final int stock;
  final String description;
  final List<String> images;
  final String categorie; // Nom de la catégorie
  final String? categorieId; // ID de la catégorie
  final bool disponible;
  final double? prixPromo;
  final double? reduction;

  Product({
    required this.id,
    required this.nom,
    required this.prix,
    required this.stock,
    required this.description,
    required this.images,
    required this.categorie,
    this.categorieId,
    required this.disponible,
    this.prixPromo,
    this.reduction,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final product = Product(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      prix: (json['prix'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      description: json['description'] ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      categorie: json['categoryId'] is Map ? json['categoryId']['nom'] ?? 'Non catégorisé' : 'Non catégorisé',
      categorieId: json['categoryId'] is Map ? json['categoryId']['_id'] ?? null : json['categoryId']?.toString(),
      disponible: json['isActive'] ?? false && (json['stock'] ?? 0) > 0,
      prixPromo: json['prixPromo'] != null ? (json['prixPromo'] is num ? json['prixPromo'].toDouble() : double.tryParse(json['prixPromo'].toString())) : null,
      reduction: json['reduction'] != null ? (json['reduction'] is num ? json['reduction'].toDouble() : double.tryParse(json['reduction'].toString())) : null,
    );
    
    return product;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'prix': prix,
      'stock': stock,
      'description': description,
      'images': images,
      'categoryId': categorieId,
      'categorie': categorie,
      'isActive': disponible,
      'prixPromo': prixPromo,
      'reduction': reduction,
    };
  }

  // Copier avec des modifications
  Product copyWith({
    String? id,
    String? nom,
    double? prix,
    int? stock,
    String? description,
    List<String>? images,
    String? categorie,
    String? categorieId,
    bool? disponible,
    double? prixPromo,
    double? reduction,
  }) {
    return Product(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      images: images ?? this.images,
      categorie: categorie ?? this.categorie,
      categorieId: categorieId ?? this.categorieId,
      disponible: disponible ?? this.disponible,
      prixPromo: prixPromo ?? this.prixPromo,
      reduction: reduction ?? this.reduction,
    );
  }
}

// Modèle de catégorie
class Category {
  final String id;
  final String nom;
  final String description;
  final String slug;
  final bool isActive;
  final String? colorName;
  final String? iconName;
  final int? productCount;

  Category({
    required this.id,
    required this.nom,
    required this.description,
    required this.slug,
    required this.isActive,
    this.colorName,
    this.iconName,
    this.productCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      slug: json['slug'] ?? '',
      isActive: json['isActive'] ?? true,
      colorName: json['colorName'],
      iconName: json['iconName'],
      productCount: json['productCount'] != null ? int.tryParse(json['productCount'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'description': description,
      'slug': slug,
      'isActive': isActive,
      'colorName': colorName,
      'iconName': iconName,
      'productCount': productCount,
    };
  }
} 