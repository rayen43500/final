const Payment = require('../models/Payment');
const Order = require('../models/Order');
const { rateLimit } = require('express-rate-limit');
require('dotenv').config();

// Intégration de Stripe pour les paiements par carte
const stripe = process.env.STRIPE_SECRET_KEY 
  ? require('stripe')(process.env.STRIPE_SECRET_KEY)
  : null;

// Rate limiter pour les paiements
const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // limite à 20 requêtes par fenêtre
  message: 'Trop de tentatives de paiement, veuillez réessayer plus tard.'
});

// Traiter le paiement
exports.processPayment = async (req, res) => {
  try {
    const { orderId, modePaiement, token } = req.body;

    // Vérifier si la commande existe et appartient à l'utilisateur
    const order = await Order.findOne({ 
      _id: orderId, 
      userId: req.user.id,
      paymentStatus: 'En attente' // Seulement les commandes en attente de paiement
    });

    if (!order) {
      return res.status(404).json({ message: 'Commande non trouvée ou déjà payée' });
    }

    let payment = null;
    
    // Traiter le paiement en fonction du mode choisi
    switch(modePaiement) {
      case 'carte':
        // Vérifier si Stripe est configuré
        if (!stripe) {
          return res.status(500).json({ message: 'Le paiement par carte n\'est pas disponible actuellement' });
        }
        
        if (!token) {
          return res.status(400).json({ message: 'Token de paiement requis' });
        }
        
        try {
          // Créer un paiement Stripe
          const charge = await stripe.charges.create({
            amount: Math.round(order.total * 100), // Montant en centimes
            currency: 'eur',
            source: token,
            description: `Paiement pour la commande #${order._id}`
          });
          
          // Créer l'enregistrement de paiement
          payment = new Payment({
            orderId: order._id,
            montant: order.total,
            modePaiement: 'carte',
            statut: 'Payé',
            transactionId: charge.id,
            detailsPaiement: {
              chargeId: charge.id,
              cardBrand: charge.payment_method_details?.card?.brand,
              last4: charge.payment_method_details?.card?.last4
            }
          });
        } catch (stripeError) {
          console.error('Erreur Stripe:', stripeError);
          return res.status(400).json({ 
            message: 'Erreur lors du traitement du paiement', 
            details: stripeError.message 
          });
        }
        break;
        
      case 'paypal':
        // Vérifier le token PayPal (dans une implémentation réelle, vous utiliseriez l'API PayPal)
        if (!token) {
          return res.status(400).json({ message: 'Token PayPal requis' });
        }
        
        // Dans une implémentation complète, vous vérifieriez le token avec l'API PayPal
        // Simulons une réponse positive pour cet exemple
        payment = new Payment({
          orderId: order._id,
          montant: order.total,
          modePaiement: 'paypal',
          statut: 'Payé',
          transactionId: `pp_${Date.now()}`, // Dans une implémentation réelle, utilisez l'ID fourni par PayPal
          detailsPaiement: {
            paypalEmail: req.body.paypalEmail || req.user.email
          }
        });
        break;
        
      case 'especes':
        // Paiement en espèces - toujours en attente jusqu'à validation par l'admin
        payment = new Payment({
          orderId: order._id,
          montant: order.total,
          modePaiement: 'especes',
          statut: 'En attente',
          detailsPaiement: {
            adresseLivraison: order.adresseLivraison
          }
        });
        break;
        
      default:
        return res.status(400).json({ message: 'Mode de paiement non pris en charge' });
    }
    
    // Sauvegarder le paiement
    await payment.save();
    
    // Si paiement immédiat (carte/paypal), mettre à jour le statut de la commande
    if (payment.statut === 'Payé') {
      order.paymentStatus = 'Payée';
      await order.save();
    }
    
    res.status(201).json({ 
      message: 'Paiement traité avec succès',
      status: payment.statut,
      paymentId: payment._id
    });
    
  } catch (error) {
    console.error('Erreur de paiement:', error);
    res.status(500).json({ message: error.message });
  }
};

// Obtenir les détails d'un paiement (admin uniquement)
exports.getPaymentDetails = async (req, res) => {
  try {
    const payment = await Payment.findById(req.params.id).populate('orderId');
    
    if (!payment) {
      return res.status(404).json({ message: 'Paiement non trouvé' });
    }
    
    res.json(payment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Valider un paiement en espèces (admin uniquement)
exports.validateCashPayment = async (req, res) => {
  try {
    const payment = await Payment.findById(req.params.id);
    
    if (!payment) {
      return res.status(404).json({ message: 'Paiement non trouvé' });
    }
    
    if (payment.modePaiement !== 'especes') {
      return res.status(400).json({ message: 'Ce n\'est pas un paiement en espèces' });
    }
    
    if (payment.statut !== 'En attente') {
      return res.status(400).json({ message: 'Ce paiement n\'est pas en attente de validation' });
    }
    
    // Valider le paiement
    payment.statut = 'Payé';
    await payment.save();
    
    // Le middleware post-save du modèle Payment mettra à jour la commande automatiquement
    
    res.json({ 
      message: 'Paiement validé avec succès',
      payment
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Annuler un paiement (admin uniquement)
exports.cancelPayment = async (req, res) => {
  try {
    const payment = await Payment.findById(req.params.id);
    
    if (!payment) {
      return res.status(404).json({ message: 'Paiement non trouvé' });
    }
    
    if (payment.statut === 'Payé') {
      // Si c'est un paiement par carte, il faudrait gérer le remboursement via Stripe
      if (payment.modePaiement === 'carte' && stripe && payment.transactionId) {
        try {
          await stripe.refunds.create({
            charge: payment.transactionId
          });
        } catch (stripeError) {
          console.error('Erreur lors du remboursement Stripe:', stripeError);
          return res.status(400).json({ 
            message: 'Erreur lors du remboursement', 
            details: stripeError.message 
          });
        }
      }
      
      // Pour PayPal, implémenter le remboursement via l'API PayPal
    }
    
    // Marquer le paiement comme annulé
    payment.statut = 'Annulé';
    await payment.save();
    
    // Le middleware post-save du modèle Payment mettra à jour la commande automatiquement
    
    res.json({ 
      message: 'Paiement annulé avec succès',
      payment
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Exporter le middleware de rate limiting
exports.paymentLimiter = paymentLimiter; 