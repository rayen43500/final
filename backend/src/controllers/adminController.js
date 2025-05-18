const DeliveryPerson = require('../models/DeliveryPerson');
const Order = require('../models/Order');

// Créer un nouveau livreur
exports.createDeliveryPerson = async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;
    
    // Vérifier si l'email est déjà utilisé
    const existingDeliveryPerson = await DeliveryPerson.findOne({ email });
    if (existingDeliveryPerson) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé' });
    }
    
    // Créer le livreur
    const deliveryPerson = new DeliveryPerson({
      name,
      email,
      password,
      phone
    });
    
    await deliveryPerson.save();
    
    res.status(201).json({
      message: 'Livreur créé avec succès',
      deliveryPerson: {
        _id: deliveryPerson._id,
        name: deliveryPerson.name,
        email: deliveryPerson.email,
        phone: deliveryPerson.phone
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Récupérer tous les livreurs
exports.getAllDeliveryPersons = async (req, res) => {
  try {
    const deliveryPersons = await DeliveryPerson.find()
      .select('-password')
      .sort({ createdAt: -1 });
    
    res.json(deliveryPersons);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Récupérer un livreur par son ID
exports.getDeliveryPerson = async (req, res) => {
  try {
    const deliveryPerson = await DeliveryPerson.findById(req.params.id)
      .select('-password');
    
    if (!deliveryPerson) {
      return res.status(404).json({ message: 'Livreur non trouvé' });
    }
    
    res.json(deliveryPerson);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Mettre à jour un livreur
exports.updateDeliveryPerson = async (req, res) => {
  try {
    const { name, email, phone, isActive } = req.body;
    
    const deliveryPerson = await DeliveryPerson.findById(req.params.id);
    
    if (!deliveryPerson) {
      return res.status(404).json({ message: 'Livreur non trouvé' });
    }
    
    // Vérifier si l'email est déjà utilisé par un autre livreur
    if (email && email !== deliveryPerson.email) {
      const existingDeliveryPerson = await DeliveryPerson.findOne({ email });
      if (existingDeliveryPerson) {
        return res.status(400).json({ message: 'Cet email est déjà utilisé' });
      }
      deliveryPerson.email = email;
    }
    
    // Mettre à jour les champs
    if (name) deliveryPerson.name = name;
    if (phone) deliveryPerson.phone = phone;
    if (isActive !== undefined) deliveryPerson.isActive = isActive;
    
    await deliveryPerson.save();
    
    res.json({
      message: 'Livreur mis à jour avec succès',
      deliveryPerson
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Réinitialiser le mot de passe d'un livreur
exports.resetDeliveryPersonPassword = async (req, res) => {
  try {
    const { password } = req.body;
    
    if (!password || password.length < 6) {
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 6 caractères' });
    }
    
    const deliveryPerson = await DeliveryPerson.findById(req.params.id);
    
    if (!deliveryPerson) {
      return res.status(404).json({ message: 'Livreur non trouvé' });
    }
    
    deliveryPerson.password = password;
    await deliveryPerson.save();
    
    res.json({ message: 'Mot de passe réinitialisé avec succès' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Supprimer un livreur
exports.deleteDeliveryPerson = async (req, res) => {
  try {
    const deliveryPerson = await DeliveryPerson.findById(req.params.id);
    
    if (!deliveryPerson) {
      return res.status(404).json({ message: 'Livreur non trouvé' });
    }
    
    // Vérifier si le livreur a des commandes assignées en cours
    const assignedOrders = await Order.countDocuments({
      deliveryPersonId: deliveryPerson._id,
      statut: { $in: ['En attente', 'Expédiée'] }
    });
    
    if (assignedOrders > 0) {
      return res.status(400).json({ 
        message: 'Ce livreur ne peut pas être supprimé car il a des commandes en cours',
        assignedOrders
      });
    }
    
    // Dissocier le livreur des commandes passées
    await Order.updateMany(
      { deliveryPersonId: deliveryPerson._id },
      { $unset: { deliveryPersonId: 1 } }
    );
    
    await DeliveryPerson.findByIdAndDelete(req.params.id);
    
    res.json({ message: 'Livreur supprimé avec succès' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Obtenir les statistiques des livreurs
exports.getDeliveryStats = async (req, res) => {
  try {
    // Nombre total de livreurs
    const totalDeliveryPersons = await DeliveryPerson.countDocuments();
    
    // Nombre de livreurs actifs
    const activeDeliveryPersons = await DeliveryPerson.countDocuments({ isActive: true });
    
    // Récupérer les 5 meilleurs livreurs (ceux qui ont livré le plus de commandes)
    const topDeliveryPersons = await Order.aggregate([
      { $match: { statut: 'Livrée' } },
      { $group: { 
        _id: '$deliveryPersonId', 
        totalDeliveries: { $sum: 1 },
        totalAmount: { $sum: '$total' }
      }},
      { $sort: { totalDeliveries: -1 } },
      { $limit: 5 },
      { $lookup: {
        from: 'deliverypersons',
        localField: '_id',
        foreignField: '_id',
        as: 'deliveryPerson'
      }},
      { $unwind: '$deliveryPerson' },
      { $project: {
        _id: 1,
        name: '$deliveryPerson.name',
        totalDeliveries: 1,
        totalAmount: 1
      }}
    ]);
    
    res.json({
      totalDeliveryPersons,
      activeDeliveryPersons,
      topDeliveryPersons
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}; 