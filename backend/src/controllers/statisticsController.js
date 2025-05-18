const Product = require('../models/Product');
const Order = require('../models/Order');
const User = require('../models/User');
const { validationResult } = require('express-validator');
const mongoose = require('mongoose');

// Obtenir les statistiques générales pour le dashboard
exports.getGeneralStats = async (req, res) => {
  try {
    // Récupérer toutes les commandes
    const allOrders = await Order.find();
    
    // Calcul des statistiques de base
    const revenuTotal = allOrders
      .filter(order => order.statut === 'Livrée')
      .reduce((sum, order) => sum + order.total, 0);
    
    const commandesTotal = allOrders.length;
    
    // Compter les commandes livrées
    const commandesLivrees = allOrders.filter(order => order.statut === 'Livrée').length;
    
    // Compter les clients uniques
    const clientsUniques = [...new Set(allOrders.map(order => order.userId.toString()))].length;
    
    // Compter les commandes par statut
    const commandesParStatut = {
      'En attente': allOrders.filter(order => order.statut === 'En attente').length,
      'Expédiée': allOrders.filter(order => order.statut === 'Expédiée').length,
      'Livrée': commandesLivrees,
      'Annulée': allOrders.filter(order => order.statut === 'Annulée').length,
    };
    
    // Calculer le taux de conversion (simulé)
    const tauxConversion = commandesTotal > 0 ? (commandesLivrees / commandesTotal * 100).toFixed(1) : 0;
    
    // Pour les données de tendance, nous utilisons des valeurs fictives pour l'instant
    // car nous n'avons pas de données historiques
    const statsData = {
      revenuTotal: revenuTotal,
      revenuComparaison: 0, // Pas de comparaison pour l'instant
      commandesTotal: commandesTotal,
      commandesComparaison: 0, // Pas de comparaison pour l'instant
      clientsTotal: clientsUniques,
      clientsComparaison: 0,
      vuesProduits: 0, // Données fictives
      vuesComparaison: 0,
      tauxConversion: parseFloat(tauxConversion),
      tauxConversionComparaison: 0,
      commandesParStatut: commandesParStatut,
      // Utiliser les données fictives pour les sections non encore implémentées
      produitsBestSellers: await getBestSellingProducts(),
      ventesMensuelles: await getMonthlySales(),
      ventesParCategorie: await getSalesByCategoryInternal()
    };
    
    res.json(statsData);
  } catch (error) {
    console.error('Erreur dans getGeneralStats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques',
      error: error.message
    });
  }
};

// Obtenir les produits les plus vendus
exports.getBestSellingProducts = async (req, res) => {
  try {
    const bestSellers = await getBestSellingProducts();
    res.json(bestSellers);
  } catch (error) {
    console.error('Erreur dans getBestSellingProducts:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des produits les plus vendus',
      error: error.message
    });
  }
};

// Obtenir les ventes par catégorie
exports.getSalesByCategory = async (req, res) => {
  try {
    // Récupérer toutes les commandes
    const orders = await Order.find().populate('produits.produitId', 'categorie');
    
    // Si aucune commande n'est trouvée
    if (!orders || orders.length === 0) {
      return res.status(200).json([]);
    }
    
    // Initialiser les compteurs
    let totalCommandes = orders.length;
    let totalCommandesLivrees = 0;
    let revenuTotal = 0;
    
    // Calculer les statistiques
    orders.forEach(order => {
      // Compter toutes les commandes indépendamment du statut
      
      // Ajouter au total des commandes livrées
      if (order.statut === 'Livrée') {
        totalCommandesLivrees++;
        revenuTotal += order.total; // Ajouter le montant des commandes livrées
      }
    });
    
    // Créer l'objet de réponse
    const categoryStats = [
      { categorie: 'Total des commandes', valeur: totalCommandes },
      { categorie: 'Commandes livrées', valeur: totalCommandesLivrees },
      { categorie: 'Revenu total (DT)', valeur: revenuTotal.toFixed(2) }
    ];
    
    res.json(categoryStats);
  } catch (error) {
    console.error('Erreur dans getSalesByCategory:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques',
      error: error.message
    });
  }
};

// Fonctions utilitaires

// Calculer le revenu sur une période
async function calculateRevenue(startDate, daysBack) {
  const endDate = new Date(startDate);
  const beginDate = new Date(startDate);
  beginDate.setDate(beginDate.getDate() - daysBack);
  
  try {
    const result = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: beginDate, $lte: endDate },
          status: { $in: ['completed', 'delivered'] }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$totalPrice' }
        }
      }
    ]);
    
    return result.length > 0 ? result[0].total : 0;
  } catch (error) {
    console.error('Erreur dans calculateRevenue:', error);
    return 0;
  }
}

