const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const crypto = require('crypto');

// Générer un token JWT
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: '1h'
  });
};

// Générer un refresh token
const generateRefreshToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: '7d'
  });
};

// Inscription
exports.register = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { nom, email, motDePasse, telephone } = req.body;

    // Vérifier si l'utilisateur existe déjà
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé' });
    }

    // Créer un nouvel utilisateur
    user = new User({
      nom,
      email,
      motDePasse,
      telephone,
      role: req.body.role ? req.body.role.charAt(0).toUpperCase() + req.body.role.slice(1).toLowerCase() : 'Client'
    });

    // Générer le token de vérification
    const verificationToken = user.generateVerificationToken();
    await user.save();

    // TODO: Envoyer l'email de vérification
    // sendVerificationEmail(user.email, verificationToken);

    // Générer les tokens
    const token = generateToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    res.status(201).json({
      token,
      refreshToken,
      user: {
        id: user._id,
        nom: user.nom,
        email: user.email,
        telephone: user.telephone,
        role: user.role,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Connexion
exports.login = async (req, res) => {
  try {
    const { email, motDePasse } = req.body;

    // Vérifier si l'utilisateur existe
    const user = await User.findOne({ email }).select('+motDePasse');
    if (!user) {
      return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
    }

    console.log('Utilisateur trouvé:', user.email, 'Rôle:', user.role);

    // Vérifier si le compte est actif
    if (!user.isActive) {
      return res.status(403).json({ message: 'Ce compte a été désactivé' });
    }

    // Vérifier si le compte est bloqué
    if (user.lockUntil && user.lockUntil > Date.now()) {
      return res.status(403).json({ 
        message: 'Compte temporairement bloqué',
        retryAfter: Math.ceil((user.lockUntil - Date.now()) / 1000)
      });
    }

    try {
      // Vérifier le mot de passe
      const isMatch = await user.comparePassword(motDePasse);
      if (!isMatch) {
        await user.incrementLoginAttempts();
        return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
      }

      // Réinitialiser les tentatives de connexion
      await user.resetLoginAttempts();

      // Générer les tokens
      const token = generateToken(user._id);
      const refreshToken = generateRefreshToken(user._id);

      // Créer la réponse sans le mot de passe
      const userResponse = {
        id: user._id,
        nom: user.nom,
        email: user.email,
        telephone: user.telephone,
        role: user.role,
        isVerified: user.isVerified
      };

      res.json({
        token,
        refreshToken,
        user: userResponse
      });
    } catch (error) {
      console.error('Erreur lors de la vérification du mot de passe:', error);
      return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
    }
  } catch (error) {
    console.error('Erreur de connexion:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Vérification d'email
exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.params;
    
    const user = await User.findOne({ verificationToken: token });
    if (!user) {
      return res.status(400).json({ message: 'Token de vérification invalide' });
    }

    user.isVerified = true;
    user.verificationToken = undefined;
    await user.save();

    res.json({ message: 'Email vérifié avec succès' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Demande de réinitialisation de mot de passe
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Aucun utilisateur trouvé avec cet email' });
    }

    const resetToken = user.generateResetPasswordToken();
    await user.save();

    // TODO: Envoyer l'email de réinitialisation
    // sendResetPasswordEmail(user.email, resetToken);

    res.json({ message: 'Email de réinitialisation envoyé' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Réinitialisation de mot de passe
exports.resetPassword = async (req, res) => {
  try {
    const { token } = req.params;
    const { motDePasse } = req.body;

    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpire: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ message: 'Token invalide ou expiré' });
    }

    user.motDePasse = motDePasse;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;
    await user.save();

    res.json({ message: 'Mot de passe réinitialisé avec succès' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Rafraîchissement du token
exports.refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(401).json({ message: 'Refresh token manquant' });
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const user = await User.findById(decoded.userId);

    if (!user) {
      return res.status(401).json({ message: 'Utilisateur non trouvé' });
    }

    const token = generateToken(user._id);
    const newRefreshToken = generateRefreshToken(user._id);

    res.json({
      token,
      refreshToken: newRefreshToken
    });
  } catch (error) {
    console.error(error);
    res.status(401).json({ message: 'Refresh token invalide' });
  }
}; 

// Changement de mot de passe
exports.changePassword = async (req, res) => {
  try {
    const { userId, currentPassword, newPassword } = req.body;
    
    // Vérification que l'utilisateur est bien celui qui fait la demande
    if (req.user._id.toString() !== userId) {
      return res.status(403).json({ message: 'Vous n\'êtes pas autorisé à modifier ce mot de passe' });
    }
    
    // Récupérer l'utilisateur
    const user = await User.findById(userId).select('+motDePasse');
    
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }
    
    // Vérifier le mot de passe actuel
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ message: 'Mot de passe actuel incorrect' });
    }
    
    // Mettre à jour le mot de passe
    user.motDePasse = newPassword;
    await user.save();
    
    res.json({ message: 'Mot de passe modifié avec succès' });
  } catch (error) {
    console.error('Erreur lors du changement de mot de passe:', error);
    res.status(500).json({ message: 'Erreur serveur lors du changement de mot de passe' });
  }
}; 