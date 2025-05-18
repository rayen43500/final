const mongoose = require('mongoose');

const validateObjectId = (paramName = 'id') => {
  return (req, res, next) => {
    const id = req.params[paramName];
    
    if (!id || !mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid ID format'
      });
    }
    
    next();
  };
};

module.exports = validateObjectId; 