const express = require('express');
const router = express.Router();
const deliveryController = require('../controllers/deliveryController');
const deliveryAuth = require('../middleware/deliveryAuth');
const validateObjectId = require('../middleware/validateObjectId');

// Appliquer le rate limiting à toutes les routes
router.use(deliveryController.deliveryLimiter);

// Route pour l'authentification des livreurs (accessible sans authentification)
router.post('/login', deliveryController.login);

// Routes protégées par authentification de livreur
router.use(deliveryAuth);

// Récupérer le profil du livreur connecté
router.get('/profile', deliveryController.getProfile);

// Récupérer les commandes assignées au livreur
router.get('/orders', deliveryController.getAssignedOrders);

// Récupérer les détails d'une commande spécifique
router.get('/orders/:id', validateObjectId('id'), deliveryController.getOrderDetails);

// Récupérer les informations client d'une commande
router.get('/orders/:id/client-info', validateObjectId('id'), deliveryController.getClientInfo);

// Confirmer la livraison et le paiement d'une commande
router.put('/orders/:id/confirm', validateObjectId('id'), deliveryController.confirmDelivery);

module.exports = router; 