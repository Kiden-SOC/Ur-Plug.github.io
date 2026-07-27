import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_request.dart';
import '../core/theme/app_colors.dart';
import '../models/provider_profile.dart';
import '../state/provider_profile_controller.dart';
import '../views/business_dashboard/provider_chat_screen.dart';
import 'shared_widgets.dart';

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


class JobRequestCard extends StatelessWidget {
  final JobRequest job;
  const JobRequestCard({super.key, required this.job});

  String get _locationText {
    if (job.landmark.isNotEmpty && job.district.isNotEmpty) {
      return '${job.landmark}, ${job.district}';
    }
    if (job.district.isNotEmpty) return job.district;
    return job.landmark;
  }

  String get _dateTimeText {
    if (job.date.isNotEmpty && job.time.isNotEmpty) {
      return '${job.date} • ${job.time}';
    }
    if (job.date.isNotEmpty) return job.date;
    return job.time;
  }

  String get _startText {
    if (job.startDate.isEmpty) return '';
    if (job.time.isNotEmpty) return '${job.startDate} • ${job.time}';
    return job.startDate;
  }

  String get _endText => job.endDate;

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.brandSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.3)),
          ),
        ],
      ),
    );
  }

  Future<void> _callCustomer(BuildContext context) async {
    String phoneNumber = job.customerPhone;

    if (phoneNumber.isEmpty && job.customerUid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(job.customerUid)
            .get();
        phoneNumber = (userDoc.data()?['contact'] ?? '').toString();
      } catch (_) {
        // Ignore — handled by the empty check below.
      }
    }

    if (phoneNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer phone number not available.')),
        );
      }
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the phone dialer.')),
      );
    }
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderChatScreen(
            customerUid: job.customerUid, customerName: job.customerName),
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contact ${job.customerName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.brandPrimary),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.brandPrimary),
                  ),
                  title: const Text('Send a Message',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Chat inside the app'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openChat(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandSecondary.withValues(alpha: 0.1),
                    child: const Icon(Icons.call_outlined,
                        color: AppColors.brandSecondary),
                  ),
                  title: const Text('Call Customer',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Place a direct phone call'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _callCustomer(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
          if (job.serviceNeeded.isNotEmpty)
            Text(job.serviceNeeded,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.brandPrimary)),
          if (job.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(job.description,
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.textDark, height: 1.4)),
          ],
          const SizedBox(height: 10),
          if (_startText.isNotEmpty)
            _detailRow(Icons.event_available, 'Start: $_startText')
          else if (_dateTimeText.isNotEmpty)
            _detailRow(Icons.schedule, _dateTimeText),
          if (_endText.isNotEmpty)
            _detailRow(Icons.event_busy, 'End: $_endText'),
          if (_locationText.isNotEmpty)
            _detailRow(Icons.near_me, _locationText),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showContactOptions(context),
              icon: const Icon(Icons.contact_phone_outlined, size: 16),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandPrimary,
                side: const BorderSide(color: AppColors.brandPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              label: const Text('Contact',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          if (job.status == JobStatus.pending) ...[
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
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
        ],
      ),
    );
  }
}
