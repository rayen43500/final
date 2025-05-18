const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Product = require('../models/Product');
const DeliveryPerson = require('../models/DeliveryPerson');
const { rateLimit } = require('express-rate-limit');
const mongoose = require('mongoose');
const User = require('../models/User');

// Configuration du rate limiting
const orderLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50 // limite chaque IP à 50 requêtes par fenêtre
});

// Créer une commande à partir des données fournies
exports.createOrder = async (req, res) => {
  try {
    console.log('Requête reçue (création de commande):', JSON.stringify(req.body, null, 2));

    // Extraire les données de la requête ou utiliser des valeurs par défaut
    const adresseLivraison = req.body.adresseLivraison || "Adresse par défaut";
    const methodePaiement = req.body.methodePaiement || "card";
    const produits = req.body.produits || [];

    // Vérifier que la liste des produits n'est pas vide
    if (produits.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'La liste des produits ne peut pas être vide'
      });
    }

    // Valider l'existence des produits dans la base de données
    for (const produit of produits) {
      const exists = await Product.findById(produit.produitId);
      if (!exists) {
        return res.status(400).json({
          success: false,
          message: `Produit avec ID ${produit.produitId} non trouvé`
        });
      }
    }

    // Formater les produits pour la commande
    const formattedProduits = produits.map(p => ({
      produitId: p.produitId,
      quantité: p.quantité || 1,
      prixUnitaire: p.prixUnitaire || 99.99
    }));

    // Calculer le total
    const total = formattedProduits.reduce((sum, p) => sum + (p.prixUnitaire * p.quantité), 0);

    // Créer une nouvelle commande
    const newOrder = new Order({
      userId: req.user.id,
      produits: formattedProduits,
      adresseLivraison,
      methodePaiement,
      total,
      statut: 'En attente',
      dateCommande: new Date(),
      createdAt: new Date(),
      updatedAt: new Date()
    });

    // Enregistrer la commande dans la base de données
    const savedOrder = await newOrder.save();

    // Vider le panier de l'utilisateur
    const cart = await Cart.findOne({ userId: req.user.id });
    if (cart) {
      cart.produits = [];
      cart.codePromo = null;
      cart.totalPrix = 0;
      await cart.save();
    }

    console.log('Commande enregistrée avec succès:', savedOrder._id);

    // Populer les produits pour la réponse
    await savedOrder.populate('produits.produitId', 'nom prix images description');

    // Formater la réponse
    const formattedOrder = {
      _id: savedOrder._id,
      userId: savedOrder.userId,
      produits: savedOrder.produits.map(item => ({
        produitId: item.produitId ? item.produitId._id : item.produitId,
        nom: item.produitId ? item.produitId.nom : 'Produit indisponible',
        prix: item.prixUnitaire,
        quantite: item.quantité,
        images: item.produitId ? item.produitId.images : []
      })),
      adresseLivraison: savedOrder.adresseLivraison,
      methodePaiement: savedOrder.methodePaiement,
      total: savedOrder.total,
      statut: savedOrder.statut,
      dateCommande: savedOrder.dateCommande,
      createdAt: savedOrder.createdAt,
      updatedAt: savedOrder.updatedAt
    };

    // Retourner la commande enregistrée
    return res.status(201).json({
      success: true,
      message: 'Commande créée avec succès',
      commande: formattedOrder
    });
  } catch (error) {
    console.error('Erreur création commande:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la commande',
      error: error.message
    });
  }
};

