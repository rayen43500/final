const Promotion = require('../models/Promotion');
const Product = require('../models/Product');
const Category = require('../models/Category');
const { rateLimit } = require('express-rate-limit');

// Rate limiter pour les endpoints promotions
const promotionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Limite à 50 requêtes par fenêtre
  message: 'Trop de requêtes, veuillez réessayer plus tard.'
});

// Créer une nouvelle promotion (Admin)
exports.createPromotion = async (req, res) => {
  try {
    const {
      nom,
      type,
      cible,
      typeReduction,
      valeurReduction,
      dateDebut,
      dateFin,
      codePromo,
      description
    } = req.body;

    // Vérifier que la cible existe (produit ou catégorie)
    let targetExists = false;
    let typeRef;

    if (type === 'produit') {
      const product = await Product.findById(cible);
      targetExists = !!product;
      typeRef = 'Product';
    } else if (type === 'categorie') {
      const category = await Category.findById(cible);
      targetExists = !!category;
      typeRef = 'Category';
    }

    if (!targetExists) {
      return res.status(404).json({ message: `${type === 'produit' ? 'Produit' : 'Catégorie'} non trouvé(e)` });
    }

    // Vérifier que les dates sont valides
    const startDate = new Date(dateDebut);
    const endDate = new Date(dateFin);

    if (endDate <= startDate) {
      return res.status(400).json({ message: 'La date de fin doit être postérieure à la date de début' });
    }

    // Vérifier que la valeur de réduction est valide
    if (typeReduction === 'pourcentage' && (valeurReduction <= 0 || valeurReduction > 100)) {
      return res.status(400).json({ message: 'Le pourcentage de réduction doit être compris entre 0 et 100' });
    }

    if (typeReduction === 'montant' && valeurReduction <= 0) {
      return res.status(400).json({ message: 'Le montant de réduction doit être supérieur à 0' });
    }

    // Vérifier si un code promo similaire existe déjà
    if (codePromo) {
      const existingPromo = await Promotion.findOne({ codePromo });
      if (existingPromo) {
        return res.status(400).json({ message: 'Ce code promotionnel existe déjà' });
      }
    }

    // Créer la promotion
    const promotion = new Promotion({
      nom,
      type,
      cible,
      typeRef,
      typeReduction,
      valeurReduction,
      dateDebut: startDate,
      dateFin: endDate,
      codePromo,
      description
    });

    await promotion.save();

    res.status(201).json({
      message: 'Promotion créée avec succès',
      promotion
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Récupérer toutes les promotions (Admin)
exports.getAllPromotions = async (req, res) => {
  try {
    const promotions = await Promotion.find()
      .sort({ dateDebut: -1 });
    
    res.json(promotions);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Récupérer une promotion par son ID (Admin)
exports.getPromotionById = async (req, res) => {
  try {
    const promotion = await Promotion.findById(req.params.id);
    
    if (!promotion) {
      return res.status(404).json({ message: 'Promotion non trouvée' });
    }
    
    res.json(promotion);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Mettre à jour une promotion (Admin)
exports.updatePromotion = async (req, res) => {
  try {
    const {
      nom,
      type,
      cible,
      typeReduction,
      valeurReduction,
      dateDebut,
      dateFin,
      isActive,
      codePromo,
      description
    } = req.body;

    const promotion = await Promotion.findById(req.params.id);
    
    if (!promotion) {
      return res.status(404).json({ message: 'Promotion non trouvée' });
    }

    // Si le type ou la cible change, vérifier que la nouvelle cible existe
    if ((type && type !== promotion.type) || (cible && cible.toString() !== promotion.cible.toString())) {
      let targetExists = false;
      let typeRef;
      
      const newType = type || promotion.type;
      const newCible = cible || promotion.cible;

      if (newType === 'produit') {
        const product = await Product.findById(newCible);
        targetExists = !!product;
        typeRef = 'Product';
      } else if (newType === 'categorie') {
        const category = await Category.findById(newCible);
        targetExists = !!category;
        typeRef = 'Category';
      }

      if (!targetExists) {
        return res.status(404).json({ message: `${newType === 'produit' ? 'Produit' : 'Catégorie'} non trouvé(e)` });
      }

      promotion.type = newType;
      promotion.cible = newCible;
      promotion.typeRef = typeRef;
    }

    // Vérifier les dates si elles sont fournies
    if (dateDebut || dateFin) {
      const startDate = dateDebut ? new Date(dateDebut) : promotion.dateDebut;
      const endDate = dateFin ? new Date(dateFin) : promotion.dateFin;

      if (endDate <= startDate) {
        return res.status(400).json({ message: 'La date de fin doit être postérieure à la date de début' });
      }

      promotion.dateDebut = startDate;
      promotion.dateFin = endDate;
    }

    // Vérifier la valeur de réduction si elle est fournie
    if (typeReduction) {
      promotion.typeReduction = typeReduction;
    }

    if (valeurReduction) {
      if (promotion.typeReduction === 'pourcentage' && (valeurReduction <= 0 || valeurReduction > 100)) {
        return res.status(400).json({ message: 'Le pourcentage de réduction doit être compris entre 0 et 100' });
      }

      if (promotion.typeReduction === 'montant' && valeurReduction <= 0) {
        return res.status(400).json({ message: 'Le montant de réduction doit être supérieur à 0' });
      }

      promotion.valeurReduction = valeurReduction;
    }

    // Vérifier le code promo s'il est fourni
    if (codePromo && codePromo !== promotion.codePromo) {
      const existingPromo = await Promotion.findOne({ codePromo });
      if (existingPromo && existingPromo._id.toString() !== promotion._id.toString()) {
        return res.status(400).json({ message: 'Ce code promotionnel existe déjà' });
      }
      promotion.codePromo = codePromo;
    }

    // Mettre à jour les autres champs
    if (nom) promotion.nom = nom;
    if (description) promotion.description = description;
    if (isActive !== undefined) promotion.isActive = isActive;

    await promotion.save();

    res.json({
      message: 'Promotion mise à jour avec succès',
      promotion
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Supprimer une promotion (Admin)
exports.deletePromotion = async (req, res) => {
  try {
    const promotion = await Promotion.findByIdAndDelete(req.params.id);
    
    if (!promotion) {
      return res.status(404).json({ message: 'Promotion non trouvée' });
    }
    
    res.json({ message: 'Promotion supprimée avec succès' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Récupérer les promotions applicables à un produit (Public)
exports.getProductPromotions = async (req, res) => {
  try {
    const productId = req.params.productId;
    
    // Vérifier que le produit existe
    const product = await Product.findById(productId).populate('categoryId');
    
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }
    
    const currentDate = new Date();
    
    // Récupérer les promotions applicables directement au produit
    const productPromotions = await Promotion.find({
      type: 'produit',
      cible: productId,
      isActive: true,
      dateDebut: { $lte: currentDate },
      dateFin: { $gte: currentDate }
    });
    
    // Récupérer les promotions applicables à la catégorie du produit
    const categoryPromotions = product.categoryId ? await Promotion.find({
      type: 'categorie',
      cible: product.categoryId._id,
      isActive: true,
      dateDebut: { $lte: currentDate },
      dateFin: { $gte: currentDate }
    }) : [];
    
    const allPromotions = [...productPromotions, ...categoryPromotions];
    
    // Si aucune promotion n'est disponible
    if (allPromotions.length === 0) {
      return res.json({
        originalPrice: product.prix,
        promotions: [],
        bestPrice: product.prix,
        discount: 0
      });
    }
    
    // Calculer le meilleur prix (prix le plus bas après toutes les promotions)
    let bestPrice = product.prix;
    let bestPromotion = null;
    
    allPromotions.forEach(promo => {
      const reducedPrice = promo.calculerPrixReduit(product.prix);
      if (reducedPrice < bestPrice) {
        bestPrice = reducedPrice;
        bestPromotion = promo;
      }
    });
    
    // Arrondir à 2 décimales
    bestPrice = Math.round(bestPrice * 100) / 100;
    const discount = Math.round((product.prix - bestPrice) * 100) / 100;
    const discountPercentage = Math.round((discount / product.prix) * 100);
    
    res.json({
      originalPrice: product.prix,
      promotions: allPromotions,
      bestPrice,
      discount,
      discountPercentage,
      bestPromotion
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Appliquer un code promo à un produit (Public)
exports.applyPromoCode = async (req, res) => {
  try {
    const { productId, promoCode } = req.body;
    
    if (!productId || !promoCode) {
      return res.status(400).json({ message: 'ID du produit et code promo requis' });
    }
    
    // Vérifier que le produit existe
    const product = await Product.findById(productId);
    
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }
    
    // Rechercher la promotion par code promo
    const promotion = await Promotion.findOne({
      codePromo: promoCode.toUpperCase(),
      isActive: true
    });
    
    if (!promotion) {
      return res.status(404).json({ message: 'Code promo invalide ou expiré' });
    }
    
    // Vérifier si le code promo est valide à la date actuelle
    const currentDate = new Date();
    if (!promotion.isValidAt(currentDate)) {
      return res.status(400).json({ message: 'Code promo expiré ou non actif' });
    }
    
    // Vérifier si le code promo est applicable au produit
    let isApplicable = false;
    
    if (promotion.type === 'produit' && promotion.cible.toString() === productId) {
      isApplicable = true;
    } else if (promotion.type === 'categorie') {
      // Vérifier si le produit appartient à la catégorie ciblée
      const productWithCategory = await Product.findById(productId).populate('categoryId');
      if (productWithCategory.categoryId && 
          productWithCategory.categoryId._id.toString() === promotion.cible.toString()) {
        isApplicable = true;
      }
    }
    
    if (!isApplicable) {
      return res.status(400).json({ message: 'Ce code promo n\'est pas applicable à ce produit' });
    }
    
    // Calculer le prix réduit
    const reducedPrice = promotion.calculerPrixReduit(product.prix);
    const discount = product.prix - reducedPrice;
    const discountPercentage = Math.round((discount / product.prix) * 100);
    
    res.json({
      originalPrice: product.prix,
      reducedPrice,
      discount,
      discountPercentage,
      promotion
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Exporter le middleware de rate limiting
exports.promotionLimiter = promotionLimiter; 