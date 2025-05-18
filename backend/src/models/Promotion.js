const mongoose = require('mongoose');

const promotionSchema = new mongoose.Schema({
  nom: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    enum: ['produit', 'categorie'],
    required: true
  },
  cible: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    // Référence dynamique selon le type (produit ou catégorie)
    refPath: 'typeRef'
  },
  typeRef: {
    type: String,
    required: true,
    enum: ['Product', 'Category']
  },
  typeReduction: {
    type: String,
    enum: ['pourcentage', 'montant'],
    required: true
  },
  valeurReduction: {
    type: Number,
    required: true,
    min: 0
  },
  dateDebut: {
    type: Date,
    required: true,
    default: Date.now
  },
  dateFin: {
    type: Date,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  codePromo: {
    type: String,
    trim: true,
    uppercase: true,
    // Optionnel: code promo pour appliquer manuellement la promotion
  },
  description: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Vérifier si la promotion est valide à une date donnée
promotionSchema.methods.isValidAt = function(date = new Date()) {
  return (
    this.isActive && 
    date >= this.dateDebut && 
    date <= this.dateFin
  );
};

// Calculer le prix après réduction
promotionSchema.methods.calculerPrixReduit = function(prixOriginal) {
  if (this.typeReduction === 'pourcentage') {
    // Limiter le pourcentage à 100%
    const pourcentage = Math.min(this.valeurReduction, 100);
    return prixOriginal * (1 - pourcentage / 100);
  } else if (this.typeReduction === 'montant') {
    // La réduction ne peut pas dépasser le prix original
    return Math.max(0, prixOriginal - this.valeurReduction);
  }
  return prixOriginal;
};

// Index pour optimiser les recherches
promotionSchema.index({ type: 1, cible: 1 });
promotionSchema.index({ dateDebut: 1, dateFin: 1 });
promotionSchema.index({ codePromo: 1 });

module.exports = mongoose.model('Promotion', promotionSchema); 