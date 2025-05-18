const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const deliveryPersonSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^\S+@\S+\.\S+$/, 'Format d\'email invalide']
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  phone: {
    type: String,
    required: true,
    trim: true
  },
  assignedOrders: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order'
  }],
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Middleware pour hacher le mot de passe avant de sauvegarder
deliveryPersonSchema.pre('save', async function(next) {
  const deliveryPerson = this;
  if (deliveryPerson.isModified('password')) {
    deliveryPerson.password = await bcrypt.hash(deliveryPerson.password, 10);
  }
  next();
});

// Méthode pour générer un token JWT
deliveryPersonSchema.methods.generateAuthToken = function() {
  const deliveryPerson = this;
  const token = jwt.sign(
    { id: deliveryPerson._id, role: 'livreur' },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
  return token;
};

// Méthode pour vérifier les credentials
deliveryPersonSchema.statics.findByCredentials = async function(email, password) {
  const DeliveryPerson = this;
  const deliveryPerson = await DeliveryPerson.findOne({ email });
  
  if (!deliveryPerson) {
    throw new Error('Email ou mot de passe incorrect');
  }
  
  const isMatch = await bcrypt.compare(password, deliveryPerson.password);
  
  if (!isMatch) {
    throw new Error('Email ou mot de passe incorrect');
  }
  
  if (!deliveryPerson.isActive) {
    throw new Error('Compte désactivé. Veuillez contacter l\'administrateur');
  }
  
  return deliveryPerson;
};

// Méthode pour retourner l'objet sans le mot de passe
deliveryPersonSchema.methods.toJSON = function() {
  const deliveryPerson = this;
  const deliveryPersonObject = deliveryPerson.toObject();
  
  delete deliveryPersonObject.password;
  
  return deliveryPersonObject;
};

module.exports = mongoose.model('DeliveryPerson', deliveryPersonSchema); 