// Récupérer les commandes de l'utilisateur
exports.getUserOrders = async (req, res) => {
  try {
    console.log(`Récupération des commandes pour l'utilisateur: ${req.user.id}`);

    const orders = await Order.find({ userId: req.user.id })
      .populate('produits.produitId', 'nom prix images description')
      .sort({ dateCommande: -1 });

    console.log(`Nombre de commandes trouvées: ${orders.length}`);

    if (!orders || orders.length === 0) {
      console.log('Aucune commande trouvée pour cet utilisateur');
      return res.status(200).json({
        success: true,
        message: 'Aucune commande trouvée',
        commandes: []
      });
    }

    const formattedOrders = orders.map(order => ({
      _id: order._id,
      numero: `CMD-${order._id.toString().slice(-6)}`,
      date: order.dateCommande,
      statut: order.statut,
      total: order.total,
      produits: order.produits.map(item => ({
        produitId: item.produitId ? item.produitId._id : item.produitId,
        nom: item.produitId ? item.produitId.nom : 'Produit indisponible',
        prix: item.prixUnitaire,
        quantite: item.quantité,
        images: item.produitId ? item.produitId.images : []
      })),
      adresseLivraison: order.adresseLivraison,
      methodePaiement: order.methodePaiement || 'Non spécifié',
      dateLivraison: order.dateLivraison,
      paymentStatus: order.paymentStatus
    }));

    return res.status(200).json({
      success: true,
      message: 'Commandes récupérées avec succès',
      commandes: formattedOrders
    });
  } catch (error) {
    console.error(`Erreur de récupération des commandes: ${error.message}`);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commandes',
      error: error.message
    });
  }
};

// Récupérer une commande spécifique (admin)
exports.getOrder = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('produits.produitId', 'nom images')
      .populate('userId', 'nom email');

    if (!order) {
      return res.status(404).json({ message: 'Commande non trouvée' });
    }

    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Mettre à jour le statut d'une commande (admin)
