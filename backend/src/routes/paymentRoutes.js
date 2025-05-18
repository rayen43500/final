const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { protect, admin } = require('../middleware/auth');
const validateObjectId = require('../middleware/validateObjectId');
const { rateLimit } = require('express-rate-limit');

// Rate limiter pour les endpoints paiements
const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // Limite à 30 requêtes par fenêtre
  message: 'Trop de requêtes, veuillez réessayer plus tard.'
});

// Appliquer le rate limiting à toutes les routes
router.use(paymentLimiter);

// Routes nécessitant une authentification
router.use(protect);

// Route pour le traitement des paiements (client)
router.post('/', paymentController.processPayment);

// Routes pour l'administration (admin uniquement)
router.get('/:id', admin, validateObjectId(), paymentController.getPaymentDetails);
router.put('/:id/validate', admin, validateObjectId(), paymentController.validateCashPayment);
router.put('/:id/cancel', admin, validateObjectId(), paymentController.cancelPayment);

module.exports = router; 