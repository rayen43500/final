const Product = require('../models/Product');
const Category = require('../models/Category');
const Promotion = require('../models/Promotion');

// Créer un produit
exports.createProduct = async (req, res) => {
  try {
    const {
      nom,
      description,
      prix,
      prixPromo,
      discount,
      images,
      stock,
      categoryId
    } = req.body;

    // Vérifier si la catégorie existe
    const category = await Category.findById(categoryId);
    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée' });
    }

    const product = new Product({
      nom,
      description,
      prix,
      prixPromo,
      discount,
      images,
      stock,
      categoryId
    });

    await product.save();

    res.status(201).json(product);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Mettre à jour un produit
exports.updateProduct = async (req, res) => {
  try {
    const {
      nom,
      description,
      prix,
      prixPromo,
      discount,
      images,
      stock,
      categoryId,
      isActive
    } = req.body;

    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }

    // Vérifier si la catégorie existe
    if (categoryId) {
      const category = await Category.findById(categoryId);
      if (!category) {
        return res.status(404).json({ message: 'Catégorie non trouvée' });
      }
    }

    product.nom = nom || product.nom;
    product.description = description || product.description;
    product.prix = prix || product.prix;
    product.prixPromo = prixPromo !== undefined ? prixPromo : product.prixPromo;
    product.discount = discount !== undefined ? discount : product.discount;
    product.images = images || product.images;
    product.stock = stock !== undefined ? stock : product.stock;
    product.categoryId = categoryId || product.categoryId;
    product.isActive = isActive !== undefined ? isActive : product.isActive;

    await product.save();

    res.json(product);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Obtenir tous les produits avec filtres
exports.getProducts = async (req, res) => {
  try {
    const {
      category,
      minPrice,
      maxPrice,
      inStock,
      onSale,
      hasPromotion,
      sortBy,
      limit = 10,
      page = 1
    } = req.query;

    let query = { isActive: true };

    // Filtres
    if (category) {
      query.categoryId = category;
    }
    if (minPrice) {
      query.prix = { ...query.prix, $gte: Number(minPrice) };
    }
    if (maxPrice) {
      query.prix = { ...query.prix, $lte: Number(maxPrice) };
    }
    if (inStock === 'true') {
      query.stock = { $gt: 0 };
    }
    if (onSale === 'true') {
      query.discount = { $gt: 0 };
    }

    // Tri
    let sortOptions = {};
    switch (sortBy) {
      case 'price-asc':
        sortOptions = { prix: 1 };
        break;
      case 'price-desc':
        sortOptions = { prix: -1 };
        break;
      case 'rating':
        sortOptions = { ratings: -1 };
        break;
      case 'newest':
        sortOptions = { createdAt: -1 };
        break;
      default:
        sortOptions = { createdAt: -1 };
    }

    const skip = (page - 1) * limit;

    // Récupérer tous les produits selon les filtres
    const products = await Product.find(query)
      .populate('categoryId', 'nom slug')
      .sort(sortOptions)
      .skip(skip)
      .limit(Number(limit));

    const total = await Product.countDocuments(query);
    
    // Si demandé, filtrer les produits avec promotions actives
    const currentDate = new Date();
    let productsWithPromotions = [...products];
    
    if (hasPromotion === 'true') {
      // Récupérer toutes les promotions actives
      const activeProductPromotions = await Promotion.find({
        type: 'produit',
        isActive: true,
        dateDebut: { $lte: currentDate },
        dateFin: { $gte: currentDate }
      });
      
      const activeCategoryPromotions = await Promotion.find({
        type: 'categorie',
        isActive: true,
        dateDebut: { $lte: currentDate },
        dateFin: { $gte: currentDate }
      });
      
      // Filtrer les produits qui ont une promotion
      productsWithPromotions = products.filter(product => {
        const hasProductPromo = activeProductPromotions.some(
          promo => promo.cible.toString() === product._id.toString()
        );
        
        const hasCategoryPromo = product.categoryId && activeCategoryPromotions.some(
          promo => promo.cible.toString() === product.categoryId._id.toString()
        );
        
        return hasProductPromo || hasCategoryPromo;
      });
    }
    
    // Enrichir les produits avec les informations de promotion
    const enrichedProducts = await Promise.all(productsWithPromotions.map(async (product) => {
      // Promotions spécifiques au produit
      const productPromotions = await Promotion.find({
        type: 'produit',
        cible: product._id,
        isActive: true,
        dateDebut: { $lte: currentDate },
        dateFin: { $gte: currentDate }
      });
      
      // Promotions de la catégorie du produit
      const categoryPromotions = product.categoryId ? await Promotion.find({
        type: 'categorie',
        cible: product.categoryId._id,
        isActive: true,
        dateDebut: { $lte: currentDate },
        dateFin: { $gte: currentDate }
      }) : [];
      
      const allPromotions = [...productPromotions, ...categoryPromotions];
      
      // Calculer le meilleur prix
      let finalPrice = product.prix;
      let activePromotion = null;
      
      if (allPromotions.length > 0) {
        allPromotions.forEach(promo => {
          const discountedPrice = promo.calculerPrixReduit(product.prix);
          if (discountedPrice < finalPrice) {
            finalPrice = discountedPrice;
            activePromotion = promo;
          }
        });
      }
      
      // Arrondir à 2 décimales
      finalPrice = Math.round(finalPrice * 100) / 100;
      
      // Calculer le pourcentage de réduction
      const discountAmount = product.prix - finalPrice;
      const discountPercentage = Math.round((discountAmount / product.prix) * 100);
      
      return {
        ...product.toObject(),
        prixFinal: finalPrice,
        reduction: discountAmount > 0 ? {
          montant: discountAmount,
          pourcentage: discountPercentage,
          promotion: activePromotion ? {
            id: activePromotion._id,
            nom: activePromotion.nom,
            type: activePromotion.type
          } : null
        } : null
      };
    }));
    
    res.json({
      products: enrichedProducts,
      total: hasPromotion === 'true' ? enrichedProducts.length : total,
      page: Number(page),
      pages: Math.ceil(total / limit)
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Obtenir un produit par son ID
exports.getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id)
      .populate('categoryId', 'nom slug')
      .populate('reviews.userId', 'nom');

    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }

    // Récupérer les promotions applicables au produit
    const currentDate = new Date();
    
    // Promotions spécifiques au produit
    const productPromotions = await Promotion.find({
      type: 'produit',
      cible: product._id,
      isActive: true,
      dateDebut: { $lte: currentDate },
      dateFin: { $gte: currentDate }
    });
    
    // Promotions de la catégorie du produit
    const categoryPromotions = product.categoryId ? await Promotion.find({
      type: 'categorie',
      cible: product.categoryId._id,
      isActive: true,
      dateDebut: { $lte: currentDate },
      dateFin: { $gte: currentDate }
    }) : [];
    
    const allPromotions = [...productPromotions, ...categoryPromotions];
    
    // Calculer le meilleur prix après promotions
    let finalPrice = product.prix;
    let activePromotion = null;
    
    if (allPromotions.length > 0) {
      allPromotions.forEach(promo => {
        const discountedPrice = promo.calculerPrixReduit(product.prix);
        if (discountedPrice < finalPrice) {
          finalPrice = discountedPrice;
          activePromotion = promo;
        }
      });
    }
    
    // Arrondir à 2 décimales
    finalPrice = Math.round(finalPrice * 100) / 100;
    
    // Calculer le pourcentage de réduction
    const discountAmount = product.prix - finalPrice;
    const discountPercentage = Math.round((discountAmount / product.prix) * 100);
    
    res.json({
      ...product.toObject(),
      promotions: allPromotions,
      prixFinal: finalPrice,
      reduction: discountAmount > 0 ? {
        montant: discountAmount,
        pourcentage: discountPercentage,
        promotion: activePromotion
      } : null
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Ajouter un avis à un produit
exports.addReview = async (req, res) => {
  try {
    const { note, commentaire } = req.body;
    const product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }

    // Vérifier si l'utilisateur a déjà laissé un avis
    const existingReview = product.reviews.find(
      review => review.userId.toString() === req.user.id
    );

    if (existingReview) {
      return res.status(400).json({ message: 'Vous avez déjà laissé un avis sur ce produit' });
    }

    await product.addReview(
      req.user.id,
      req.user.nom,
      note,
      commentaire
    );

    res.json(product);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Rechercher des produits
exports.searchProducts = async (req, res) => {
  try {
    const { q } = req.query;
    const limit = Number(req.query.limit) || 10;

    if (!q) {
      return res.status(400).json({ message: 'Le terme de recherche est requis' });
    }

    const products = await Product.find({
      $and: [
        { isActive: true },
        {
          $or: [
            { nom: { $regex: q, $options: 'i' } },
            { description: { $regex: q, $options: 'i' } }
          ]
        }
      ]
    })
      .populate('categoryId', 'nom slug')
      .limit(limit);

    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Réapprovisionner le stock d'un produit (Admin)
exports.restockProduct = async (req, res) => {
  try {
    const { quantity, référence, commentaire } = req.body;
    
    if (!quantity || quantity <= 0) {
      return res.status(400).json({ message: 'La quantité doit être un nombre positif' });
    }
    
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }
    
    // Utiliser la méthode de réapprovisionnement du modèle Product avec traçabilité
    const newStock = await product.restock(
      Number(quantity), 
      référence || 'Réapprovisionnement manuel',
      req.user.id,
      commentaire || 'Réapprovisionnement effectué par administrateur'
    );
    
    res.json({
      message: `Stock mis à jour avec succès. Nouveau stock: ${newStock}`,
      product
    });
  } catch (error) {
    console.error('Erreur lors du réapprovisionnement:', error);
    res.status(500).json({ message: error.message });
  }
};

// Obtenir les produits en rupture de stock ou en stock faible (Admin)
exports.getLowStockProducts = async (req, res) => {
  try {
    const { threshold = 5 } = req.query;
    
    // Trouver les produits dont le stock est inférieur ou égal au seuil
    const lowStockProducts = await Product.find({
      stock: { $lte: Number(threshold), $gt: 0 }
    })
    .sort({ stock: 1 })
    .select('nom stock stockAlerte stockMax prix isActive categoryId images')
    .populate('categoryId', 'nom');
    
    // Trouver les produits en rupture de stock (stock = 0)
    const outOfStockProducts = await Product.find({ stock: 0 })
      .select('nom stock stockAlerte stockMax prix isActive categoryId images')
      .populate('categoryId', 'nom');
    
    res.json({
      lowStockProducts,
      outOfStockProducts,
      totalLowStock: lowStockProducts.length,
      totalOutOfStock: outOfStockProducts.length
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des produits en stock faible:', error);
    res.status(500).json({ message: error.message });
  }
};

// Ajuster le stock d'un produit (Inventaire) (Admin)
exports.adjustStock = async (req, res) => {
  try {
    const { nouveauStock, commentaire } = req.body;
    
    if (nouveauStock === undefined || nouveauStock < 0) {
      return res.status(400).json({ message: 'Le nouveau stock doit être un nombre positif ou nul' });
    }
    
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }
    
    // Utiliser la méthode d'ajustement du modèle Product
    const stockAjusté = await product.ajusterStock(
      Number(nouveauStock),
      req.user.id,
      commentaire || 'Ajustement d\'inventaire'
    );
    
    res.json({
      message: `Stock ajusté avec succès. Nouveau stock: ${stockAjusté}`,
      product
    });
  } catch (error) {
    console.error('Erreur lors de l\'ajustement du stock:', error);
    res.status(500).json({ message: error.message });
  }
};

// Configurer les paramètres de stock d'un produit (Admin)
exports.configureStockSettings = async (req, res) => {
  try {
    const { stockAlerte, stockMax, notifications } = req.body;
    
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }
    
    // Mettre à jour les paramètres de stock
    if (stockAlerte !== undefined && stockAlerte >= 0) {
      product.stockAlerte = stockAlerte;
    }
    
    if (stockMax !== undefined && stockMax >= 0) {
      product.stockMax = stockMax;
    }
    
    if (notifications) {
      if (notifications.stockFaible !== undefined) {
        product.notifications.stockFaible = notifications.stockFaible;
      }
      
      if (notifications.stockVide !== undefined) {
        product.notifications.stockVide = notifications.stockVide;
      }
    }
    
    await product.save();
    
    res.json({
      message: 'Paramètres de stock mis à jour avec succès',
      product
    });
  } catch (error) {
    console.error('Erreur lors de la configuration des paramètres de stock:', error);
    res.status(500).json({ message: error.message });
  }
};

// Obtenir l'historique des mouvements de stock d'un produit (Admin)
exports.getStockHistory = async (req, res) => {
  try {
    const { début, fin } = req.query;
    
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }
    
    // Récupérer l'historique des mouvements
    const mouvements = product.getHistoriqueMouvements(début, fin);
    
    // Si besoin de données utilisateur, on peut les peupler
    // Cela nécessiterait une mise à jour de la méthode getHistoriqueMouvements
    
    res.json({
      produit: {
        _id: product._id,
        nom: product.nom,
        stock: product.stock,
        stockAlerte: product.stockAlerte,
        stockMax: product.stockMax
      },
      mouvements,
      total: mouvements.length
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'historique des mouvements:', error);
    res.status(500).json({ message: error.message });
  }
};

// Réserver du stock pour un produit (sans décrémenter immédiatement)
exports.reserveStock = async (req, res) => {
  try {
    const { quantity, référence, commentaire } = req.body;
    
    if (!quantity || quantity <= 0) {
      return res.status(400).json({ message: 'La quantité doit être un nombre positif' });
    }
    
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }
    
    // Utiliser la méthode de réservation du modèle Product
    await product.réserverStock(
      Number(quantity),
      référence || 'Réservation',
      req.user.id,
      commentaire || 'Réservation de stock'
    );
    
    res.json({
      message: `${quantity} unités de ${product.nom} réservées avec succès`,
      stockDisponible: product.stock
    });
  } catch (error) {
    console.error('Erreur lors de la réservation de stock:', error);
    res.status(500).json({ message: error.message });
  }
}; 