exports.updateOrderStatus = async (req, res) => {
  try {
    const { statut } = req.body;
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({ message: 'Commande non trouvée' });
    }

    order.statut = statut;
    if (statut === 'Expédiée') {
      order.dateLivraison = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 jours
    }

    await order.save();
    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Assigner un livreur à une commande (admin)
exports.assignDeliveryPerson = async (req, res) => {
  try {
    const { deliveryPersonId } = req.body;

    if (!deliveryPersonId) {
      return res.status(400).json({ message: 'ID du livreur requis' });
    }

    // Rechercher l'utilisateur avec le rôle Livreur
    const livreur = await User.findOne({ 
      _id: deliveryPersonId,
      role: 'Livreur'
    });
    
    if (!livreur) {
      return res.status(404).json({ message: 'Livreur non trouvé' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Commande non trouvée' });
    }

    // Mettre à jour la commande avec l'ID du livreur
    order.livreurId = livreur._id;
    if (order.statut === 'En attente') {
      order.statut = 'Expédiée';
      order.dateLivraison = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000); // Livraison dans 2 jours
    }

    await order.save();

    res.json({
      message: 'Livreur assigné avec succès',
      order
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Créer une commande à partir d'un panier synchronisé
exports.createOrderFromSync = async (req, res) => {
  try {
    const { adresse, methodePaiement, notes } = req.body;

    if (!adresse) {
      return res.status(400).json({
        success: false,
        error: 'Adresse de livraison requise'
      });
    }

    if (!methodePaiement) {
      return res.status(400).json({
        success: false,
        error: 'Méthode de paiement requise'
      });
    }

    const cart = await Cart.findOne({ userId: req.user.id })
      .populate('produits.produitId');

    if (!cart || cart.produits.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Panier vide'
      });
    }

    let total = 0;
    for (const item of cart.produits) {
      const price = item.produitId.prixPromo || item.produitId.prix;
      total += price * item.quantité;
    }

    const order = new Order({
      userId: req.user.id,
      produits: cart.produits.map(item => ({
        produitId: item.produitId._id,
        quantité: item.quantité,
        prixUnitaire: item.produitId.prixPromo || item.produitId.prix
      })),
      adresseLivraison: adresse,
      methodePaiement,
      notes,
      codePromo: cart.codePromo,
      total,
      statut: 'En attente'
    });

    await order.save();
    await order.populate('produits.produitId', 'nom prix images prixPromo');

    cart.produits = [];
    cart.codePromo = null;
    cart.totalPrix = 0;
    await cart.save();

    res.status(201).json({
      success: true,
      data: order
    });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création de la commande'
    });
  }
};

// Récupérer les commandes de l'utilisateur pour mobile
exports.getMobileUserOrders = async (req, res) => {
  try {
    console.log(`[MOBILE API] Récupération des commandes pour l'utilisateur: ${req.user.id}`);

    const orders = await Order.find({ userId: req.user.id })
      .populate('produits.produitId', 'nom prix images description prixPromo stock')
      .sort({ dateCommande: -1 });

    console.log(`[MOBILE API] Nombre de commandes trouvées: ${orders.length}`);

    if (!orders || orders.length === 0) {
      console.log('[MOBILE API] Aucune commande trouvée pour cet utilisateur');
      return res.status(200).json({
        success: true,
        message: 'Aucune commande trouvée',
        commandes: []
      });
    }

    const mobileOrders = orders.map(order => ({
      _id: order._id,
      numero: `CMD-${order._id.toString().slice(-6)}`,
      date: order.dateCommande,
      statut: order.statut,
      total: order.total,
      produits: order.produits.map(item => ({
        produitId: item.produitId ? item.produitId._id : item.produitId,
        nom: item.produitId ? item.produitId.nom : 'Produit indisponible',
        prix: item.prixUnitaire,
        quantite: item.quantité,
        images: item.produitId && item.produitId.images ? item.produitId.images : []
      })),
      adresseLivraison: order.adresseLivraison,
      methodePaiement: order.methodePaiement || 'Non spécifié',
      dateLivraison: order.dateLivraison,
      dateCreation: order.createdAt,
      paiement: {
        statut: order.paymentStatus || 'Payé',
        methode: order.methodePaiement || 'Carte bancaire'
      },
      livraison: {
        adresse: order.adresseLivraison,
        statut: order.statut,
        date: order.dateLivraison
      }
    }));

    return res.status(200).json({
      success: true,
      message: 'Commandes récupérées avec succès',
      commandes: mobileOrders
    });
  } catch (error) {
    console.error(`[MOBILE API] Erreur de récupération des commandes: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commandes',
      error: error.message
    });
  }
};

// Récupérer le détail d'une commande pour mobile
exports.getMobileOrderDetails = async (req, res) => {
  try {
    console.log(`[MOBILE API] Récupération des détails de la commande: ${req.params.id}`);

    const order = await Order.findById(req.params.id)
      .populate('produits.produitId', 'nom prix images description prixPromo stock')
      .populate('userId', 'nom email');

    if (!order) {
      console.log(`[MOBILE API] Commande non trouvée: ${req.params.id}`);
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }

    if (order.userId && order.userId._id.toString() !== req.user.id && req.user.role !== 'Admin') {
      console.log(`[MOBILE API] Accès non autorisé à la commande ${req.params.id} par l'utilisateur ${req.user.id}`);
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas autorisé à accéder à cette commande'
      });
    }

    const mobileOrderDetails = {
      _id: order._id,
      numero: `CMD-${order._id.toString().slice(-6)}`,
      date: order.dateCommande,
      statut: order.statut,
      total: order.total,
      produits: order.produits.map(item => ({
        produitId: item.produitId ? item.produitId._id : item.produitId,
        nom: item.produitId ? item.produitId.nom : 'Produit indisponible',
        prix: item.prixUnitaire,
        quantite: item.quantité,
        images: item.produitId && item.produitId.images ? item.produitId.images : [],
        description: item.produitId ? item.produitId.description : ''
      })),
      adresseLivraison: order.adresseLivraison,
      methodePaiement: order.methodePaiement || 'Non spécifié',
      dateLivraison: order.dateLivraison,
      dateCreation: order.createdAt,
      paiement: {
        statut: order.paymentStatus || 'Payé',
        methode: order.methodePaiement || 'Carte bancaire',
        reference: order.paymentRef || `PAY-${order._id.toString().slice(-6)}`,
        date: order.dateCommande
      },
      livraison: {
        statut: order.statut,
        suivi: order.trackingNumber || '',
        transporteur: order.deliveryCompany || 'Standard',
        dateExpedition: order.shipmentDate || null,
        dateLivraison: order.dateLivraison || null
      },
      client: {
        nom: order.userId && order.userId.nom ? order.userId.nom : 'Client',
        email: order.userId && order.userId.email ? order.userId.email : '',
        telephone: order.userId && order.userId.telephone ? order.userId.telephone : ''
      }
    };

    return res.status(200).json({
      success: true,
      message: 'Détails de la commande récupérés avec succès',
      commande: mobileOrderDetails
    });
  } catch (error) {
    console.error(`[MOBILE API] Erreur lors de la récupération des détails de la commande: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des détails de la commande',
      error: error.message
    });
  }
};

// Récupérer une commande spécifique pour l'utilisateur
exports.getUserOrderDetails = async (req, res) => {
  try {
    const orderId = req.params.id;
    console.log(`Récupération des détails de la commande ${orderId} pour l'utilisateur: ${req.user.id}`);

    const order = await Order.findOne({
      _id: orderId,
      userId: req.user.id
    })
      .populate('produits.produitId', 'nom prix images description')
      .populate('deliveryPersonId', 'nom prenom telephone');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée ou vous n\'êtes pas autorisé à voir cette commande'
      });
    }

    const formattedOrder = {
      _id: order._id,
      numero: `CMD-${order._id.toString().slice(-6)}`,
      date: order.dateCommande,
      statut: order.statut,
      total: order.total,
      produits: order.produits.map(item => ({
        produitId: item.produitId ? item.produitId._id : item.produitId,
        nom: item.produitId ? item.produitId.nom : 'Produit indisponible',
        prix: item.prixUnitaire,
        quantite: item.quantité,
        images: item.produitId ? item.produitId.images : []
      })),
      adresseLivraison: order.adresseLivraison,
      methodePaiement: order.methodePaiement || 'Non spécifié',
      dateLivraison: order.dateLivraison,
      paymentStatus: order.paymentStatus,
      livreur: order.deliveryPersonId ? {
        nom: `${order.deliveryPersonId.prenom} ${order.deliveryPersonId.nom}`,
        telephone: order.deliveryPersonId.telephone
      } : null
    };

    return res.status(200).json({
      success: true,
      message: 'Détails de la commande récupérés avec succès',
      commande: formattedOrder
    });
  } catch (error) {
    console.error(`Erreur de récupération des détails de la commande: ${error.message}`);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des détails de la commande',
      error: error.message
    });
  }
};

