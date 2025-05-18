const mongoose = require('mongoose');
const dotenv = require('dotenv');
const TestStatistic = require('../models/TestStatistic');
const User = require('../models/User');

// Charger les variables d'environnement
dotenv.config();

// Connexion à MongoDB
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => {
  console.error('MongoDB connection error:', err);
  process.exit(1);
});

// Données de test
const testTypes = ['Performance', 'Fonctionnel', 'Intégration', 'Unitaire', 'Autre'];
const modules = ['Authentification', 'Panier', 'Paiement', 'Produits', 'Commandes', 'Utilisateurs'];
const environments = ['Développement', 'Test', 'Staging', 'Production'];

// Fonction pour générer un nombre aléatoire entre min et max
const getRandomInt = (min, max) => {
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

// Fonction pour générer un tableau de dates réparties sur les 90 derniers jours
const generateDates = (count) => {
  const dates = [];
  const now = new Date();
  
  for (let i = 0; i < count; i++) {
    const date = new Date(now);
    // Répartir les dates sur les 90 derniers jours
    date.setDate(date.getDate() - getRandomInt(0, 90));
    dates.push(date);
  }
  
  return dates;
};

// Fonction pour générer les données de test
const generateTestData = async (count) => {
  try {
    // Récupérer un utilisateur administrateur pour l'attribuer comme exécuteur
    const admin = await User.findOne({ role: 'Admin' });
    const developer = await User.findOne({ role: 'Developpeur' });
    
    // Si aucun administrateur n'est trouvé, utiliser null
    const executedBy = admin ? admin._id : (developer ? developer._id : null);
    
    // Générer des dates réparties
    const dates = generateDates(count);

    // Préparer les données
    const testData = [];
    
    // Créer des statistiques pour chaque module
    for (const module of modules) {
      // Pour chaque module, créer plusieurs types de tests
      for (let i = 0; i < getRandomInt(3, 8); i++) {
        const testName = `Test ${i + 1} - ${module}`;
        const testType = testTypes[getRandomInt(0, testTypes.length - 1)];
        
        // Pour chaque test, générer plusieurs exécutions
        for (let j = 0; j < getRandomInt(5, 15); j++) {
          const success = Math.random() > 0.2; // 80% de succès
          const errorCount = success ? 0 : getRandomInt(1, 5);
          const warningCount = getRandomInt(0, 3);
          const duration = getRandomInt(50, 5000); // Entre 50ms et 5000ms
          
          testData.push({
            testName,
            testType,
            executionDate: dates[getRandomInt(0, dates.length - 1)],
            duration,
            success,
            errorCount,
            warningCount,
            module,
            environment: environments[getRandomInt(0, environments.length - 1)],
            executedBy,
            details: {
              browser: ['Chrome', 'Firefox', 'Safari'][getRandomInt(0, 2)],
              os: ['Windows', 'MacOS', 'Linux'][getRandomInt(0, 2)],
              resolution: ['1920x1080', '1366x768', '2560x1440'][getRandomInt(0, 2)]
            },
            notes: success ? 'Test réussi' : `Échec avec ${errorCount} erreurs`
          });
        }
      }
    }
    
    // Insérer les données dans la base de données
    await TestStatistic.insertMany(testData);
    
    console.log(`${testData.length} statistiques de test ont été générées`);
    
    // Fermer la connexion à MongoDB
    mongoose.connection.close();
  } catch (error) {
    console.error('Erreur lors de la génération des données:', error);
    mongoose.connection.close();
    process.exit(1);
  }
};

// Nombre de dates à générer
const COUNT = 90;

// Exécuter la fonction de génération
generateTestData(COUNT)
  .then(() => console.log('Génération des données terminée'))
  .catch(error => console.error('Erreur:', error)); 