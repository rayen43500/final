const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  nom: {
    type: String,
    required: [true, 'Le nom de la catégorie est requis'],
    trim: true,
    unique: true
  },
  slug: {
    type: String,
    required: [true, 'Le slug est requis'],
    unique: true,
    lowercase: true
  },
  description: {
    type: String,
    trim: true
  },
  parentCategory: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    default: null
  },
  isActive: {
    type: Boolean,
    default: true
  },
  colorName: {
    type: String,
    enum: ['blue', 'red', 'green', 'orange', 'purple', 'teal', 'pink', 'amber', 'indigo', 'cyan'],
    default: 'blue'
  },
  iconName: {
    type: String,
    enum: ['devices', 'headphones', 'computer', 'watch', 'speaker', 'home', 'phone_android', 'tv', 'camera_alt', 'videogame_asset', 'sports_esports', 'memory', 'category'],
    default: 'category'
  }
}, {
  timestamps: true
});

// Middleware pour générer le slug avant de sauvegarder
categorySchema.pre('save', function(next) {
  if (!this.isModified('nom')) return next();
  
  this.slug = this.nom
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
  
  next();
});

module.exports = mongoose.model('Category', categorySchema); 