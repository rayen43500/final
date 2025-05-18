const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { protect, admin } = require('../middleware/auth');
const validateObjectId = require('../middleware/validateObjectId');
const { rateLimit } = require('express-rate-limit');

// Rate limiter pour les endpoints commandes
const orderLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 60, // Limite à 60 requêtes par fenêtre
  message: 'Trop de requêtes, veuillez réessayer plus tard.'
});

// Appliquer le rate limiting à toutes les routes
router.use(orderLimiter);

// Routes protégées par authentification
router.use(protect);

// Routes pour les clients
router.post('/', orderController.createOrder);
router.get('/', orderController.getUserOrders);
router.get('/mobile/mes-commandes', orderController.getUserOrders); // Endpoint mobile spécifique
router.get('/:id', validateObjectId(), orderController.getUserOrderDetails);
router.get('/mobile/:id', validateObjectId(), orderController.getUserOrderDetails); // Endpoint mobile spécifique

// Routes pour les livreurs
router.get('/delivery/mes-livraisons', orderController.getDeliveryPersonOrders);
router.put('/delivery/:id/status', validateObjectId(), orderController.updateOrderStatusByDeliveryPerson);

// Routes pour les administrateurs
router.get('/admin/:id', admin, validateObjectId(), orderController.getOrder);
router.put('/:id/status', admin, validateObjectId(), orderController.updateOrderStatus);
router.put('/:id/assign', admin, validateObjectId(), orderController.assignDeliveryPerson);

module.exports = router; 