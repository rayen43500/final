const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { protect, admin } = require('../middleware/auth');
const validateObjectId = require('../middleware/validateObjectId');

// Toutes les routes nécessitent une authentification et des privilèges admin
router.use(protect);
router.use(admin);

// Routes pour gérer les livreurs
router.post('/delivery-persons', adminController.createDeliveryPerson);
router.get('/delivery-persons', adminController.getAllDeliveryPersons);
router.get('/delivery-persons/:id', validateObjectId(), adminController.getDeliveryPerson);
router.put('/delivery-persons/:id', validateObjectId(), adminController.updateDeliveryPerson);
router.put('/delivery-persons/:id/reset-password', validateObjectId(), adminController.resetDeliveryPersonPassword);
router.delete('/delivery-persons/:id', validateObjectId(), adminController.deleteDeliveryPerson);
router.get('/delivery-stats', adminController.getDeliveryStats);

module.exports = router; 