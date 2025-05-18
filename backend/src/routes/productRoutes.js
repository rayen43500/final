const express = require('express');
const router = express.Router();
const { auth, isAdmin } = require('../middlewares/auth');
const productController = require('../controllers/productController');
const { body } = require('express-validator');

// Validation des données
const validateProduct = [
  body('nom').trim().notEmpty().withMessage('Le nom du produit est requis'),
  body('description').trim().notEmpty().withMessage('La description est requise'),
  body('prix').isFloat({ min: 0 }).withMessage('Le prix doit être un nombre positif'),
  body('prixPromo').optional().isFloat({ min: 0 }).withMessage('Le prix promo doit être un nombre positif'),
  body('discount').optional().isInt({ min: 0, max: 100 }).withMessage('La réduction doit être entre 0 et 100'),
  body('images').isArray({ min: 1 }).withMessage('Au moins une image est requise'),
  body('stock').isInt({ min: 0 }).withMessage('Le stock doit être un nombre positif'),
  body('categoryId').isMongoId().withMessage('ID de catégorie invalide')
];

const validateReview = [
  body('note').isInt({ min: 1, max: 5 }).withMessage('La note doit être entre 1 et 5'),
  body('commentaire').trim().notEmpty().withMessage('Le commentaire est requis')
];

/**
 * @swagger
 * components:
 *   schemas:
 *     Product:
 *       type: object
 *       required:
 *         - nom
 *         - description
 *         - prix
 *         - images
 *         - stock
 *         - categoryId
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated ID
 *         nom:
 *           type: string
 *           description: Product name
 *         description:
 *           type: string
 *           description: Product description
 *         prix:
 *           type: number
 *           description: Product price
 *         prixPromo:
 *           type: number
 *           description: Promotional price
 *         discount:
 *           type: number
 *           description: Discount percentage (0-100)
 *         images:
 *           type: array
 *           items:
 *             type: string
 *           description: Array of image URLs
 *         stock:
 *           type: integer
 *           description: Available quantity
 *         categoryId:
 *           type: string
 *           description: Category ID
 *         isActive:
 *           type: boolean
 *           description: Product availability status
 */

/**
 * @swagger
 * /api/produits:
 *   get:
 *     summary: Get all products
 *     description: Retrieve a list of all products with optional filtering
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Number of items per page
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by category
 *     responses:
 *       200:
 *         description: A list of products
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 products:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Product'
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 pages:
 *                   type: integer
 */
router.get('/', productController.getProducts);

/**
 * @swagger
 * /api/produits/search:
 *   get:
 *     summary: Search products
 *     description: Search products by name or description
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *         required: true
 *         description: Search query
 *     responses:
 *       200:
 *         description: Search results
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Product'
 */
router.get('/search', productController.searchProducts);

/**
 * @swagger
 * /api/produits/{id}:
 *   get:
 *     summary: Get product by ID
 *     description: Retrieve a single product by its ID
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: Product ID
 *     responses:
 *       200:
 *         description: Product details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Product'
 *       404:
 *         description: Product not found
 */
router.get('/:id', productController.getProductById);

/**
 * @swagger
 * /api/produits/{id}/review:
 *   post:
 *     summary: Add a review to a product
 *     description: Add a review with rating and comment to a product
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: Product ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - note
 *               - commentaire
 *             properties:
 *               note:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *                 description: Rating (1-5)
 *               commentaire:
 *                 type: string
 *                 description: Review comment
 *     responses:
 *       200:
 *         description: Review added successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Product not found
 */
router.post('/:id/review', auth, validateReview, productController.addReview);

/**
 * @swagger
 * /api/produits:
 *   post:
 *     summary: Create a new product
 *     description: Create a new product (admin only)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Product'
 *     responses:
 *       201:
 *         description: Product created successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin access required
 */
router.post('/', auth, isAdmin, validateProduct, productController.createProduct);

/**
 * @swagger
 * /api/produits/{id}:
 *   put:
 *     summary: Update a product
 *     description: Update an existing product (admin only)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: Product ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Product'
 *     responses:
 *       200:
 *         description: Product updated successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin access required
 *       404:
 *         description: Product not found
 */
router.put('/:id', auth, isAdmin, validateProduct, productController.updateProduct);

/**
 * @swagger
 * /api/produits/{id}/restock:
 *   post:
 *     summary: Restock a product
 *     description: Add stock to an existing product (admin only)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: Product ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - quantity
 *             properties:
 *               quantity:
 *                 type: integer
 *                 minimum: 1
 *                 description: Quantity to add
 *               référence:
 *                 type: string
 *                 description: Reference for the restock operation
 *               commentaire:
 *                 type: string
 *                 description: Additional notes
 *     responses:
 *       200:
 *         description: Product restocked successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin access required
 *       404:
 *         description: Product not found
 */
router.post('/:id/restock', auth, isAdmin, productController.restockProduct);

// Nouvelles routes pour la gestion avancée des stocks
router.put('/:id/adjust-stock', auth, isAdmin, productController.adjustStock);
router.put('/:id/stock-settings', auth, isAdmin, productController.configureStockSettings);
router.get('/:id/stock-history', auth, isAdmin, productController.getStockHistory);
router.post('/:id/reserve', auth, productController.reserveStock);

// Exporter le router
module.exports = router; 