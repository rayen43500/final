import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/review.dart';

class LocalReviewService {
  static const String _storageKey = 'product_reviews';
  final Uuid _uuid = const Uuid();

  // Récupérer tous les avis stockés
  Future<List<Review>> getAllReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reviewsJson = prefs.getString(_storageKey);
    
    if (reviewsJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> decodedJson = json.decode(reviewsJson);
      return decodedJson.map((item) => Review.fromJson(item)).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des avis: $e');
      return [];
    }
  }
  
  // Récupérer les avis d'un produit spécifique
  Future<List<Review>> getProductReviews(String productId) async {
    final allReviews = await getAllReviews();
    return allReviews.where((review) => review.productId == productId).toList();
  }
  
  // Calculer la note moyenne d'un produit
  Future<double> getAverageRating(String productId) async {
    final reviews = await getProductReviews(productId);
    
    if (reviews.isEmpty) {
      return 0.0;
    }
    
    double totalRating = 0;
    for (var review in reviews) {
      totalRating += review.rating;
    }
    
    return totalRating / reviews.length;
  }
  
  // Ajouter un nouvel avis
  Future<Review> addReview({
    required String productId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final allReviews = await getAllReviews();
    
    final newReview = Review(
      id: _uuid.v4(),
      productId: productId,
      userName: userName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    
    allReviews.add(newReview);
    await _saveReviews(allReviews);
    
    return newReview;
  }
  
  // Sauvegarder les avis dans le stockage local
  Future<void> _saveReviews(List<Review> reviews) async {
    final prefs = await SharedPreferences.getInstance();
    final reviewsJson = json.encode(reviews.map((review) => review.toJson()).toList());
    await prefs.setString(_storageKey, reviewsJson);
  }
  
  // Données initiales pour avoir quelques avis par défaut
  Future<void> initializeWithMockData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_storageKey) == null) {
      final List<Review> mockReviews = [
        Review(
          id: '1',
          productId: 'test1',
          userName: 'Jean Dupont',
          rating: 4.5,
          comment: 'Très bon produit, je recommande !',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Review(
          id: '2',
          productId: 'test1',
          userName: 'Marie Martin',
          rating: 5.0,
          comment: 'Excellent rapport qualité-prix',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        Review(
          id: '3',
          productId: 'test2',
          userName: 'Pierre Durand',
          rating: 3.5,
          comment: 'Bon produit mais livraison lente',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
      
      await _saveReviews(mockReviews);
    }
  }
} 