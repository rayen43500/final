class AppConstants {
  // Noms d'application
  static const String appName = 'BIN FLOW Livraison';
  static const String appTagline = 'Livraison d\'artisanat éco-responsable';
  
  // Livraisons
  static const String deliveries = 'Livraisons';
  static const String myDeliveries = 'Mes livraisons';
  static const String availableDeliveries = 'Livraisons disponibles';
  static const String completedDeliveries = 'Livraisons terminées';
  static const String pendingDeliveries = 'Livraisons en attente';
  static const String inProgressDeliveries = 'Livraisons en cours';
  
  // Détails de livraison
  static const String deliveryDetails = 'Détails de la livraison';
  static const String pickupPoint = 'Point de collecte';
  static const String deliveryPoint = 'Point de livraison';
  static const String deliveryDate = 'Date de livraison';
  static const String deliveryTime = 'Heure de livraison';
  static const String estimatedDelivery = 'Livraison estimée';
  static const String deliveryStatus = 'Statut de la livraison';
  static const String deliveryDistance = 'Distance';
  static const String deliveryInstructions = 'Instructions de livraison';
  
  // Éco-responsabilité
  static const String ecoFriendlyDelivery = 'Livraison éco-responsable';
  static const String carbonFootprint = 'Empreinte carbone';
  static const String sustainablePackaging = 'Emballage durable';
  static const String ecoPackagingInfo = 'Information sur l\'emballage éco';
  static const String sustainableTransport = 'Transport durable';
  
  // Clients et commandes
  static const String customer = 'Client';
  static const String customerDetails = 'Détails du client';
  static const String customerName = 'Nom du client';
  static const String customerPhone = 'Téléphone du client';
  static const String customerAddress = 'Adresse du client';
  static const String orderDetails = 'Détails de la commande';
  static const String orderItems = 'Créations commandées';
  static const String fragileItems = 'Créations fragiles';
  static const String specialCare = 'Soin particulier';
  
  // Actions
  static const String acceptDelivery = 'Accepter la livraison';
  static const String startDelivery = 'Commencer la livraison';
  static const String completeDelivery = 'Terminer la livraison';
  static const String cancelDelivery = 'Annuler la livraison';
  static const String contactCustomer = 'Contacter le client';
  static const String contactSupport = 'Contacter le support';
  static const String takePhoto = 'Prendre une photo';
  static const String uploadProof = 'Télécharger une preuve';
  
  // Navigation
  static const String login = 'Connexion';
  static const String logout = 'Déconnexion';
  static const String profile = 'Profil';
  static const String settings = 'Paramètres';
  static const String help = 'Aide';
  static const String about = 'À propos';
  
  // Statuts de livraison
  static const String statusPending = 'En attente';
  static const String statusAccepted = 'Acceptée';
  static const String statusPickedUp = 'Collectée';
  static const String statusInTransit = 'En transit';
  static const String statusDelivered = 'Livrée';
  static const String statusCancelled = 'Annulée';
  
  // Messages
  static const String noDeliveries = 'Aucune livraison disponible';
  static const String successDelivery = 'Livraison terminée avec succès';
  static const String errorDelivery = 'Erreur lors de la livraison';
  static const String confirmDelivery = 'Confirmer la livraison';
  static const String confirmDeliveryMessage = 'Êtes-vous sûr de vouloir marquer cette livraison comme terminée?';
  
  // Types d'emballages écologiques
  static const List<String> ecoPackagingTypes = [
    'Papier kraft recyclé',
    'Carton recyclé',
    'Papier de soie biodégradable',
    'Tissu réutilisable',
    'Paille biodégradable', 
    'Sacs en papier',
    'Boîtes en carton',
    'Ruban en fibres naturelles',
    'Papier bulle biodégradable',
    'Matériaux de calage compostables'
  ];
} 