const Category = require('../models/Category');
const Product = require('../models/Product');

// Créer une catégorie
exports.createCategory = async (req, res) => {
  try {
    const { nom, description, slug, parentCategory, isActive, colorName, iconName } = req.body;

    // Vérifier que le nom est fourni
    if (!nom) {
      return res.status(400).json({ message: 'Le nom de la catégorie est requis' });
    }

    // Générer un slug si non fourni
    const categorySlug = slug || nom.toLowerCase().replace(/[^a-z0-9]/g, '-');

    const category = new Category({
      nom,
      description,
      slug: categorySlug,
      parentCategory: parentCategory || null,
      isActive: isActive !== undefined ? isActive : true,
      colorName,
      iconName
    });

    await category.save();

    res.status(201).json(category);
  } catch (error) {
    console.error('Erreur lors de la création de la catégorie:', error);
    
    // Gestion de l'erreur de duplication de slug
    if (error.code === 11000 && error.keyPattern && error.keyPattern.slug) {
      return res.status(400).json({ message: 'Une catégorie avec ce nom/slug existe déjà' });
    }
    
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Mettre à jour une catégorie
exports.updateCategory = async (req, res) => {
  try {
    const { nom, description, slug, parentCategory, isActive, colorName, iconName } = req.body;
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée' });
    }

    // Mettre à jour uniquement les champs fournis
    if (nom) category.nom = nom;
    if (description !== undefined) category.description = description;
    if (slug) category.slug = slug;
    if (parentCategory !== undefined) category.parentCategory = parentCategory;
    if (isActive !== undefined) category.isActive = isActive;
    if (colorName !== undefined) category.colorName = colorName;
    if (iconName !== undefined) category.iconName = iconName;

    await category.save();

    res.json(category);
  } catch (error) {
    console.error('Erreur lors de la mise à jour de la catégorie:', error);
    
    // Gestion de l'erreur de duplication de slug
    if (error.code === 11000 && error.keyPattern && error.keyPattern.slug) {
      return res.status(400).json({ message: 'Une catégorie avec ce nom/slug existe déjà' });
    }
    
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Supprimer une catégorie
exports.deleteCategory = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée' });
    }

    // Vérifier si la catégorie a des sous-catégories
    const hasSubCategories = await Category.exists({ parentCategory: category._id });
    if (hasSubCategories) {
      return res.status(400).json({ message: 'Impossible de supprimer une catégorie qui a des sous-catégories' });
    }

    // Vérifier si des produits utilisent cette catégorie
    const productsCount = await Product.countDocuments({ categoryId: category._id });
    if (productsCount > 0) {
      return res.status(400).json({ 
        message: `La catégorie est utilisée par ${productsCount} produits. Veuillez d'abord modifier ou supprimer ces produits.`
      });
    }

    await category.deleteOne();

    res.json({ message: 'Catégorie supprimée avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression de la catégorie:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Obtenir toutes les catégories
exports.getCategories = async (req, res) => {
  try {
    // Filtrer par statut actif/inactif si spécifié
    let query = {};
    if (req.query.isActive !== undefined) {
      query.isActive = req.query.isActive === 'true';
    }

    const categories = await Category.find(query)
      .populate('parentCategory', 'nom slug')
      .sort({ nom: 1 });

    // Ajouter le comptage de produits pour chaque catégorie
    const categoriesWithProductCount = await Promise.all(
      categories.map(async (category) => {
        const productCount = await Product.countDocuments({ categoryId: category._id });
        const categoryObj = category.toObject();
        categoryObj.productCount = productCount;
        return categoryObj;
      })
    );

    res.json(categoriesWithProductCount);
  } catch (error) {
    console.error('Erreur lors de la récupération des catégories:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Obtenir une catégorie par son ID
exports.getCategoryById = async (req, res) => {
  try {
    const category = await Category.findById(req.params.id)
      .populate('parentCategory', 'nom slug');

    if (!category) {
      return res.status(404).json({ message: 'Catégorie non trouvée' });
    }

    // Ajouter le comptage de produits
    const productCount = await Product.countDocuments({ categoryId: category._id });
    const categoryObj = category.toObject();
    categoryObj.productCount = productCount;

    res.json(categoryObj);
  } catch (error) {
    console.error('Erreur lors de la récupération de la catégorie:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Obtenir les statistiques des catégories
exports.getCategoryStats = async (req, res) => {
  try {
    const categories = await Category.find().sort({ nom: 1 });
    
    // Pour chaque catégorie, récupérer des statistiques détaillées
    const stats = await Promise.all(
      categories.map(async (category) => {
        const totalProducts = await Product.countDocuments({ categoryId: category._id });
        const activeProducts = await Product.countDocuments({ 
          categoryId: category._id,
          isActive: true 
        });
        const outOfStockProducts = await Product.countDocuments({ 
          categoryId: category._id,
          stock: 0 
        });
        
        // Calculer le prix moyen des produits dans la catégorie
        const productsPriceData = await Product.aggregate([
          { $match: { categoryId: category._id } },
          { $group: {
              _id: null,
              avgPrice: { $avg: '$prix' },
              minPrice: { $min: '$prix' },
              maxPrice: { $max: '$prix' }
            }
          }
        ]);
        
        const priceData = productsPriceData.length > 0 ? {
          moyenne: Math.round(productsPriceData[0].avgPrice * 100) / 100,
          minimum: productsPriceData[0].minPrice,
          maximum: productsPriceData[0].maxPrice
        } : { moyenne: 0, minimum: 0, maximum: 0 };
        
        return {
          _id: category._id,
          nom: category.nom,
          slug: category.slug,
          isActive: category.isActive,
          colorName: category.colorName,
          iconName: category.iconName,
          stats: {
            totalProduits: totalProducts,
            produitsActifs: activeProducts,
            produitsRupture: outOfStockProducts,
            prix: priceData
          }
        };
      })
    );
    
    res.json(stats);
  } catch (error) {
    console.error('Erreur lors de la récupération des statistiques:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}; 