// Exporter le middleware de rate limiting
exports.orderLimiter = orderLimiter;

// Récupérer le nombre total de commandes
exports.getOrderCount = async (req, res) => {
  try {
    console.log('Comptage des commandes totales');
    
    // Vérifier si l'utilisateur est un admin
    if (req.user.role !== 'Admin' && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé. Seuls les administrateurs peuvent accéder à ces statistiques.'
      });
    }
    
    const count = await Order.countDocuments();
    console.log(`Nombre total de commandes: ${count}`);
    
    return res.status(200).json({
      success: true,
      count: count
    });
  } catch (error) {
    console.error(`Erreur lors du comptage des commandes: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors du comptage des commandes',
      error: error.message
    });
  }
};

// Récupérer toutes les commandes (pour admin)
exports.getAllOrders = async (req, res) => {
  try {
    console.log('Récupération de toutes les commandes (admin)');

    // Vérifier si l'utilisateur est un admin
    if (req.user.role !== 'Admin' && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé. Seuls les administrateurs peuvent voir toutes les commandes.'
      });
    }

    const orders = await Order.find({})
      .populate('produits.produitId', 'nom prix images description')
      .populate('userId', 'nom email telephone')
      .sort({ dateCommande: -1 });

    console.log(`Nombre total de commandes trouvées: ${orders.length}`);

    if (!orders || orders.length === 0) {
      console.log('Aucune commande trouvée dans la base de données');
      return res.status(200).json({
        success: true,
        message: 'Aucune commande trouvée',
        commandes: []
      });
    }

    const formattedOrders = orders.map(order => ({
      _id: order._id,
      numero: `CMD-${order._id.toString().slice(-6)}`,
      date: order.dateCommande || order.createdAt,
      statut: order.statut,
      total: order.total,
      client: order.userId ? {
        nom: order.userId.nom || 'Client',
        email: order.userId.email || '',
        telephone: order.userId.telephone || ''
      } : { nom: 'Client inconnu', email: '', telephone: '' },
      produits: order.produits.map(item => ({
        produitId: item.produitId ? item.produitId._id : item.produitId,
        nom: item.produitId ? item.produitId.nom : 'Produit indisponible',
        prix: item.prixUnitaire,
        quantite: item.quantité,
        images: item.produitId ? item.produitId.images : []
      })),
      adresseLivraison: order.adresseLivraison,
      methodePaiement: order.methodePaiement || 'Non spécifié',
      dateLivraison: order.dateLivraison,
      paymentStatus: order.paymentStatus,
      livreur: order.deliveryPersonId ? {
        id: order.deliveryPersonId,
        nom: order.deliveryPersonId.nom || 'Livreur assigné'
      } : null
    }));

    return res.status(200).json({
      success: true,
      message: 'Commandes récupérées avec succès',
      commandes: formattedOrders
    });
  } catch (error) {
    console.error(`Erreur de récupération des commandes: ${error.message}`);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commandes',
      error: error.message
    });
  }
};

// Traiter une commande (processOrderById)
exports.processOrderById = async (req, res) => {
  try {
    const { orderId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(orderId)) {
      return res.status(400).json({
        success: false,
        message: 'ID de commande invalide'
      });
    }

    const order = await Order.findById(orderId);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }
    
    // Vérifier que la commande n'est pas déjà traitée
    if (order.statut !== 'En attente') {
      return res.status(400).json({
        success: false,
        message: `Impossible de traiter une commande avec le statut "${order.statut}"`
      });
    }
    
    // Mettre à jour le statut de la commande
    order.statut = 'En cours de préparation';
    order.updatedAt = new Date();
    
    await order.save();
    
    return res.status(200).json({
      success: true,
      message: 'Commande mise en traitement avec succès',
      commande: {
        _id: order._id,
        statut: order.statut,
        dateCommande: order.dateCommande,
        updatedAt: order.updatedAt
      }
    });
  } catch (error) {
    console.error('Erreur lors du traitement de la commande:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors du traitement de la commande',
      error: error.message
    });
  }
};

// Récupérer les commandes assignées au livreur authentifié
exports.getDeliveryPersonOrders = async (req, res) => {
  try {
    console.log(`Récupération des commandes assignées au livreur: ${req.user.id}`);
    
    // Vérifier si l'utilisateur est un livreur
    if (req.user.role !== 'Livreur') {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé. Seuls les livreurs peuvent accéder à ces commandes.'
      });
    }
    
    // Trouver toutes les commandes assignées à ce livreur
    const orders = await Order.find({ livreurId: req.user.id })
      .populate('produits.produitId', 'nom prix images description stock')
      .populate('userId', 'nom email telephone')
      .sort({ dateCommande: -1 });
      
    console.log(`Nombre de commandes assignées au livreur: ${orders.length}`);
    
    if (!orders || orders.length === 0) {
      console.log('Aucune commande assignée à ce livreur');
      return res.status(200).json({
        success: true,
        message: 'Aucune commande assignée',
        commandes: []
      });
    }
    
    // Formater les commandes pour l'application mobile du livreur
    const formattedOrders = orders.map(order => ({
      _id: order._id,
      numero: `CMD-${order._id.toString().slice(-6)}`,
      date: order.dateCommande,
      statut: order.statut,
      total: order.total,
      produits: order.produits.map(item => ({
        produitId: item.produitId ? item.produitId._id : item.produitId,
        nomProduit: item.produitId ? item.produitId.nom : 'Produit indisponible',
        prixUnitaire: item.prixUnitaire,
        quantité: item.quantité,
        images: item.produitId && item.produitId.images ? item.produitId.images : []
      })),
      adresseLivraison: order.adresseLivraison,
      paymentStatus: order.paymentStatus || 'En attente',
      dateLivraison: order.dateLivraison,
      distance: calculateDistance(order.adresseLivraison), // Fonction fictive pour calculer la distance
      estimatedTime: calculateDeliveryTime(order.adresseLivraison), // Fonction fictive pour estimer le temps
      client: order.userId ? {
        userId: order.userId._id,
        userName: order.userId.nom || 'Client',
        userEmail: order.userId.email || '',
        userPhone: order.userId.telephone || ''
      } : { userName: 'Client', userEmail: '', userPhone: '' }
    }));
    
    return res.status(200).json({
      success: true,
      message: 'Commandes récupérées avec succès',
      commandes: formattedOrders
    });
  } catch (error) {
    console.error(`Erreur lors de la récupération des commandes du livreur: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commandes',
      error: error.message
    });
  }
};

