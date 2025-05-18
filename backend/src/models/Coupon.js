const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['percentage', 'fixed'],
    default: 'percentage'
  },
  value: {
    type: Number,
    required: true,
    min: 0,
    max: 100
  },
  minAmount: {
    type: Number,
    default: 0,
    min: 0
  },
  startDate: {
    type: Date,
    default: Date.now
  },
  endDate: {
    type: Date,
    required: true,
    validate: {
      validator: function(v) {
        return v > this.startDate;
      },
      message: 'La date de fin doit être postérieure à la date de début'
    }
  },
  maxUses: {
    type: Number,
    default: null
  },
  usedCount: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Méthode pour vérifier si le coupon est valide
couponSchema.methods.isValid = function(orderAmount = 0) {
  const now = new Date();
  
  // Vérifier si le coupon est actif
  if (!this.isActive) return { valid: false, message: 'Ce code promo n\'est plus actif' };
  
  // Vérifier la période de validité
  if (now < this.startDate || now > this.endDate) {
    return { valid: false, message: 'Ce code promo a expiré ou n\'est pas encore valable' };
  }
  
  // Vérifier le nombre maximum d'utilisations
  if (this.maxUses !== null && this.usedCount >= this.maxUses) {
    return { valid: false, message: 'Ce code promo a atteint son nombre maximum d\'utilisations' };
  }
  
  // Vérifier le montant minimum de commande
  if (orderAmount < this.minAmount) {
    return { 
      valid: false, 
      message: `Ce code promo nécessite un montant minimum de ${this.minAmount} DT`
    };
  }
  
  return { valid: true, discount: this.value };
};

// Méthode pour incrémenter le compteur d'utilisation
couponSchema.methods.use = function() {
  this.usedCount += 1;
  return this.save();
};

module.exports = mongoose.model('Coupon', couponSchema); 