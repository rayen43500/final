const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  nom: {
    type: String,
    required: true
  },
  note: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  commentaire: {
    type: String,
    required: true,
    trim: true
  }
}, {
  timestamps: true
});

const productSchema = new mongoose.Schema({
  nom: {
    type: String,
    required: [true, 'Le nom du produit est requis'],
    trim: true
  },
  description: {
    type: String,
    required: [true, 'La description est requise'],
    trim: true
  },
  prix: {
    type: Number,
    required: [true, 'Le prix est requis'],
    min: [0, 'Le prix ne peut pas être négatif']
  },
  prixPromo: {
    type: Number,
    min: [0, 'Le prix promo ne peut pas être négatif']
  },
  discount: {
    type: Number,
    min: [0, 'La réduction ne peut pas être négative'],
    max: [100, 'La réduction ne peut pas dépasser 100%']
  },
  images: [{
    type: String,
    required: [true, 'Au moins une image est requise']
  }],
  stock: {
    type: Number,
    required: [true, 'Le stock est requis'],
    min: [0, 'Le stock ne peut pas être négatif']
  },
  stockAlerte: {
    type: Number,
    default: 5,
    min: [0, 'Le seuil d\'alerte ne peut pas être négatif']
  },
  stockMax: {
    type: Number,
    min: [0, 'La capacité maximale ne peut pas être négative']
  },
  notifications: {
    stockFaible: {
      type: Boolean,
      default: true
    },
    stockVide: {
      type: Boolean,
      default: true
    }
  },
  sku: {
    type: String,
    unique: true,
    sparse: true,
    trim: true
  },
  mouvementsStock: [{
    type: {
      type: String,
      enum: ['entrée', 'sortie', 'ajustement', 'réservation'],
      required: true
    },
    quantité: {
      type: Number,
      required: true
    },
    date: {
      type: Date,
      default: Date.now
    },
    référence: {
      type: String
    },
    utilisateurId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    commentaire: String
  }],
  categoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: [true, 'La catégorie est requise']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  ratings: {
    type: Number,
    default: 0
  },
  reviews: [reviewSchema]
}, {
  timestamps: true
});

// Middleware pour calculer la moyenne des notes
productSchema.methods.calculateAverageRating = function() {
  if (this.reviews.length === 0) {
    this.ratings = 0;
    return;
  }

  const sum = this.reviews.reduce((acc, review) => acc + review.note, 0);
  this.ratings = sum / this.reviews.length;
};

// Middleware pour mettre à jour la moyenne des notes après chaque avis
productSchema.pre('save', function(next) {
  this.calculateAverageRating();
  next();
});

// Méthode pour ajouter un avis
productSchema.methods.addReview = async function(userId, userName, note, commentaire) {
  this.reviews.push({
    userId,
    nom: userName,
    note,
    commentaire
  });

  await this.calculateAverageRating();
  await this.save();
};

// Middleware pour gérer le stock
productSchema.pre('save', function(next) {
  // Si le stock est modifié et atteint 0, marquer le produit comme indisponible
  if (this.isModified('stock') && this.stock === 0) {
    this.isActive = false;
  }
  
  // Si le stock est modifié, devient > 0 et le produit est inactif à cause du stock (pas d'autres raisons)
  // alors réactiver le produit
  if (this.isModified('stock') && this.stock > 0 && this.isActive === false) {
    this.isActive = true;
  }
  
  next();
});

// Middleware pour vérifier si le produit est en stock faible et envoyer des alertes
productSchema.post('save', async function(doc) {
  // Vérifier si le stock est passé sous le seuil d'alerte
  if (doc.notifications.stockFaible && doc.stock > 0 && doc.stock <= doc.stockAlerte) {
    console.log(`ALERTE: Stock faible pour ${doc.nom} (${doc.stock} unités restantes)`);
    // Ici, on pourrait envoyer un email ou une notification
  }
  
  // Vérifier si le produit est en rupture de stock
  if (doc.notifications.stockVide && doc.stock === 0) {
    console.log(`ALERTE: Rupture de stock pour ${doc.nom}`);
    // Ici, on pourrait envoyer un email ou une notification prioritaire
  }
});

