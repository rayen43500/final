const jwt = require('jsonwebtoken');
const DeliveryPerson = require('../models/DeliveryPerson');

/**
 * Middleware pour authentifier les livreurs
 * Vérifie le token JWT et ajoute l'objet livreur à la requête
 */
const deliveryAuth = async (req, res, next) => {
  try {
    // Vérifier si le token est présent dans l'en-tête Authorization
    const token = req.header('Authorization').replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ message: 'Authentification requise' });
    }
    
    // Vérifier et décoder le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Vérifier que le rôle est 'livreur'
    if (decoded.role !== 'livreur') {
      return res.status(403).json({ message: 'Accès non autorisé' });
    }
    
    // Récupérer le livreur correspondant
    const deliveryPerson = await DeliveryPerson.findOne({ 
      _id: decoded.id,
      isActive: true
    });
    
    if (!deliveryPerson) {
      return res.status(401).json({ message: 'Compte de livreur non trouvé ou désactivé' });
    }
    
    // Ajouter le livreur à l'objet requête
    req.deliveryPerson = deliveryPerson;
    req.token = token;
    
    next();
  } catch (error) {
    res.status(401).json({ message: 'Veuillez vous authentifier', error: error.message });
  }
};

module.exports = deliveryAuth; 