import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/admin_service.dart';

/// Reviews tab: providers first, reviews second.
///
/// Providers are grouped into "New reviews" (has at least one review the
/// admin hasn't seen yet) and "Reviewed" (everything's been viewed).
/// Tapping a provider opens their review list and marks them read — but
/// they stay listed under "Reviewed" afterwards rather than disappearing,
/// so past reviews are always still reachable.
class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: adminService.reviewsByProviderStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load reviews: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
        }
        final providers = snapshot.data!;
        if (providers.isEmpty) {
          return const Center(child: Text('No reviews yet.', style: TextStyle(color: Colors.grey)));
        }

        final unread = providers.where((p) => p['isUnread'] == true).toList();
        final read = providers.where((p) => p['isUnread'] != true).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (unread.isNotEmpty) ...[
              _sectionHeader('New reviews', unread.length, Icons.mark_email_unread_outlined, AppColors.accentRedOrange),
              ...unread.map((p) => _ProviderRow(provider: p, adminService: adminService)),
              const SizedBox(height: 20),
            ],
            _sectionHeader('Reviewed', read.length, Icons.mark_email_read_outlined, AppColors.textMuted),
            if (read.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nothing here yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ...read.map((p) => _ProviderRow(provider: p, adminService: adminService)),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$title ($count)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final Map<String, dynamic> provider;
  final AdminService adminService;

  const _ProviderRow({required this.provider, required this.adminService});

  @override
  Widget build(BuildContext context) {
    final bool isUnread = provider['isUnread'] == true;
    final DateTime latestAt = provider['latestReviewAt'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isUnread ? Border.all(color: AppColors.accentRedOrange.withValues(alpha: 0.35)) : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
          child: const Icon(Icons.storefront, color: AppColors.brandPrimary, size: 18),
        ),
        title: Text(
          provider['providerName'] as String,
          style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${provider['reviewCount']} review${provider['reviewCount'] == 1 ? '' : 's'} · last ${_relativeDate(latestAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isUnread
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentRedOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () async {
          await adminService.markProviderReviewsRead(provider['providerId'] as String);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderReviewsScreen(
                providerId: provider['providerId'] as String,
                providerName: provider['providerName'] as String,
              ),
            ),
          );
        },
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}

/// A single provider's review list — reachable at any time from either the
/// "New reviews" or "Reviewed" section, so nothing is ever locked away
/// once it's been seen.
class ProviderReviewsScreen extends StatelessWidget {
  final String providerId;
  final String providerName;

  const ProviderReviewsScreen({super.key, required this.providerId, required this.providerName});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: Text(providerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: adminService.providerReviewsStream(providerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load reviews: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
          }
          final reviews = snapshot.data!;
          if (reviews.isEmpty) {
            return const Center(child: Text('No reviews for this provider.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) => _reviewCard(context, adminService, reviews[index]),
          );
        },
      ),
    );
  }

  Widget _reviewCard(BuildContext context, AdminService adminService, Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final customerName = review['customerName'] as String? ?? 'Anonymous';
    final createdAt = review['createdAt'] is Timestamp ? (review['createdAt'] as Timestamp).toDate() : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.brandPrimary)),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(i < rating ? Icons.star : Icons.star_border, size: 14, color: Colors.amber),
                ),
              ),
            ],
          ),
          if (createdAt != null)
            Text(
              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmDelete(context, adminService, review),
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              label: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AdminService adminService, Map<String, dynamic> review) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently removes the review from the provider\'s page. This cannot be undone directly, though the affected user can file an appeal.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (spam, harassment, fake, off-topic, contains PII, other)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (reason == null || reason.trim().isEmpty || !context.mounted) return;

    try {
      await adminService.deleteReview(
        providerId: review['providerId'] as String,
        reviewId: review['id'] as String,
        reason: reason.trim(),
        reviewSnapshot: {
          'rating': review['rating'],
          'comment': review['comment'],
          'customerName': review['customerName'],
        },
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review removed.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
