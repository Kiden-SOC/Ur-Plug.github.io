import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 20,
    this.onChanged,
  });

  bool get isInteractive => onChanged != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        final star = Icon(
          filled ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
        if (!isInteractive) return star;
        return InkWell(
          borderRadius: BorderRadius.circular(size),
          onTap: () => onChanged!(i + 1),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: star,
          ),
        );
      }),
    );
  }
}
