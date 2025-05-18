const Cart = require('../models/Cart');
const Product = require('../models/Product');
const Coupon = require('../models/Coupon');
const { cartLimiter } = require('../middleware/rateLimiter');

// Get user's cart
exports.getCart = async (req, res) => {
  try {
    let cart = await Cart.findOne({ userId: req.user.id })
      .populate('produits.produitId', 'nom prix images stock prixPromo discount');

    if (!cart) {
      cart = await Cart.create({ userId: req.user.id });
    }

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    console.error('Error getting cart:', error);
    res.status(500).json({
      success: false,
      error: 'Error retrieving cart'
    });
  }
};

// Add product to cart
exports.addToCart = async (req, res) => {
  try {
    const { produitId, quantite = 1 } = req.body;

    // Validate product exists and has stock
    const product = await Product.findById(produitId);
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    if (product.stock < quantite) {
      return res.status(400).json({
        success: false,
        error: 'Not enough stock available'
      });
    }

    let cart = await Cart.findOne({ user: req.user._id });
    if (!cart) {
      cart = await Cart.create({ user: req.user._id });
    }

    // Check if product already in cart
    const existingItem = cart.items.find(item => 
      item.produit.toString() === produitId
    );

    if (existingItem) {
      // Update quantity if product exists
      existingItem.quantite += quantite;
      if (existingItem.quantite > product.stock) {
        return res.status(400).json({
          success: false,
          error: 'Not enough stock available'
        });
      }
    } else {
      // Add new item if product doesn't exist
      cart.items.push({
        produit: produitId,
        quantite
      });
    }

    await cart.save();
    await cart.populate('items.produit', 'nom prix images stock prixPromo discount');
    await cart.populate('promoCode', 'code type value');

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    console.error('Error adding to cart:', error);
    res.status(500).json({
      success: false,
      error: 'Error adding product to cart'
    });
  }
};

// Update product quantity in cart
exports.updateQuantity = async (req, res) => {
  try {
    const { quantite } = req.body;
    const { produitId } = req.params;

    if (quantite < 1) {
      return res.status(400).json({
        success: false,
        error: 'Quantity must be at least 1'
      });
    }

    const product = await Product.findById(produitId);
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    if (product.stock < quantite) {
      return res.status(400).json({
        success: false,
        error: 'Not enough stock available'
      });
    }

    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) {
      return res.status(404).json({
        success: false,
        error: 'Cart not found'
      });
    }

    const itemIndex = cart.items.findIndex(item => 
      item.produit.toString() === produitId
    );

    if (itemIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'Product not found in cart'
      });
    }

    cart.items[itemIndex].quantite = quantite;
    await cart.save();
    await cart.populate('items.produit', 'nom prix images stock prixPromo discount');
    await cart.populate('promoCode', 'code type value');

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    console.error('Error updating cart quantity:', error);
    res.status(500).json({
      success: false,
      error: 'Error updating cart quantity'
    });
  }
};

// Remove product from cart
exports.removeFromCart = async (req, res) => {
  try {
    const { produitId } = req.params;

    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) {
      return res.status(404).json({
        success: false,
        error: 'Cart not found'
      });
    }

    cart.items = cart.items.filter(item => 
      item.produit.toString() !== produitId
    );

    await cart.save();
    await cart.populate('items.produit', 'nom prix images stock prixPromo discount');
    await cart.populate('promoCode', 'code type value');

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    console.error('Error removing from cart:', error);
    res.status(500).json({
      success: false,
      error: 'Error removing product from cart'
    });
  }
};

// Clear cart
exports.clearCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) {
      return res.status(404).json({
        success: false,
        error: 'Cart not found'
      });
    }

    cart.items = [];
    cart.promoCode = null;
    await cart.save();

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    console.error('Error clearing cart:', error);
    res.status(500).json({
      success: false,
      error: 'Error clearing cart'
    });
  }
};

// Apply promo code
exports.applyPromoCode = async (req, res) => {
  try {
    const { code } = req.body;

    const coupon = await Coupon.findOne({ code });
    if (!coupon) {
      return res.status(404).json({
        success: false,
        error: 'Invalid promo code'
      });
    }

    if (!coupon.isValid()) {
      return res.status(400).json({
        success: false,
        error: 'Promo code has expired or reached usage limit'
      });
    }

    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) {
      return res.status(404).json({
        success: false,
        error: 'Cart not found'
      });
    }

    if (cart.items.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Cart is empty'
      });
    }

    cart.promoCode = coupon._id;
    await cart.save();
    await cart.populate('items.produit', 'nom prix images stock prixPromo discount');
    await cart.populate('promoCode', 'code type value');

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    console.error('Error applying promo code:', error);
    res.status(500).json({
      success: false,
      error: 'Error applying promo code'
    });
  }
};

// Synchroniser le panier avec le backend
exports.syncCart = async (req, res) => {
  try {
    const { items } = req.body;
    
    // Vérifier que tous les produits existent et ont suffisamment de stock
    for (const item of items) {
      const product = await Product.findById(item.produitId);
      
      if (!product) {
        return res.status(404).json({
          success: false,
          error: `Produit ${item.produitId} non trouvé`
        });
      }
      
      if (product.stock < item.quantite) {
        return res.status(400).json({
          success: false,
          error: `Stock insuffisant pour le produit ${product.nom}`
        });
      }
    }
    
    // Mettre à jour le panier de l'utilisateur
    let cart = await Cart.findOne({ userId: req.user.id });
    
    if (!cart) {
      cart = await Cart.create({ userId: req.user.id });
    }
    
    // Mettre à jour les items du panier
    cart.produits = items.map(item => ({
      produitId: item.produitId,
      quantité: item.quantite,
      prixUnitaire: 0 // Sera mis à jour avec le prix du produit ci-dessous
    }));
    
    // Mettre à jour les prix unitaires
    for (let i = 0; i < cart.produits.length; i++) {
      const item = cart.produits[i];
      const product = await Product.findById(item.produitId);
      cart.produits[i].prixUnitaire = product.prix;
    }
    
    // Recalculer le total
    cart.calculerTotal();
    await cart.save();
    
    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    console.error('Error syncing cart:', error);
    res.status(500).json({
      success: false,
      error: 'Error syncing cart'
    });
  }
};

// Export rate limiter for use in routes
exports.cartLimiter = cartLimiter; 