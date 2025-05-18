class User {
  final String id;
  final String nom;
  final String email;
  final String telephone;
  final String role;
  final bool isVerified;
  final bool isActive;
  
  User({
    required this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.role,
    required this.isVerified,
    required this.isActive,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] ?? 'Livreur',
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'role': role,
      'isVerified': isVerified,
      'isActive': isActive,
    };
  }
  
  bool isLivreur() {
    return role == 'Livreur';
  }
} 