// Fonction fictive pour calculer la distance (dans une vraie application, utilisez un service de géolocalisation)
function calculateDistance(address) {
  // Cette fonction doit être remplacée par un vrai calcul de distance
  // Par exemple, utiliser l'API Google Maps Distance Matrix
  
  // Pour l'exemple, nous retournons une valeur aléatoire entre 1 et 10 km
  return Math.round((Math.random() * 9 + 1) * 10) / 10;
}

// Fonction fictive pour estimer le temps de livraison
function calculateDeliveryTime(address) {
  // Cette fonction doit être remplacée par un vrai calcul de temps
  // Basé sur la distance et la vitesse moyenne
  
  // Pour l'exemple, nous retournons une valeur entre 10 et 30 minutes
  return Math.round(Math.random() * 20 + 10);
}

// Mettre à jour le statut d'une commande par le livreur
exports.updateOrderStatusByDeliveryPerson = async (req, res) => {
  try {
    const { status } = req.body;
    
    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Le statut est requis'
      });
    }
    
    // Vérifier que le statut est valide
    const validStatuses = ['En cours', 'Livrée', 'Annulée'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Statut invalide. Les statuts valides sont: ' + validStatuses.join(', ')
      });
    }
    
    // Vérifier si l'utilisateur est un livreur
    if (req.user.role !== 'Livreur') {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé. Seuls les livreurs peuvent mettre à jour ces commandes.'
      });
    }
    
    // Trouver la commande
    const order = await Order.findOne({ 
      _id: req.params.id,
      livreurId: req.user.id
    });
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée ou vous n\'êtes pas autorisé à la modifier'
      });
    }
    
    // Mettre à jour le statut
    order.statut = status;
    
    // Si livrée, mettre à jour la date de livraison
    if (status === 'Livrée') {
      order.dateLivraison = new Date();
    }
    
    await order.save();
    
    return res.status(200).json({
      success: true,
      message: 'Statut de la commande mis à jour avec succès',
      commande: {
        _id: order._id,
        statut: order.statut,
        dateLivraison: order.dateLivraison
      }
    });
  } catch (error) {
    console.error(`Erreur lors de la mise à jour du statut: ${error.message}`);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du statut',
      error: error.message
    });
  }
};