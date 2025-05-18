const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const userSchema = new mongoose.Schema({
  nom: {
    type: String,
    required: [true, 'Le nom est requis'],
    trim: true
  },
  email: {
    type: String,
    required: [true, 'L\'email est requis'],
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Veuillez entrer un email valide']
  },
  telephone: {
    type: String,
    trim: true
  },
  motDePasse: {
    type: String,
    required: [true, 'Le mot de passe est requis'],
    minlength: [8, 'Le mot de passe doit contenir au moins 8 caractères'],
    match: [
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
      'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial'
    ],
    select: false
  },
  role: {
    type: String,
    enum: ['Client', 'Admin', 'Livreur'],
    default: 'Client'
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  verificationToken: {
    type: String,
    select: false
  },
  resetPasswordToken: {
    type: String,
    select: false
  },
  resetPasswordExpire: {
    type: Date,
    select: false
  },
  loginAttempts: {
    type: Number,
    default: 0
  },
  lockUntil: {
    type: Date
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Hash le mot de passe avant de sauvegarder
userSchema.pre('save', async function(next) {
  if (!this.isModified('motDePasse')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.motDePasse = await bcrypt.hash(this.motDePasse, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Méthode pour comparer les mots de passe
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    if (!this.motDePasse) {
      throw new Error('Mot de passe non trouvé');
    }
    return await bcrypt.compare(candidatePassword, this.motDePasse);
  } catch (error) {
    console.error('Erreur lors de la comparaison des mots de passe:', error);
    throw error;
  }
};

// Méthode pour générer un token de vérification
userSchema.methods.generateVerificationToken = function() {
  const verificationToken = crypto.randomBytes(20).toString('hex');
  this.verificationToken = verificationToken;
  return verificationToken;
};

// Méthode pour générer un token de réinitialisation
userSchema.methods.generateResetPasswordToken = function() {
  const resetToken = crypto.randomBytes(20).toString('hex');
  this.resetPasswordToken = resetToken;
  this.resetPasswordExpire = Date.now() + 3600000; // 1 heure
  return resetToken;
};

// Méthode pour gérer les tentatives de connexion
userSchema.methods.incrementLoginAttempts = async function() {
  // NOTE: Cette méthode a été modifiée pour désactiver le verrouillage du compte
  // En production, il est recommandé de réactiver cette sécurité
  
  // Version originale commentée :
  /*
  if (this.lockUntil && this.lockUntil > Date.now()) {
    throw new Error('Compte temporairement bloqué');
  }

  this.loginAttempts += 1;
  
  if (this.loginAttempts >= 5) {
    this.lockUntil = Date.now() + 30 * 60 * 1000; // 30 minutes
  }
  
  await this.save({ validateBeforeSave: false });
  */
  
  // Version désactivée (ne fait rien)
  return;
};

// Méthode pour réinitialiser les tentatives de connexion
userSchema.methods.resetLoginAttempts = async function() {
  // Version désactivée pour correspondre à la méthode incrementLoginAttempts
  return;
  
  // Version originale commentée :
  /*
  this.loginAttempts = 0;
  this.lockUntil = undefined;
  await this.save({ validateBeforeSave: false });
  */
};

module.exports = mongoose.model('User', userSchema); 