// Compter les commandes sur une période
async function countOrders(startDate, daysBack) {
  const endDate = new Date(startDate);
  const beginDate = new Date(startDate);
  beginDate.setDate(beginDate.getDate() - daysBack);
  
  try {
    const count = await Order.countDocuments({
      createdAt: { $gte: beginDate, $lte: endDate }
    });
    
    return count;
  } catch (error) {
    console.error('Erreur dans countOrders:', error);
    return 0;
  }
}

// Compter les nouveaux utilisateurs sur une période
async function countNewUsers(startDate, daysBack) {
  const endDate = new Date(startDate);
  const beginDate = new Date(startDate);
  beginDate.setDate(beginDate.getDate() - daysBack);
  
  try {
    const count = await User.countDocuments({
      createdAt: { $gte: beginDate, $lte: endDate }
    });
    
    return count;
  } catch (error) {
    console.error('Erreur dans countNewUsers:', error);
    return 0;
  }
}

// Obtenir le nombre de vues de produits sur une période (simulation)
function getProductViews(startDate, daysBack) {
  // Comme il s'agit d'une simulation, nous retournons une valeur basée sur la date
  const seed = startDate.getMonth() * 1000 + startDate.getDate() * 100;
  return seed + Math.floor(Math.random() * 1000);
}

// Calculer le pourcentage de changement entre deux valeurs
function calculatePercentageChange(oldValue, newValue) {
  if (oldValue === 0) return newValue > 0 ? 100 : 0;
  return parseFloat(((newValue - oldValue) / oldValue * 100).toFixed(1));
}

// Obtenir les produits les plus vendus
async function getBestSellingProducts() {
  try {
    const result = await Order.aggregate([
      { $match: { statut: { $in: ['Livrée', 'Expédiée'] } } },
      { $unwind: '$produits' },
      {
        $group: {
          _id: '$produits.produitId',
          totalSold: { $sum: '$produits.quantité' },
          totalRevenue: { $sum: { $multiply: ['$produits.prixUnitaire', '$produits.quantité'] } }
        }
      },
      { $sort: { totalSold: -1 } },
      { $limit: 5 },
      {
        $lookup: {
          from: 'products',
          localField: '_id',
          foreignField: '_id',
          as: 'productDetails'
        }
      },
      { $unwind: { path: '$productDetails', preserveNullAndEmptyArrays: true } },
      {
        $project: {
          _id: 0,
          nom: { $ifNull: ['$productDetails.nom', 'Produit inconnu'] },
          ventes: '$totalSold',
          revenu: '$totalRevenue'
        }
      }
    ]);
    
    // Si aucun résultat, retourner des données fictives
    if (result.length === 0) {
      return [
        { nom: 'Doliprane 1000mg', ventes: 28, revenu: 168.72 },
        { nom: 'Advil 200mg', ventes: 45, revenu: 584.55 },
        { nom: 'Smecta', ventes: 12, revenu: 155.88 },
        { nom: 'Vitamines C', ventes: 24, revenu: 598.00 },
        { nom: 'Sérum Physiologique', ventes: 32, revenu: 255.68 }
      ];
    }
    
    return result;
  } catch (error) {
    console.error('Erreur dans getBestSellingProducts:', error);
    return [
      { nom: 'Doliprane 1000mg', ventes: 28, revenu: 168.72 },
      { nom: 'Advil 200mg', ventes: 45, revenu: 584.55 },
      { nom: 'Smecta', ventes: 12, revenu: 155.88 },
      { nom: 'Vitamines C', ventes: 24, revenu: 598.00 },
      { nom: 'Sérum Physiologique', ventes: 32, revenu: 255.68 }
    ];
  }
}

