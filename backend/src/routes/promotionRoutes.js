const express = require('express');
const router = express.Router();
const promotionController = require('../controllers/promotionController');
const { protect, admin } = require('../middleware/auth');
const validateObjectId = require('../middleware/validateObjectId');
const { rateLimit } = require('express-rate-limit');

// Rate limiter pour les endpoints promotions
const promotionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Limite à 50 requêtes par fenêtre
  message: 'Trop de requêtes, veuillez réessayer plus tard.'
});

// Appliquer le rate limiting à toutes les routes
router.use(promotionLimiter);

// Routes publiques
router.get('/product/:productId', validateObjectId('productId'), promotionController.getProductPromotions);
router.post('/apply-code', promotionController.applyPromoCode);

// Routes nécessitant authentification et droits admin
router.use(protect);
router.use(admin);

// Routes admin pour la gestion des promotions
router.post('/', promotionController.createPromotion);
router.get('/', promotionController.getAllPromotions);
router.get('/:id', validateObjectId(), promotionController.getPromotionById);
router.put('/:id', validateObjectId(), promotionController.updatePromotion);
router.delete('/:id', validateObjectId(), promotionController.deletePromotion);

module.exports = router; 