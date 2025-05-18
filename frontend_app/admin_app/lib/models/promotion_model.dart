class Promotion {
  final String id;
  final String nom;
  final String? description;
  final String type; // 'produit' ou 'categorie'
  final String cible; // ID du produit ou de la catégorie
  final String typeRef; // Type de référence (Product ou Category)
  final String typeReduction; // 'pourcentage', 'montant' ou 'livraison'
  final double valeurReduction;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? codePromo;
  final bool isActive;
  final int utilisations;
  final int? limiteUtilisations;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.nom,
    this.description,
    required this.type,
    required this.cible,
    required this.typeRef,
    required this.typeReduction,
    required this.valeurReduction,
    required this.dateDebut,
    required this.dateFin,
    this.codePromo,
    required this.isActive,
    required this.utilisations,
    this.limiteUtilisations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      type: json['type'] ?? '',
      cible: json['cible'] ?? '',
      typeRef: json['typeRef'] ?? '',
      typeReduction: json['typeReduction'] ?? '',
      valeurReduction: double.parse(json['valeurReduction']?.toString() ?? '0'),
      dateDebut: json['dateDebut'] != null ? DateTime.parse(json['dateDebut']) : DateTime.now(),
      dateFin: json['dateFin'] != null ? DateTime.parse(json['dateFin']) : DateTime.now().add(const Duration(days: 30)),
      codePromo: json['codePromo'],
      isActive: json['isActive'] ?? false,
      utilisations: json['utilisations'] ?? 0,
      limiteUtilisations: json['limiteUtilisations'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'description': description,
      'type': type,
      'cible': cible,
      'typeRef': typeRef,
      'typeReduction': typeReduction,
      'valeurReduction': valeurReduction,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'codePromo': codePromo,
      'isActive': isActive,
      'utilisations': utilisations,
      'limiteUtilisations': limiteUtilisations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Vérifier si la promotion est valide à une date donnée
  bool isValidAt(DateTime date) {
    return isActive && dateDebut.isBefore(date) && dateFin.isAfter(date);
  }

  // Formatter les dates en format lisible
  String get dateDebutFormatted {
    return '${dateDebut.day.toString().padLeft(2, '0')}/${dateDebut.month.toString().padLeft(2, '0')}/${dateDebut.year}';
  }

  String get dateFinFormatted {
    return '${dateFin.day.toString().padLeft(2, '0')}/${dateFin.month.toString().padLeft(2, '0')}/${dateFin.year}';
  }

  // Calculer le prix réduit pour un prix donné
  double calculerPrixReduit(double prixOriginal) {
    if (typeReduction == 'pourcentage') {
      return prixOriginal * (1 - valeurReduction / 100);
    } else if (typeReduction == 'montant') {
      final prixReduit = prixOriginal - valeurReduction;
      return prixReduit > 0 ? prixReduit : 0;
    } else {
      return prixOriginal;
    }
  }

  // Obtenir le statut de la promotion
  String get statusText {
    final now = DateTime.now();
    
    if (!isActive) {
      return 'Inactif';
    } else if (dateFin.isBefore(now)) {
      return 'Expiré';
    } else if (dateDebut.isAfter(now)) {
      return 'À venir';
    } else {
      return 'Actif';
    }
  }

  // Obtenir la couleur du statut
  String get statusColor {
    switch (statusText) {
      case 'Inactif':
        return 'grey';
      case 'Expiré':
        return 'red';
      case 'À venir':
        return 'orange';
      case 'Actif':
        return 'green';
      default:
        return 'grey';
    }
  }
} 