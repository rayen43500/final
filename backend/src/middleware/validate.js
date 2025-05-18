const { ObjectId } = require('mongoose').Types;

const validateObjectId = (req, res, next) => {
  const { id } = req.params;
  
  if (!ObjectId.isValid(id)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid ID format'
    });
  }
  
  next();
};

const validateProductData = (req, res, next) => {
  const { nom, description, prix, stock, categorie } = req.body;
  
  if (!nom || !description || !prix || !stock || !categorie) {
    return res.status(400).json({
      success: false,
      error: 'Missing required fields'
    });
  }
  
  if (typeof prix !== 'number' || prix <= 0) {
    return res.status(400).json({
      success: false,
      error: 'Invalid price'
    });
  }
  
  if (typeof stock !== 'number' || stock < 0) {
    return res.status(400).json({
      success: false,
      error: 'Invalid stock quantity'
    });
  }
  
  next();
};

const validateUserData = (req, res, next) => {
  const { email, password, nom, prenom } = req.body;
  
  if (!email || !password || !nom || !prenom) {
    return res.status(400).json({
      success: false,
      error: 'Missing required fields'
    });
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid email format'
    });
  }
  
  if (password.length < 6) {
    return res.status(400).json({
      success: false,
      error: 'Password must be at least 6 characters long'
    });
  }
  
  next();
};

const validateOrderData = (req, res, next) => {
  const { produits, adresseLivraison, methodePaiement } = req.body;
  
  if (!produits || !Array.isArray(produits) || produits.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Invalid products data'
    });
  }
  
  if (!adresseLivraison || typeof adresseLivraison !== 'object') {
    return res.status(400).json({
      success: false,
      error: 'Invalid delivery address'
    });
  }
  
  if (!methodePaiement || !['Carte', 'PayPal', 'Virement'].includes(methodePaiement)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid payment method'
    });
  }
  
  next();
};

module.exports = {
  validateObjectId,
  validateProductData,
  validateUserData,
  validateOrderData
}; 