import 'package:flutter/material.dart';
import '../services/local_review_service.dart';
import '../widgets/star_rating.dart';

class ProductRatingBadge extends StatefulWidget {
  final String productId;
  final double size;
  final bool showCount;
  final MainAxisAlignment alignment;

  const ProductRatingBadge({
    Key? key,
    required this.productId,
    this.size = 16.0,
    this.showCount = true,
    this.alignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  State<ProductRatingBadge> createState() => _ProductRatingBadgeState();
}

class _ProductRatingBadgeState extends State<ProductRatingBadge> {
  final LocalReviewService _reviewService = LocalReviewService();
  double _rating = 0;
  int _reviewCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      final reviews = await _reviewService.getProductReviews(widget.productId);
      final avgRating = await _reviewService.getAverageRating(widget.productId);
      
      if (mounted) {
        setState(() {
          _rating = avgRating;
          _reviewCount = reviews.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 16,
        width: 80,
        child: Center(
          child: LinearProgressIndicator(
            backgroundColor: Colors.amber,
            color: Colors.amberAccent,
            minHeight: 2,
          ),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: widget.alignment,
      children: [
        StarRating(
          rating: _rating,
          size: widget.size,
          showRatingValue: _reviewCount > 0,
        ),
        if (widget.showCount) ...[
          const SizedBox(width: 4),
          Text(
            _reviewCount > 0 ? '($_reviewCount)' : 'Aucun avis',
            style: TextStyle(
              fontSize: widget.size * 0.7,
              color: Colors.grey[600],
              fontStyle: _reviewCount > 0 ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
} 