const rateLimit = require('express-rate-limit');

// REMARQUE: Les limiteurs ont été désactivés en augmentant considérablement les valeurs
// En production, il est recommandé de remettre des valeurs plus restrictives pour la sécurité

// Limite pour les tentatives de connexion (désactivée)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Valeur très élevée pour désactiver pratiquement la limitation
  message: 'Trop de tentatives de connexion. Veuillez réessayer plus tard.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Limite pour les inscriptions (désactivée)
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 1000, // Valeur très élevée pour désactiver pratiquement la limitation
  message: 'Trop de tentatives d\'inscription. Veuillez réessayer plus tard.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Limite pour les demandes de réinitialisation de mot de passe (désactivée)
const resetPasswordLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 1000, // Valeur très élevée pour désactiver pratiquement la limitation
  message: 'Trop de demandes de réinitialisation. Veuillez réessayer plus tard.',
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  loginLimiter,
  registerLimiter,
  resetPasswordLimiter
}; 