// Méthode pour ajouter un mouvement de stock
productSchema.methods.ajouterMouvementStock = async function(type, quantité, référence, utilisateurId, commentaire) {
  this.mouvementsStock.push({
    type,
    quantité,
    référence,
    utilisateurId,
    commentaire
  });
  
  return this.save();
};

// Réapprovisionner avec traçabilité
productSchema.methods.restock = async function(quantity, référence, utilisateurId, commentaire) {
  if (quantity <= 0) {
    throw new Error('La quantité à ajouter doit être supérieure à 0.');
  }
  
  const ancienStock = this.stock;
  this.stock += quantity;
  
  // Vérifier si on ne dépasse pas le stock maximum
  if (this.stockMax && this.stock > this.stockMax) {
    throw new Error(`La quantité dépasse la capacité maximale de stockage (${this.stockMax}).`);
  }
  
  // Ajouter dans l'historique des mouvements
  await this.ajouterMouvementStock('entrée', quantity, référence, utilisateurId, commentaire);
  
  console.log(`Stock mis à jour pour ${this.nom}: ${ancienStock} -> ${this.stock}`);
  
  return this.stock;
};

// Méthode mise à jour pour décrémenter le stock avec traçabilité
productSchema.methods.updateStock = async function(quantity, référence, utilisateurId, commentaire) {
  // Vérifier si la quantité demandée est disponible
  if (this.stock < quantity) {
    throw new Error(`Stock insuffisant. Seulement ${this.stock} unités disponibles.`);
  }
  
  const ancienStock = this.stock;
  this.stock -= quantity;
  
  // Ajouter dans l'historique des mouvements
  await this.ajouterMouvementStock('sortie', quantity, référence, utilisateurId, commentaire);
  
  console.log(`Stock décrémenté pour ${this.nom}: ${ancienStock} -> ${this.stock}`);
  
  return this.stock;
};

// Méthode pour faire un ajustement de stock (inventaire)
productSchema.methods.ajusterStock = async function(nouveauStock, utilisateurId, commentaire) {
  if (nouveauStock < 0) {
    throw new Error('Le nouveau stock ne peut pas être négatif.');
  }
  
  const ancienStock = this.stock;
  const différence = nouveauStock - ancienStock;
  
  this.stock = nouveauStock;
  
  // Ajouter dans l'historique
  await this.ajouterMouvementStock('ajustement', différence, 'Inventaire', utilisateurId, commentaire);
  
  console.log(`Stock ajusté pour ${this.nom}: ${ancienStock} -> ${this.stock}`);
  
  return this.stock;
};

// Méthode pour réserver temporairement du stock
productSchema.methods.réserverStock = async function(quantite, userId, raison) {
  try {
    // Vérifier si la quantité demandée est disponible
    if (this.stock < quantite) {
      return {
        success: false,
        message: `Stock insuffisant. Seulement ${this.stock} unités disponibles.`
      };
    }
    
    // Créer un mouvement de stock pour la réservation
    const mouvement = {
      type: 'reservation',
      quantite: quantite,
      date: new Date(),
      utilisateur: userId,
      raison: raison || 'Réservation de stock',
      produitId: this._id
    };
    
    // Enregistrer le mouvement de stock dans l'historique
    if (!this.mouvementsStock) {
      this.mouvementsStock = [];
    }
    this.mouvementsStock.push(mouvement);
    
    // Réduire temporairement le stock disponible
    // Note: Le stock ne sera pas réellement soustrait jusqu'à la validation de la commande
    this.stockReserve = (this.stockReserve || 0) + quantite;
    
    await this.save();
    
    return {
      success: true,
      message: 'Stock réservé avec succès',
      mouvement: mouvement
    };
  } catch (error) {
    console.error('Erreur lors de la réservation du stock:', error);
    return {
      success: false,
      message: 'Erreur lors de la réservation du stock'
    };
  }
};

// Méthode pour obtenir l'historique des mouvements de stock
productSchema.methods.getHistoriqueMouvements = function(début, fin) {
  // Filtrer par date si spécifiées
  if (début && fin) {
    return this.mouvementsStock.filter(mvt => 
      mvt.date >= new Date(début) && mvt.date <= new Date(fin)
    );
  }
  
  return this.mouvementsStock;
};

module.exports = mongoose.model('Product', productSchema); 