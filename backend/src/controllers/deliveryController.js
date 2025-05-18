const DeliveryPerson = require('../models/DeliveryPerson');
const Order = require('../models/Order');
const Payment = require('../models/Payment');
const User = require('../models/User');
const { rateLimit } = require('express-rate-limit');

// Rate limiter pour les endpoints livreurs
const deliveryLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limite à 100 requêtes par fenêtre
  message: 'Trop de requêtes, veuillez réessayer plus tard.'
});

// Authentification des livreurs
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Vérifier les credentials
    const deliveryPerson = await DeliveryPerson.findByCredentials(email, password);
    
    // Générer un token JWT
    const token = deliveryPerson.generateAuthToken();
    
    res.json({
      deliveryPerson,
      token
    });
  } catch (error) {
    res.status(401).json({ message: error.message });
  }
};

// Récupérer le profil du livreur connecté
exports.getProfile = async (req, res) => {
  try {
    res.json(req.deliveryPerson);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Récupérer les commandes assignées au livreur connecté
exports.getAssignedOrders = async (req, res) => {
  try {
    const orders = await Order.find({ 
      deliveryPersonId: req.deliveryPerson._id,
      statut: { $in: ['Expédiée', 'En attente'] } // Seulement les commandes non livrées
    })
    .select('_id userId adresseLivraison statut paymentStatus dateCommande total')
    .populate('userId', 'nom email phone');
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Récupérer les détails d'une commande spécifique
exports.getOrderDetails = async (req, res) => {
  try {
    const order = await Order.findOne({
      _id: req.params.id,
      deliveryPersonId: req.deliveryPerson._id
    })
    .populate('produits.produitId')
    .populate('userId', 'nom email phone');
    
    if (!order) {
      return res.status(404).json({ message: 'Commande non trouvée ou non assignée à ce livreur' });
    }
    
    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Récupérer les informations client d'une commande
exports.getClientInfo = async (req, res) => {
  try {
    // Vérifier que la commande est bien assignée au livreur
    const order = await Order.findOne({
      _id: req.params.id,
      deliveryPersonId: req.deliveryPerson._id
    });
    
    if (!order) {
      return res.status(404).json({ message: 'Commande non trouvée ou non assignée à ce livreur' });
    }
    
    // Récupérer les informations client
    const client = await User.findById(order.userId)
      .select('nom email phone');
    
    if (!client) {
      return res.status(404).json({ message: 'Client non trouvé' });
    }
    
    res.json({
      clientInfo: client,
      adresseLivraison: order.adresseLivraison,
      montantTotal: order.total,
      modePaiement: order.paymentStatus === 'En attente' ? 'especes' : 'prépayé'
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Confirmer la livraison et le paiement d'une commande
exports.confirmDelivery = async (req, res) => {
  try {
    // Vérifier que la commande est bien assignée au livreur
    const order = await Order.findOne({
      _id: req.params.id,
      deliveryPersonId: req.deliveryPerson._id,
      statut: { $in: ['Expédiée', 'En attente'] } // Seulement les commandes non livrées
    });
    
    if (!order) {
      return res.status(404).json({ message: 'Commande non trouvée, déjà livrée ou non assignée à ce livreur' });
    }
    
    // Mettre à jour le statut de la commande
    order.statut = 'Livrée';
    
    // Si la commande est payée en espèces et pas encore marquée comme payée
    if (order.paymentStatus === 'En attente') {
      order.paymentStatus = 'Payée';
      
      // Créer un paiement
      const payment = new Payment({
        orderId: order._id,
        montant: order.total,
        modePaiement: 'especes',
        statut: 'Payé',
        detailsPaiement: {
          confirmedBy: req.deliveryPerson._id,
          confirmationDate: new Date()
        }
      });
      
      await payment.save();
    }
    
    await order.save();
    
    res.json({
      message: 'Livraison et paiement confirmés avec succès',
      order
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Exporter le middleware de rate limiting
exports.deliveryLimiter = deliveryLimiter; 