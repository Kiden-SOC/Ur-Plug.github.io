import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/job_request_card.dart';
import '../../widgets/shared_widgets.dart';

/// Full log of every job the provider has acted on — confirmed, declined
/// or completed — so they always have a record of their work.
class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final history = controller.jobHistory;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Job History',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: history.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No history yet',
              subtitle:
                  'Jobs you\u2019ve confirmed, declined or completed will be logged here.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children:
                  history.map((job) => JobRequestCard(job: job)).toList(),
            ),
    );
  }
}