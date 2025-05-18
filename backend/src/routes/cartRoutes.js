const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');
const { protect } = require('../middleware/auth');
const validateObjectId = require('../middleware/validateObjectId');
const { rateLimit } = require('express-rate-limit');

// Rate limiter pour les endpoints panier
const cartLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limite à 100 requêtes par fenêtre
  message: 'Trop de requêtes, veuillez réessayer plus tard.'
});

// Appliquer le rate limiting à toutes les routes du panier
router.use(cartLimiter);

// Routes protégées par authentification
router.use(protect);

// Obtenir le panier de l'utilisateur
router.get('/', cartController.getCart);

// Synchroniser le panier avec le backend
router.post('/sync', cartController.syncCart);

// Ajouter un produit au panier
router.post('/', cartController.addToCart);

// Mettre à jour la quantité d'un produit
router.put('/:produitId', validateObjectId('produitId'), cartController.updateQuantity);

// Supprimer un produit du panier
router.delete('/:produitId', validateObjectId('produitId'), cartController.removeFromCart);

// Vider le panier
router.delete('/', cartController.clearCart);

// Appliquer un code promo
router.post('/coupon', cartController.applyPromoCode);

module.exports = router; 