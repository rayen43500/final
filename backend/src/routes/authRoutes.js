const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const { auth } = require('../middlewares/auth');
// Importation des limiteurs désactivée pour développement
// const { loginLimiter, registerLimiter, resetPasswordLimiter } = require('../middlewares/rateLimiter');

// Validation des données
const validateRegister = [
  body('nom').trim().notEmpty().withMessage('Le nom est requis'),
  body('email').isEmail().withMessage('Email invalide'),
  body('motDePasse')
    .isLength({ min: 8 })
    .withMessage('Le mot de passe doit contenir au moins 8 caractères')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/)
    .withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial')
];

const validateLogin = [
  body('email').isEmail().withMessage('Email invalide'),
  body('motDePasse').notEmpty().withMessage('Le mot de passe est requis')
];

const validateResetPassword = [
  body('motDePasse')
    .isLength({ min: 8 })
    .withMessage('Le mot de passe doit contenir au moins 8 caractères')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/)
    .withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial')
];

const validateChangePassword = [
  body('currentPassword').notEmpty().withMessage('Le mot de passe actuel est requis'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('Le mot de passe doit contenir au moins 8 caractères')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/)
    .withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial'),
  body('userId').notEmpty().withMessage('L\'identifiant utilisateur est requis')
];

// Routes - REMARQUE: Les limiteurs ont été retirés pour le développement
// En production, réactiver les limiteurs pour la sécurité
router.post('/register', validateRegister, authController.register); // registerLimiter retiré
router.post('/login', validateLogin, authController.login); // loginLimiter retiré
router.get('/verify-email/:token', authController.verifyEmail);
router.post('/forgot-password', authController.forgotPassword); // resetPasswordLimiter retiré
router.post('/reset-password/:token', validateResetPassword, authController.resetPassword);
router.post('/refresh-token', authController.refreshToken);
router.post('/change-password', auth, validateChangePassword, authController.changePassword);

module.exports = router; 