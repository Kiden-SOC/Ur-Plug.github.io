import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/shared_widgets.dart';

/// Public ratings, reviews and comments customers have left.
class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Ratings & Reviews',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: controller.ratings.isEmpty
          ? const EmptyState(
              icon: Icons.star_outline,
              title: 'No ratings yet',
              subtitle:
                  'Complete jobs and customers will leave verified reviews here.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                UrPlugCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(controller.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brandPrimary)),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < controller.averageRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                          height: 50,
                          width: 1,
                          color: AppColors.brandPrimary.withValues(alpha:0.1)),
                      Column(
                        children: [
                          Text('${controller.ratings.length}',
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brandPrimary)),
                          const Text('Verified Reviews',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...controller.ratings.map((rating) => UrPlugCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppColors.brandPrimary.withValues(alpha:0.1),
                                child: const Icon(Icons.person_outline,
                                    size: 16, color: AppColors.brandPrimary),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rating.customerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brandPrimary,
                                          fontSize: 13)),
                                  Text(rating.date,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(rating.stars.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(rating.comment,
                              style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 12.5,
                                  height: 1.4)),
                        ],
                      ),
                    )),
              ],
            ),
    );
  }
}