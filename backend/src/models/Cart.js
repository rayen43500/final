const mongoose = require('mongoose');

const cartItemSchema = new mongoose.Schema({
  produitId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true
  },
  quantité: {
    type: Number,
    required: true,
    min: 1
  },
  prixUnitaire: {
    type: Number,
    required: true
  }
});

const cartSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  produits: [cartItemSchema],
  totalPrix: {
    type: Number,
    default: 0
  },
  codePromo: {
    type: String,
    default: null
  },
  réduction: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Méthode pour calculer le total du panier
cartSchema.methods.calculerTotal = function() {
  this.totalPrix = this.produits.reduce((total, item) => {
    return total + (item.prixUnitaire * item.quantité);
  }, 0);

  // Appliquer la réduction si un code promo est actif
  if (this.réduction > 0) {
    this.totalPrix = this.totalPrix * (1 - this.réduction / 100);
  }

  return this.totalPrix;
};

// Méthode pour ajouter ou mettre à jour un produit
cartSchema.methods.ajouterProduit = async function(produitId, quantité, prixUnitaire) {
  const index = this.produits.findIndex(item => item.produitId.toString() === produitId.toString());
  
  if (index >= 0) {
    this.produits[index].quantité += quantité;
    this.produits[index].prixUnitaire = prixUnitaire;
  } else {
    this.produits.push({ produitId, quantité, prixUnitaire });
  }

  this.calculerTotal();
  return this.save();
};

// Méthode pour supprimer un produit
cartSchema.methods.supprimerProduit = async function(produitId) {
  this.produits = this.produits.filter(item => item.produitId.toString() !== produitId.toString());
  this.calculerTotal();
  return this.save();
};

// Méthode pour vider le panier
cartSchema.methods.viderPanier = async function() {
  this.produits = [];
  this.totalPrix = 0;
  this.codePromo = null;
  this.réduction = 0;
  return this.save();
};

// Méthode pour appliquer un code promo au panier
cartSchema.methods.appliquerCodePromo = async function(code, discount) {
  const Coupon = require('./Coupon');
  const coupon = await Coupon.findOne({ code: code.toUpperCase() });
  
  if (!coupon) {
    throw new Error('Code promo invalide');
  }
  
  this.codePromo = code;
  
  // Déterminer le type de remise et appliquer la réduction
  if (coupon.type === 'percentage') {
    this.réduction = discount;
  } else if (coupon.type === 'fixed') {
    // Pour une réduction fixe, on calcule le pourcentage équivalent par rapport au total
    const pourcentage = (discount / this.totalPrix) * 100;
    this.réduction = pourcentage > 100 ? 100 : pourcentage; // Limiter à 100% maximum
  }
  
  // Recalculer le total après remise
  this.calculerTotal();
  
  return this.save();
};

// Middleware pour nettoyer les paniers abandonnés
cartSchema.statics.nettoyerPaniersAbandonnés = async function() {
  const dateLimite = new Date();
  dateLimite.setDate(dateLimite.getDate() - 7); // 7 jours d'inactivité

  await this.deleteMany({
    updatedAt: { $lt: dateLimite },
    produits: { $size: 0 }
  });
};

module.exports = mongoose.model('Cart', cartSchema); 