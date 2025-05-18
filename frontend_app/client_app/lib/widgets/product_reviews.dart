import 'package:flutter/material.dart';
import '../services/local_review_service.dart';
import '../widgets/star_rating.dart';
import '../models/review.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart' as theme;

class ProductReviews extends StatefulWidget {
  final String productId;
  final bool showAddReview;

  const ProductReviews({
    Key? key,
    required this.productId,
    this.showAddReview = true,
  }) : super(key: key);

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  final LocalReviewService _reviewService = LocalReviewService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0;
  bool _showAddReviewForm = false;
  
  // Pour le formulaire d'ajout d'avis
  final _commentController = TextEditingController();
  final _nameController = TextEditingController();
  double _newRating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadReviews();
  }
  
  Future<void> _initializeAndLoadReviews() async {
    // Initialiser les données de test si nécessaire
    await _reviewService.initializeWithMockData();
    await _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reviews = await _reviewService.getProductReviews(widget.productId);
      final avgRating = await _reviewService.getAverageRating(widget.productId);
      
      setState(() {
        _reviews = reviews;
        _averageRating = avgRating;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des avis: $e')),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_newRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez attribuer une note')),
      );
      return;
    }
    
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre nom')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reviewService.addReview(
        productId: widget.productId,
        userName: _nameController.text,
        rating: _newRating,
        comment: _commentController.text,
      );
      
      // Réinitialiser le formulaire
      _commentController.clear();
      _nameController.clear();
      setState(() {
        _newRating = 0;
        _showAddReviewForm = false;
      });
      
      // Recharger les avis
      await _loadReviews();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci ! Votre avis a été ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de l\'avis: $e')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé des avis avec note moyenne
        _buildReviewSummary(),
        
        const SizedBox(height: 16),
        
        // Bouton pour ajouter un avis
        if (widget.showAddReview && !_showAddReviewForm)
          _buildAddReviewButton(),
          
        // Formulaire d'ajout d'avis
        if (widget.showAddReview && _showAddReviewForm)
          _buildAddReviewForm(),
          
        const SizedBox(height: 24),
        
        // Liste des avis
        _buildReviewsList(),
      ],
    );
  }
  
  Widget _buildReviewSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Text(
            'Avis clients (${_reviews.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRating(
                    rating: _averageRating,
                    size: 30,
                    color: Colors.amber,
                    showRatingValue: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Basé sur ${_reviews.length} avis',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Votre avis compte pour nous et pour les autres utilisateurs !',
            style: TextStyle(
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddReviewButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _showAddReviewForm = true;
          });
        },
        icon: const Icon(Icons.star, color: Colors.white),
        label: const Text('Donnez votre avis sur ce produit'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: Colors.amber.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAddReviewForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.AppTheme.accentColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Partagez votre expérience',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showAddReviewForm = false;
                  });
                },
              ),
            ],
          ),
          
          const Divider(),
          const SizedBox(height: 16),
          
          // Champ du nom
          const Text(
            'Votre nom:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Entrez votre nom',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Votre note:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Sélection des étoiles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _newRating = index + 1.0;
                  });
                },
                // Permettre de sélectionner en glissant le doigt
                onHorizontalDragUpdate: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.globalPosition);
                  final starWidth = box.size.width / 5;
                  final starIndex = (localPosition.dx / starWidth).floor();
                  
                  if (starIndex >= 0 && starIndex < 5) {
                    setState(() {
                      _newRating = starIndex + 1.0;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    index < _newRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _newRating > 0 
              ? 'Votre note: ${_newRating.toStringAsFixed(0)}/5' 
              : 'Sélectionnez une note',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Votre commentaire:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Champ de commentaire
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Partagez votre expérience avec ce produit...',
              prefixIcon: const Icon(Icons.comment),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            maxLines: 4,
          ),
          
          const SizedBox(height: 24),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showAddReviewForm = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: theme.AppTheme.accentColor,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Publier'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun avis pour ce produit',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Soyez le premier à donner votre avis !',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avis des clients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final review = _reviews[index];
            final formattedDate = DateFormat('dd/MM/yyyy').format(review.createdAt);
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.AppTheme.primaryColor,
                        child: Text(
                          (review.userName)[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StarRating(
                        rating: review.rating,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      review.comment,
                      style: const TextStyle(height: 1.3),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
} 