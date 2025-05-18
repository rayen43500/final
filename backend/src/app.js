const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const { errorHandler } = require('./middleware/error');
const { protect } = require('./middleware/auth');

// Import routes
const authRoutes = require('./routes/authRoutes');
const productRoutes = require('./routes/productRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const cartRoutes = require('./routes/cartRoutes');
const orderRoutes = require('./routes/orderRoutes');
const promotionRoutes = require('./routes/promotionRoutes');
const commandesRoutes = require('./routes/commandesRoutes');
const panierRoutes = require('./routes/panierRoutes');
const userRoutes = require('./routes/userRoutes');
const statisticsRoutes = require('./routes/statisticsRoutes');

const app = express();

// Middleware
app.use(cors({
  origin: function(origin, callback) {
    // Autoriser les requêtes sans origine (comme les appels d'API mobile)
    if (!origin) return callback(null, true);
    
    // Autoriser toutes les origines localhost, quel que soit le port
    if (origin.startsWith('http://localhost:')) {
      return callback(null, true);
    }
    
    // Liste des autres origines autorisées si nécessaire
    const allowedOrigins = [
      'http://127.0.0.1:5500',
      // Ajoutez d'autres origines non-localhost si nécessaire
    ];
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Bloqué par la politique CORS'));
    }
  },
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/cart', protect, cartRoutes);
app.use('/api/orders', protect, orderRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/commandes', protect, commandesRoutes);
app.use('/api/panier', protect, panierRoutes);
app.use('/api/users', userRoutes);
app.use('/api/statistics', statisticsRoutes);

// Endpoint de statut pour tester la connexion
app.get('/api/status', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API opérationnelle',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// 404 handler
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

// Error handling
app.use(errorHandler);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// Database connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));

module.exports = app; 