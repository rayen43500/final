require('dotenv').config();
const mongoose = require('mongoose');
const Promotion = require('../models/Promotion');
const Product = require('../models/Product');
const Category = require('../models/Category');

// Connexion à la base de données
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('Connexion à MongoDB établie pour seeder les promotions'))
.catch(err => {
  console.error('Erreur de connexion à MongoDB:', err);
  process.exit(1);
});

// Fonctions utilitaires pour la gestion des dates
const addDays = (date, days) => {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
};

const today = new Date();
const inOneMonth = addDays(today, 30);
const inTwoWeeks = addDays(today, 14);
const yesterday = addDays(today, -1);

// Fonction pour créer des promotions
const seedPromotions = async () => {
  try {
    // Supprimer toutes les promotions existantes
    await Promotion.deleteMany({});
    console.log('Toutes les promotions existantes ont été supprimées');

    // Récupérer quelques catégories et produits pour les promotions
    const categories = await Category.find().limit(2);
    const products = await Product.find().limit(3);

    if (categories.length === 0 || products.length === 0) {
      console.error('Aucune catégorie ou produit trouvé. Veuillez d\'abord seeder les catégories et produits.');
      process.exit(1);
    }

    // Créer des promotions
    const promotions = [
      // Promotion sur une catégorie (20% de réduction)
      {
        nom: 'Soldes d\'été sur la catégorie',
        type: 'categorie',
        cible: categories[0]._id,
        typeRef: 'Category',
        typeReduction: 'pourcentage',
        valeurReduction: 20,
        dateDebut: today,
        dateFin: inOneMonth,
        isActive: true,
        description: '20% de réduction sur tous les produits de la catégorie'
      },
      // Promotion sur un produit spécifique (10 DT de réduction)
      {
        nom: 'Offre spéciale produit',
        type: 'produit',
        cible: products[0]._id,
        typeRef: 'Product',
        typeReduction: 'montant',
        valeurReduction: 10,
        dateDebut: today,
        dateFin: inTwoWeeks,
        isActive: true,
        codePromo: 'PROD10',
        description: '10 DT de réduction sur ce produit'
      },
      // Promotion flash sur un produit (50% de réduction)
      {
        nom: 'Promo Flash',
        type: 'produit',
        cible: products[1]._id,
        typeRef: 'Product',
        typeReduction: 'pourcentage',
        valeurReduction: 50,
        dateDebut: today,
        dateFin: addDays(today, 2),
        isActive: true,
        description: 'Promotion flash de 50% pendant 2 jours seulement !'
      },
      // Promotion expirée (pour les tests)
      {
        nom: 'Promotion Expirée',
        type: 'categorie',
        cible: categories[1]._id,
        typeRef: 'Category',
        typeReduction: 'pourcentage',
        valeurReduction: 30,
        dateDebut: addDays(yesterday, -10),
        dateFin: yesterday,
        isActive: true,
        description: 'Cette promotion est expirée'
      },
      // Promotion avec code promo
      {
        nom: 'Code Promo Spécial',
        type: 'categorie',
        cible: categories[1]._id,
        typeRef: 'Category',
        typeReduction: 'pourcentage',
        valeurReduction: 15,
        dateDebut: today,
        dateFin: inOneMonth,
        isActive: true,
        codePromo: 'SUMMER15',
        description: 'Utilisez le code SUMMER15 pour 15% de réduction'
      }
    ];

    // Insérer les promotions dans la base de données
    await Promotion.insertMany(promotions);

    console.log(`${promotions.length} promotions ont été créées avec succès`);
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors de la création des promotions:', error);
    process.exit(1);
  }
};

// Exécuter le seeder
seedPromotions(); 