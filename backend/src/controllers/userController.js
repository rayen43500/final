const User = require('../models/User');

// Obtenir le profil de l'utilisateur connecté
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-motDePasse');
    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Obtenir le nombre total d'utilisateurs (Admin seulement)
exports.getUserCount = async (req, res) => {
  try {
    const count = await User.countDocuments();
    res.json({ count });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Mettre à jour le profil
exports.updateProfile = async (req, res) => {
  try {
    const { nom, email, telephone } = req.body;
    
    // Vérifier si l'email est déjà utilisé par un autre utilisateur
    if (email && email !== req.user.email) {
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ message: 'Cet email est déjà utilisé' });
      }
    }

    const user = await User.findById(req.user.id);
    if (nom) user.nom = nom;
    if (email) user.email = email;
    if (telephone) user.telephone = telephone;

    await user.save();

    res.json({
      id: user._id,
      nom: user.nom,
      email: user.email,
      telephone: user.telephone,
      role: user.role,
      isVerified: user.isVerified
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Obtenir la liste des utilisateurs (Admin seulement)
exports.getUsers = async (req, res) => {
  try {
    const users = await User.find().select('-motDePasse');
    res.json(users);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Désactiver un utilisateur (Admin seulement)
exports.disableUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    // Empêcher la désactivation d'un admin par un autre admin
    if (user.role === 'Admin' && req.user.id !== user._id.toString()) {
      return res.status(403).json({ message: 'Vous ne pouvez pas désactiver un autre administrateur' });
    }

    user.isActive = false;
    await user.save();

    res.json({ message: 'Utilisateur désactivé avec succès' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Activer un utilisateur (Admin seulement)
exports.enableUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    user.isActive = true;
    await user.save();

    res.json({ message: 'Utilisateur activé avec succès' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
}; 