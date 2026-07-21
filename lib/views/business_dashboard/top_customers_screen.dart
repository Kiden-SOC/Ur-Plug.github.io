import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/shared_widgets.dart';

/// Recognises the provider's most loyal customers — the ones who keep
/// coming back — ranked by how many jobs they've booked.
class TopCustomersScreen extends StatelessWidget {
  const TopCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final customers = [...controller.topCustomers]
      ..sort((a, b) => b.jobsCompleted.compareTo(a.jobsCompleted));

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Top Customers',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: customers.isEmpty
          ? const EmptyState(
              icon: Icons.workspace_premium_outlined,
              title: 'No repeat customers yet',
              subtitle:
                  'Customers who book you again and again will be ranked here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = customers[index];
                final bool isTopRanked = index == 0;
                return UrPlugCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppColors.brandPrimary.withValues(alpha:0.1),
                            child: const Icon(Icons.person,
                                color: AppColors.brandPrimary),
                          ),
                          if (isTopRanked)
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentRedOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.workspace_premium,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer.customerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.brandPrimary)),
                            const SizedBox(height: 3),
                            Text(
                              '${customer.jobsCompleted} job${customer.jobsCompleted == 1 ? '' : 's'} \u2022 last booked ${customer.lastServiceDate}',
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isTopRanked)
                            const StatusPill(
                              label: 'Most Loyal',
                              color: AppColors.accentRedOrange,
                              icon: Icons.star,
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 13, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                customer.averageRatingGiven
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}