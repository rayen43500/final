const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    required: true
  },
  montant: {
    type: Number,
    required: true,
    min: 0
  },
  modePaiement: {
    type: String,
    enum: ['carte', 'paypal', 'especes'],
    required: true
  },
  statut: {
    type: String,
    enum: ['En attente', 'Payé', 'Annulé'],
    default: 'En attente'
  },
  transactionId: {
    type: String,
    // Obligatoire seulement pour les paiements par carte ou PayPal
  },
  detailsPaiement: {
    // Stocke des infos supplémentaires selon le mode de paiement
    type: mongoose.Schema.Types.Mixed
  },
  datePaiement: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Middleware pour mettre à jour le statut de la commande associée
paymentSchema.post('save', async function() {
  const Order = mongoose.model('Order');
  
  // Si le paiement est marqué comme payé, mettre à jour le statut de paiement de la commande
  if (this.statut === 'Payé') {
    await Order.findByIdAndUpdate(this.orderId, {
      paymentStatus: 'Payée'
    });
  } else if (this.statut === 'Annulé') {
    await Order.findByIdAndUpdate(this.orderId, {
      paymentStatus: 'Annulée'
    });
  }
});

module.exports = mongoose.model('Payment', paymentSchema); 