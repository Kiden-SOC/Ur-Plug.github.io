import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/provider_profile.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/job_request_card.dart';
import '../../widgets/shared_widgets.dart';

/// Jobs a customer has requested that the provider hasn't responded to yet.
class PendingJobsScreen extends StatelessWidget {
  const PendingJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final pending = controller.jobRequests
        .where((j) => j.status == JobStatus.pending)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Pending Jobs',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: pending.isEmpty
          ? const EmptyState(
              icon: Icons.pending_actions_outlined,
              title: 'No pending jobs',
              subtitle:
                  'New job requests from customers will land here for you to accept or decline.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children:
                  pending.map((job) => JobRequestCard(job: job)).toList(),
            ),
    );
  }
}