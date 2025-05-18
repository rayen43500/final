const mongoose = require('mongoose');

const testStatisticSchema = new mongoose.Schema({
  testName: {
    type: String,
    required: [true, 'Nom du test requis'],
    trim: true
  },
  testType: {
    type: String,
    required: [true, 'Type de test requis'],
    enum: ['Performance', 'Fonctionnel', 'Intégration', 'Unitaire', 'Autre'],
    default: 'Fonctionnel'
  },
  executionDate: {
    type: Date,
    default: Date.now
  },
  duration: {
    type: Number,  // en milliseconds
    required: [true, 'Durée du test requise']
  },
  success: {
    type: Boolean,
    required: [true, 'Statut de réussite requis']
  },
  errorCount: {
    type: Number,
    default: 0
  },
  warningCount: {
    type: Number,
    default: 0
  },
  module: {
    type: String,
    required: [true, 'Module testé requis']
  },
  environment: {
    type: String,
    enum: ['Développement', 'Test', 'Staging', 'Production'],
    default: 'Développement'
  },
  executedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  details: {
    type: Object,
    default: {}
  },
  notes: {
    type: String
  }
}, {
  timestamps: true
});

// Indexation pour des requêtes plus rapides
testStatisticSchema.index({ testName: 1, executionDate: -1 });
testStatisticSchema.index({ module: 1 });
testStatisticSchema.index({ success: 1 });
testStatisticSchema.index({ executionDate: -1 });

// Méthodes statistiques
testStatisticSchema.statics.getAverageExecutionTime = async function(testName) {
  const stats = await this.aggregate([
    { $match: { testName: testName } },
    { $group: { _id: null, avgDuration: { $avg: "$duration" } } }
  ]);
  
  return stats.length > 0 ? stats[0].avgDuration : 0;
};

testStatisticSchema.statics.getSuccessRate = async function(testName) {
  const stats = await this.aggregate([
    { $match: { testName: testName } },
    { $group: { 
      _id: null, 
      totalTests: { $sum: 1 },
      successfulTests: { $sum: { $cond: [{ $eq: ["$success", true] }, 1, 0] } }
    } }
  ]);
  
  if (stats.length === 0) return 0;
  return (stats[0].successfulTests / stats[0].totalTests) * 100;
};

const TestStatistic = mongoose.model('TestStatistic', testStatisticSchema);

module.exports = TestStatistic; 