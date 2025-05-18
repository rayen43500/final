# API E-Commerce - Documentation Backend

## Vue d'ensemble
Cette application backend fournit une API complète pour une plateforme e-commerce, avec gestion des produits, des utilisateurs, des commandes, du panier, des paiements, des promotions et des livraisons.

## Technologies utilisées
- Node.js
- Express.js
- MongoDB avec Mongoose
- JWT pour l'authentification
- Stripe (intégration de paiement)
- Express Rate Limit pour la protection contre les abus

## Modèles de données

### 1. Utilisateur (User)
- Authentification (email/mot de passe)
- Rôles (client, admin)
- Profil avec informations de contact

### 2. Produit (Product)
- Informations détaillées (nom, description, prix)
- Gestion des stocks avec statut de disponibilité
- Système d'avis et de notations
- Catégorisation
- Images multiples

### 3. Catégorie (Category)
- Organisation hiérarchique des produits
- Attributs pour filtrage

### 4. Panier (Cart)
- Gestion temporaire des produits avant achat
- Calcul dynamique des prix et quantités
- Support pour codes promo

### 5. Commande (Order)
- Suivi du statut de la commande
- Produits commandés avec quantités et prix
- Adresse de livraison
- Statut de paiement
- Lien avec livreur

### 6. Paiement (Payment)
- Différentes méthodes (carte, PayPal, espèces)
- Statut de paiement
- Sécurisation des transactions

### 7. Promotion (Promotion)
- Réductions par produit ou catégorie
- Types de réductions (pourcentage ou montant fixe)
- Validité temporelle
- Codes promo

### 8. Livreur (DeliveryPerson)
- Gestion des livreurs
- Commandes assignées
- Confirmation de livraison

## APIs disponibles

### 1. Authentification
- `POST /api/auth/register` : Inscription
- `POST /api/auth/login` : Connexion
- `GET /api/auth/me` : Profil utilisateur connecté
- `PUT /api/auth/me` : Mise à jour du profil

### 2. Produits
- `GET /api/produits` : Liste des produits avec filtres et pagination
- `GET /api/produits/:id` : Détails d'un produit
- `POST /api/produits` : Création d'un produit (admin)
- `PUT /api/produits/:id` : Mise à jour d'un produit (admin)
- `GET /api/produits/search` : Recherche de produits
- `POST /api/produits/:id/review` : Ajouter un avis
- `POST /api/produits/:id/restock` : Réapprovisionner le stock (admin)
- `GET /api/produits/inventory/low-stock` : Produits en rupture ou stock faible (admin)

### 3. Catégories
- `GET /api/categories` : Liste des catégories
- `GET /api/categories/:id` : Détails d'une catégorie
- `POST /api/categories` : Création d'une catégorie (admin)
- `PUT /api/categories/:id` : Mise à jour d'une catégorie (admin)

### 4. Panier
- `GET /api/panier` : Consulter le panier
- `POST /api/panier` : Ajouter un produit au panier
- `PUT /api/panier/:produitId` : Mettre à jour la quantité
- `DELETE /api/panier/:produitId` : Supprimer un produit du panier
- `DELETE /api/panier` : Vider le panier
- `POST /api/panier/coupon` : Appliquer un code promo

### 5. Commandes
- `POST /api/commandes` : Créer une commande
- `GET /api/commandes` : Liste des commandes de l'utilisateur
- `GET /api/commandes/:id` : Détails d'une commande (admin)
- `PUT /api/commandes/:id` : Modifier le statut (admin)
- `PUT /api/commandes/:id/assign` : Assigner un livreur (admin)

### 6. Paiements
- `POST /api/payments` : Traiter un paiement
- `GET /api/payments/:id` : Consulter un paiement (admin)
- `PUT /api/payments/:id/validate` : Valider un paiement en espèces (admin)
- `PUT /api/payments/:id/cancel` : Annuler un paiement (admin)

### 7. Promotions
- `GET /api/promotions/product/:productId` : Promotions pour un produit
- `POST /api/promotions/apply-code` : Appliquer un code promo
- `POST /api/promotions` : Créer une promotion (admin)
- `GET /api/promotions` : Liste des promotions (admin)
- `PUT /api/promotions/:id` : Modifier une promotion (admin)
- `DELETE /api/promotions/:id` : Supprimer une promotion (admin)

