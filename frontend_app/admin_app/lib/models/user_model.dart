class User {
  final String id;
  final String nom;
  final String email;
  final String telephone;
  final String dateInscription;
  final String role;
  final String status;
  final int commandes;
  final String adresse;
  final bool isVerified;
  final bool isActive;
  final String? livreurId;
  final String? livreurName;

  User({
    required this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.dateInscription,
    required this.role,
    required this.status,
    required this.commandes,
    required this.adresse,
    this.isVerified = false,
    this.isActive = true,
    this.livreurId,
    this.livreurName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Extraire la date de création de createdAt ou dateInscription
    String dateInscription = '';
    if (json['createdAt'] != null) {
      try {
        final date = DateTime.parse(json['createdAt']);
        dateInscription = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        dateInscription = json['createdAt'] ?? '';
      }
    } else {
      dateInscription = json['dateInscription'] ?? '';
    }
    
    // Convertir l'isActive en status
    String status = 'Actif';
    if (json['isActive'] != null && json['isActive'] == false) {
      status = 'Inactif';
    } else if (json['status'] != null) {
      status = json['status'];
    }
    
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      dateInscription: dateInscription,
      role: json['role'] ?? 'Client',
      status: status,
      commandes: json['commandes'] ?? 0,
      adresse: json['adresse'] ?? '',
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      livreurId: json['livreurId'],
      livreurName: json['livreurName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'dateInscription': dateInscription,
      'role': role,
      'status': status,
      'isActive': isActive,
      'isVerified': isVerified,
      'commandes': commandes,
      'adresse': adresse,
      'livreurId': livreurId,
      'livreurName': livreurName,
    };
  }

  User copyWith({
    String? id,
    String? nom,
    String? email,
    String? telephone,
    String? dateInscription,
    String? role,
    String? status,
    bool? isActive,
    bool? isVerified,
    int? commandes,
    String? adresse,
    String? livreurId,
    String? livreurName,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      dateInscription: dateInscription ?? this.dateInscription,
      role: role ?? this.role,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      commandes: commandes ?? this.commandes,
      adresse: adresse ?? this.adresse,
      livreurId: livreurId ?? this.livreurId,
      livreurName: livreurName ?? this.livreurName,
    );
  }
} 