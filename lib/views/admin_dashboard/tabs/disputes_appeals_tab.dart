import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/dispute.dart';
import '../../../models/appeal.dart';
import '../../../services/admin_service.dart';

class DisputesAppealsTab extends StatefulWidget {
  const DisputesAppealsTab({super.key});

  @override
  State<DisputesAppealsTab> createState() => _DisputesAppealsTabState();
}

class _DisputesAppealsTabState extends State<DisputesAppealsTab> {
  final AdminService _adminService = AdminService();
  bool _showingDisputes = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _segment('Disputes', _showingDisputes, () => setState(() => _showingDisputes = true))),
              const SizedBox(width: 8),
              Expanded(child: _segment('Appeals', !_showingDisputes, () => setState(() => _showingDisputes = false))),
            ],
          ),
        ),
        Expanded(child: _showingDisputes ? _buildDisputes() : _buildAppeals()),
      ],
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPrimary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: active ? null : Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // DISPUTES
  // ---------------------------------------------------------------

  Widget _buildDisputes() {
    return StreamBuilder<List<Dispute>>(
      stream: _adminService.disputesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Could not load disputes: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
        final disputes = snapshot.data!;
        if (disputes.isEmpty) return const Center(child: Text('No disputes filed.', style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: disputes.length,
          itemBuilder: (context, index) => _disputeCard(disputes[index]),
        );
      },
    );
  }

  Widget _disputeCard(Dispute dispute) {
    final isOpen = dispute.status == DisputeStatus.open || dispute.status == DisputeStatus.underReview;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${dispute.raisedByName} vs ${dispute.respondentName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.brandPrimary)),
              ),
              _statusBadge(dispute.status.name),
            ],
          ),
          const SizedBox(height: 4),
          Text('Category: ${dispute.category} • Job ${dispute.jobId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(dispute.description, style: const TextStyle(fontSize: 13)),
          if (dispute.resolutionNotes != null) ...[
            const SizedBox(height: 8),
            Text('Resolution: ${dispute.resolutionNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          if (isOpen) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (dispute.status == DisputeStatus.open)
                  TextButton(
                    onPressed: () => _adminService.markDisputeUnderReview(dispute.id),
                    child: const Text('Start review'),
                  ),
                TextButton(
                  onPressed: () => _resolveDispute(dispute, asResolved: false),
                  child: const Text('Dismiss', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandSecondary, foregroundColor: Colors.white),
                  onPressed: () => _resolveDispute(dispute, asResolved: true),
                  child: const Text('Resolve'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolveDispute(Dispute dispute, {required bool asResolved}) async {
    final controller = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(asResolved ? 'Resolve dispute' : 'Dismiss dispute'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Resolution notes...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (notes == null || notes.trim().isEmpty || !mounted) return;
    try {
      await _adminService.resolveDispute(disputeId: dispute.id, asResolved: asResolved, resolutionNotes: notes.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ---------------------------------------------------------------
  // APPEALS
  // ---------------------------------------------------------------

  Widget _buildAppeals() {
    return StreamBuilder<List<Appeal>>(
      stream: _adminService.appealsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Could not load appeals: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
        final appeals = snapshot.data!;
        if (appeals.isEmpty) return const Center(child: Text('No appeals filed.', style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: appeals.length,
          itemBuilder: (context, index) => _appealCard(appeals[index]),
        );
      },
    );
  }

  Widget _appealCard(Appeal appeal) {
    final isPending = appeal.status == AppealStatus.pending;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(appeal.submittedByName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.brandPrimary)),
              ),
              _statusBadge(appeal.status.name),
            ],
          ),
          const SizedBox(height: 4),
          Text('Appealing: ${appeal.targetType.replaceAll('_', ' ')}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(appeal.userStatement, style: const TextStyle(fontSize: 13)),
          if (appeal.reviewNotes != null) ...[
            const SizedBox(height: 8),
            Text('Review notes: ${appeal.reviewNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _resolveAppeal(appeal, uphold: true),
                  child: const Text('Uphold original action'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandSecondary, foregroundColor: Colors.white),
                  onPressed: () => _resolveAppeal(appeal, uphold: false),
                  child: const Text('Overturn'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolveAppeal(Appeal appeal, {required bool uphold}) async {
    final controller = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(uphold ? 'Uphold original action' : 'Overturn — reinstate account'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Notes for this decision...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (notes == null || notes.trim().isEmpty || !mounted) return;
    try {
      await _adminService.resolveAppeal(appeal: appeal, uphold: uphold, reviewNotes: notes.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appeal resolved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'resolved' || status == 'upheld') color = Colors.green;
    if (status == 'dismissed' || status == 'overturned') color = Colors.blueGrey;
    if (status == 'underReview') color = Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
