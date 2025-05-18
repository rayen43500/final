const express = require('express');
const router = express.Router();
const { auth, isAdmin } = require('../middlewares/auth');
const userController = require('../controllers/userController');

// Routes protégées
router.get('/me', auth, userController.getProfile);

// Route pour le comptage des utilisateurs (pour le dashboard)
router.get('/count', auth, isAdmin, userController.getUserCount);

router.get('/', auth, isAdmin, userController.getUsers);
router.patch('/:id/disable', auth, isAdmin, userController.disableUser);
router.patch('/:id/enable', auth, isAdmin, userController.enableUser);

module.exports = router; 