import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/job_request_card.dart';
import '../../widgets/shared_widgets.dart';

/// Jobs the provider has accepted and is currently working on.
class UnfinishedJobsScreen extends StatelessWidget {
  const UnfinishedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final ongoing = controller.ongoingJobs;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Unfinished Jobs',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ongoing.isEmpty
          ? const EmptyState(
              icon: Icons.build_outlined,
              title: 'Nothing in progress',
              subtitle:
                  'Jobs you\u2019ve accepted and are currently working on will appear here until you mark them done.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children:
                  ongoing.map((job) => JobRequestCard(job: job)).toList(),
            ),
    );
  }
}