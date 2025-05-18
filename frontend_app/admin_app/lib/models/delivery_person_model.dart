class DeliveryPerson {
  final String id;
  final String nom;
  final String email;
  final String telephone;
  final String status;
  final int livraisons;
  final double rating;
  final String zone;
  final String vehicule;
  final String photo;
  final bool isActive;

  DeliveryPerson({
    required this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    this.status = 'Disponible',
    this.livraisons = 0,
    this.rating = 0.0,
    this.zone = '',
    this.vehicule = '',
    this.photo = 'https://picsum.photos/200/300',
    this.isActive = true,
  });

  factory DeliveryPerson.fromJson(Map<String, dynamic> json) {
    return DeliveryPerson(
      id: json['_id'] ?? json['id'] ?? '',
      nom: json['name'] ?? json['nom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['phone'] ?? json['telephone'] ?? '',
      status: json['status'] ?? (json['isActive'] == true ? 'Disponible' : 'Inactif'),
      livraisons: json['livraisons'] ?? json['totalDeliveries'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      zone: json['zone'] ?? '',
      vehicule: json['vehicule'] ?? '',
      photo: json['photo'] ?? json['avatar'] ?? 'https://picsum.photos/200/300',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': nom,
      'email': email,
      'phone': telephone,
      'status': status,
      'livraisons': livraisons,
      'rating': rating,
      'zone': zone,
      'vehicule': vehicule,
      'photo': photo,
      'isActive': isActive,
    };
  }

  DeliveryPerson copyWith({
    String? id,
    String? nom,
    String? email,
    String? telephone,
    String? status,
    int? livraisons,
    double? rating,
    String? zone,
    String? vehicule,
    String? photo,
    bool? isActive,
  }) {
    return DeliveryPerson(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      status: status ?? this.status,
      livraisons: livraisons ?? this.livraisons,
      rating: rating ?? this.rating,
      zone: zone ?? this.zone,
      vehicule: vehicule ?? this.vehicule,
      photo: photo ?? this.photo,
      isActive: isActive ?? this.isActive,
    );
  }
} 