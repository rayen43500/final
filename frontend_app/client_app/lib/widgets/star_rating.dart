import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final bool showRatingValue;
  final MainAxisAlignment alignment;

  const StarRating({
    Key? key,
    required this.rating,
    this.size = 20.0,
    this.color = Colors.amber,
    this.showRatingValue = false,
    this.alignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            if (index < rating.floor()) {
              // Étoile complète
              return Icon(
                Icons.star,
                color: color,
                size: size,
              );
            } else if (index == rating.floor() && rating % 1 > 0) {
              // Demi-étoile
              return Icon(
                Icons.star_half,
                color: color,
                size: size,
              );
            } else {
              // Étoile vide
              return Icon(
                Icons.star_border,
                color: color,
                size: size,
              );
            }
          }),
        ),
        if (showRatingValue) ...[
          const SizedBox(width: 5),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }
} 