### 8. Livreurs
- `POST /api/delivery/login` : Connexion livreur
- `GET /api/delivery/profile` : Profil du livreur
- `GET /api/delivery/orders` : Commandes assignées
- `GET /api/delivery/orders/:id/client-info` : Info client pour livraison
- `PUT /api/delivery/orders/:id/confirm` : Confirmer livraison/paiement

### 9. Administration
- `POST /api/admin/delivery-persons` : Créer un livreur
- `GET /api/admin/delivery-persons` : Liste des livreurs
- `PUT /api/admin/delivery-persons/:id` : Modifier un livreur
- `DELETE /api/admin/delivery-persons/:id` : Supprimer un livreur
- `GET /api/admin/delivery-stats` : Statistiques de livraison

## Scénarios d'utilisation

### 1. Gestion des produits et du stock
- Les produits sont automatiquement marqués comme "Indisponibles" quand leur stock atteint zéro
- Le système vérifie la disponibilité avant d'ajouter au panier ou de créer une commande
- Les administrateurs peuvent réapprovisionner le stock et surveiller les produits en stock faible

### 2. Processus d'achat complet
1. L'utilisateur ajoute des produits à son panier
2. Il peut appliquer des codes promo ou bénéficier de promotions actives
3. Il valide sa commande en fournissant une adresse de livraison
4. Il choisit un mode de paiement (carte, PayPal, espèces)
5. Le stock des produits est automatiquement mis à jour
6. L'administrateur peut assigner un livreur à la commande
7. Le livreur confirme la livraison et le paiement (si en espèces)

### 3. Gestion des promotions
- Les administrateurs peuvent créer des promotions sur des produits ou catégories
- Les promotions peuvent être en pourcentage ou montant fixe
- Les utilisateurs voient automatiquement les prix réduits
- Possibilité d'appliquer des codes promo supplémentaires

### 4. Système de livraison
1. L'administrateur assigne un livreur à une commande
2. Le livreur voit les commandes qui lui sont assignées
3. Il peut consulter les informations client pour la livraison
4. Il confirme la livraison et collecte le paiement si nécessaire
5. Le statut de la commande et du paiement est mis à jour automatiquement

## Sécurité
- Authentification par JWT avec différents rôles
- Rate limiting pour prévenir les attaques par force brute
- Validation des données d'entrée
- Protection des routes sensibles
- Vérification des stocks avant validation des commandes

## Architecture
- Structure MVC (Modèle-Vue-Contrôleur)
- Middlewares de sécurité et validation
- API RESTful avec endpoints bien définis
- Middlewares personnalisés pour l'authentification, l'autorisation et la validation
- Intégration de services tiers pour les paiements 

## Gestion Avancée des Stocks
Le système offre une gestion de stock robuste et complète avec les fonctionnalités suivantes :

### Traçabilité des Mouvements
- Historique complet de tous les mouvements de stock (entrées, sorties, ajustements, réservations)
- Chaque mouvement stocke la date, la quantité, la référence et l'utilisateur qui l'a effectué
- Filtrage de l'historique par période

### Alertes de Stock
- Seuil d'alerte personnalisable par produit
- Notification automatique en cas de stock faible
- Notification en cas de rupture de stock
- Configuration des préférences de notification par produit

### Opérations de Stock
- Réapprovisionnement avec traçabilité
- Ajustement de stock (inventaire)
- Réservation de stock
- Vérification de stock maximum pour éviter le surstockage

### Endpoints Spécifiques
- `POST /api/produits/:id/restock` : Réapprovisionner un produit
- `PUT /api/produits/:id/adjust-stock` : Ajuster le stock (inventaire)
- `PUT /api/produits/:id/stock-settings` : Configurer les paramètres de stock
- `GET /api/produits/:id/stock-history` : Consulter l'historique des mouvements
- `POST /api/produits/:id/reserve` : Réserver du stock
- `GET /api/produits/inventory/low-stock` : Obtenir la liste des produits en rupture ou stock faible 