// Obtenir les ventes mensuelles de l'année en cours
async function getMonthlySales() {
  try {
    const currentYear = new Date().getFullYear();
    const startOfYear = new Date(currentYear, 0, 1);
    const endOfYear = new Date(currentYear, 11, 31);
    
    const result = await Order.aggregate([
      {
        $match: {
          dateCommande: { $gte: startOfYear, $lte: endOfYear },
          statut: { $in: ['Livrée', 'Expédiée'] }
        }
      },
      {
        $group: {
          _id: { $month: '$dateCommande' },
          ventes: { $sum: '$total' }
        }
      },
      { $sort: { _id: 1 } }
    ]);
    
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    // Préparer les données mensuelles complètes (tous les mois)
    const monthlySales = months.map((month, index) => {
      const monthData = result.find(r => r._id === index + 1);
      return {
        mois: month,
        ventes: monthData ? monthData.ventes : 0
      };
    });
    
    // Si aucune donnée, retourner des données par défaut
    if (result.length === 0) {
      return [
        { mois: 'Jan', ventes: 0 },
        { mois: 'Fév', ventes: 0 },
        { mois: 'Mar', ventes: 0 },
        { mois: 'Avr', ventes: 0 },
        { mois: 'Mai', ventes: 0 },
        { mois: 'Juin', ventes: 0 },
        { mois: 'Juil', ventes: 0 },
        { mois: 'Août', ventes: 0 },
        { mois: 'Sep', ventes: 0 },
        { mois: 'Oct', ventes: 0 },
        { mois: 'Nov', ventes: 0 },
        { mois: 'Déc', ventes: 0 }
      ];
    }
    
    return monthlySales;
  } catch (error) {
    console.error('Erreur dans getMonthlySales:', error);
    // Retourner des données fictives en cas d'erreur
    return [
      { mois: 'Jan', ventes: 0 },
      { mois: 'Fév', ventes: 0 },
      { mois: 'Mar', ventes: 0 },
      { mois: 'Avr', ventes: 0 },
      { mois: 'Mai', ventes: 0 },
      { mois: 'Juin', ventes: 0 },
      { mois: 'Juil', ventes: 0 },
      { mois: 'Août', ventes: 0 },
      { mois: 'Sep', ventes: 0 },
      { mois: 'Oct', ventes: 0 },
      { mois: 'Nov', ventes: 0 },
      { mois: 'Déc', ventes: 0 }
    ];
  }
}

// Obtenir les ventes par catégorie
async function getSalesByCategory() {
  try {
    const result = await Order.aggregate([
      { $match: { status: { $in: ['completed', 'delivered'] } } },
      { $unwind: '$products' },
      {
        $lookup: {
          from: 'products',
          localField: 'products.product',
          foreignField: '_id',
          as: 'productDetails'
        }
      },
      { $unwind: '$productDetails' },
      {
        $lookup: {
          from: 'categories',
          localField: 'productDetails.category',
          foreignField: '_id',
          as: 'categoryDetails'
        }
      },
      { $unwind: '$categoryDetails' },
      {
        $group: {
          _id: '$categoryDetails.name',
          totalSales: { $sum: { $multiply: ['$products.price', '$products.quantity'] } }
        }
      },
      { $sort: { totalSales: -1 } }
    ]);
    
    // Calculer le total pour obtenir les pourcentages
    const totalSales = result.reduce((acc, curr) => acc + curr.totalSales, 0);
    
    const categorySales = result.map(category => ({
      categorie: category._id,
      pourcentage: Math.round((category.totalSales / totalSales) * 100)
    }));
    
    // Si aucun résultat, retourner des données fictives adaptées à la pharmacie
    if (categorySales.length === 0) {
      return [
        { categorie: 'Médicaments', pourcentage: 45 },
        { categorie: 'Parapharmacie', pourcentage: 25 },
        { categorie: 'Orthopédie', pourcentage: 15 },
        { categorie: 'Cosmétiques', pourcentage: 10 },
        { categorie: 'Nutrition', pourcentage: 5 }
      ];
    }
    
    return categorySales;
  } catch (error) {
    console.error('Erreur dans getSalesByCategory:', error);
    return [
      { categorie: 'Médicaments', pourcentage: 45 },
      { categorie: 'Parapharmacie', pourcentage: 25 },
      { categorie: 'Orthopédie', pourcentage: 15 },
      { categorie: 'Cosmétiques', pourcentage: 10 },
      { categorie: 'Nutrition', pourcentage: 5 }
    ];
  }
}

// Fonction interne pour récupérer les statistiques par catégorie
async function getSalesByCategoryInternal() {
  try {
    // Récupérer toutes les commandes
    const orders = await Order.find();
    
    // Si aucune commande n'est trouvée
    if (!orders || orders.length === 0) {
      return [];
    }
    
    // Initialiser les compteurs
    let totalCommandes = orders.length;
    let totalCommandesLivrees = 0;
    let revenuTotal = 0;
    
    // Calculer les statistiques
    orders.forEach(order => {
      // Ajouter au total des commandes livrées
      if (order.statut === 'Livrée') {
        totalCommandesLivrees++;
        revenuTotal += order.total;
      }
    });
    
    // Créer l'objet de réponse
    return [
      { categorie: 'Total des commandes', valeur: totalCommandes },
      { categorie: 'Commandes livrées', valeur: totalCommandesLivrees },
      { categorie: 'Revenu total (DT)', valeur: revenuTotal.toFixed(2) }
    ];
  } catch (error) {
    console.error('Erreur dans getSalesByCategoryInternal:', error);
    return [];
  }
} 