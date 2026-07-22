import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/provider_profile.dart';
import '../state/provider_profile_controller.dart';
import '../views/business_dashboard/provider_chat_screen.dart';
import 'shared_widgets.dart';

/// Status pill matching a [JobStatus].
StatusPill jobStatusPill(JobStatus status) {
  switch (status) {
    case JobStatus.pending:
      return const StatusPill(
          label: 'Pending', color: AppColors.warning, icon: Icons.schedule);
    case JobStatus.accepted:
      return const StatusPill(
          label: 'Ongoing', color: AppColors.brandSecondary, icon: Icons.build);
    case JobStatus.declined:
      return StatusPill(
          label: 'Declined', color: Colors.red.shade700, icon: Icons.cancel);
    case JobStatus.completed:
      return const StatusPill(
          label: 'Completed', color: AppColors.success, icon: Icons.task_alt);
  }
}

/// Card representation of a single job request, with contextual actions
/// depending on its current status:
///  • pending    → Accept / Decline
///  • accepted   → Message Customer / Mark as Completed
///  • completed / declined → read-only history entry
class JobRequestCard extends StatelessWidget {
  final JobRequest job;
  const JobRequestCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ProviderProfileController>();

    return UrPlugCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                child: const Icon(Icons.person_outline,
                    size: 18, color: AppColors.brandPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.brandPrimary)),
                    Text(job.id,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              jobStatusPill(job.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(job.serviceNeeded,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textDark, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.near_me, size: 14, color: AppColors.brandSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(job.locationHint,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.brandSecondary),
              const SizedBox(width: 4),
              Text(job.requestedTime,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          if (job.status == JobStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        controller.setJobStatus(job.id, JobStatus.declined),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Decline',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        controller.setJobStatus(job.id, JobStatus.accepted),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Accept Job',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
          if (job.status == JobStatus.accepted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProviderChatScreen(customerUid: job.customerUid, customerName: job.customerName),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text('Message',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        controller.setJobStatus(job.id, JobStatus.completed),
                    icon: const Icon(Icons.task_alt, size: 16),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    label: const Text('Mark Done',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}