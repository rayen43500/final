const express = require('express');
const router = express.Router();
const { auth, isAdmin } = require('../middlewares/auth');
const categoryController = require('../controllers/categoryController');
const { body } = require('express-validator');

// Validation des données
const validateCategory = [
  body('nom').trim().notEmpty().withMessage('Le nom de la catégorie est requis'),
  body('description').optional().trim(),
  body('parentCategory').optional().isMongoId().withMessage('ID de catégorie parent invalide'),
  body('colorName').optional().isIn(['blue', 'red', 'green', 'orange', 'purple', 'teal', 'pink', 'amber', 'indigo', 'cyan']),
  body('iconName').optional().isIn(['devices', 'headphones', 'computer', 'watch', 'speaker', 'home', 'phone_android', 'tv', 'camera_alt', 'videogame_asset', 'sports_esports', 'memory', 'category'])
];

// Routes publiques
router.get('/', categoryController.getCategories);
router.get('/:id', categoryController.getCategoryById);

// Route pour les statistiques (protégée Admin)
router.get('/stats/all', auth, isAdmin, categoryController.getCategoryStats);

// Routes protégées (Admin)
router.post('/', auth, isAdmin, validateCategory, categoryController.createCategory);
router.put('/:id', auth, isAdmin, validateCategory, categoryController.updateCategory);
router.delete('/:id', auth, isAdmin, categoryController.deleteCategory);

module.exports = router; 