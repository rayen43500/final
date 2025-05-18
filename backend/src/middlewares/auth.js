const jwt = require('jsonwebtoken');
const User = require('../models/User');

const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ message: 'Accès non autorisé. Token manquant.' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-motDePasse');

    if (!user) {
      return res.status(401).json({ message: 'Accès non autorisé. Utilisateur non trouvé.' });
    }

    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Accès non autorisé. Token invalide.' });
  }
};

const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'Admin') {
    next();
  } else {
    res.status(403).json({ message: 'Accès interdit. Droits administrateur requis.' });
  }
};

module.exports = { auth, isAdmin }; 