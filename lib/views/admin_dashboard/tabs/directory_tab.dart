import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_service.dart';

class DirectoryTab extends StatefulWidget {
  const DirectoryTab({super.key});

  @override
  State<DirectoryTab> createState() => _DirectoryTabState();
}

class _DirectoryTabState extends State<DirectoryTab> {
  final AdminService _adminService = AdminService();
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _adminService.usersStream(),
      builder: (context, usersSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _adminService.providersStream(),
          builder: (context, providersSnap) {
            if (usersSnap.hasError || providersSnap.hasError) {
              return Center(
                child: Text('Could not load the directory: ${usersSnap.error ?? providersSnap.error}'),
              );
            }
            if (!usersSnap.hasData || !providersSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
            }

            final users = usersSnap.data!;
            final providersByUid = {for (final p in providersSnap.data!) p['uid'] as String: p};

            var entries = users.map((u) => _DirectoryEntry(user: u, provider: providersByUid[u.uid])).toList();

            switch (_filter) {
              case 'Pending Verification':
                entries = entries.where((e) => e.provider?['verificationStatus'] == 'pending').toList();
                break;
              case 'Suspended':
                entries = entries.where((e) => e.isSuspended).toList();
                break;
              default:
                break;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('All'),
                      _filterChip('Pending Verification'),
                      _filterChip('Suspended'),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(child: Text('No accounts match this filter.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: entries.length,
                          itemBuilder: (context, index) => _entryCard(entries[index]),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String label) {
    final isActive = _filter == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : AppColors.brandPrimary)),
      selected: isActive,
      selectedColor: AppColors.brandPrimary,
      backgroundColor: Colors.white,
      onSelected: (_) => setState(() => _filter = label),
    );
  }

  Widget _entryCard(_DirectoryEntry entry) {
    final isProvider = entry.user.role == 'producer';
    final provider = entry.provider;
    final verificationStatus = provider?['verificationStatus'] as String?;
    final isSuspended = entry.isSuspended;

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
              CircleAvatar(
                radius: 20,
                backgroundColor: isProvider ? AppColors.brandSecondary.withValues(alpha: 0.1) : AppColors.brandPrimary.withValues(alpha: 0.15),
                child: Icon(isProvider ? Icons.engineering_outlined : Icons.person_outline,
                    size: 20, color: isProvider ? AppColors.brandSecondary : AppColors.brandPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.user.fullName.isEmpty ? entry.user.email : entry.user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brandPrimary)),
                    Text('${isProvider ? 'Provider' : 'Consumer'} • ${entry.user.district}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (isSuspended)
                _badge('Suspended', Colors.red)
              else if (verificationStatus == 'pending')
                _badge('Pending', Colors.orange)
              else if (verificationStatus == 'approved')
                _badge('Verified', Colors.green)
              else
                _badge('Active', Colors.blueGrey),
            ],
          ),
          if (isProvider && provider != null) ...[
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Icon(Icons.work_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(provider['businessCategory'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(width: 16),
                const Icon(Icons.star_outline, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${provider['rating'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isProvider && verificationStatus == 'pending') ...[
                TextButton(
                  onPressed: () => _rejectVerification(entry.user.uid),
                  child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandSecondary, foregroundColor: Colors.white),
                  onPressed: () => _approveVerification(entry.user.uid),
                  child: const Text('Approve'),
                ),
              ] else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSuspended ? Colors.green : Colors.redAccent,
                    side: BorderSide(color: isSuspended ? Colors.green : Colors.redAccent),
                  ),
                  onPressed: () => isSuspended
                      ? _reinstate(entry.user.uid, isProvider ? 'provider' : 'user')
                      : _suspend(entry.user.uid, isProvider ? 'provider' : 'user'),
                  child: Text(isSuspended ? 'Lift Suspension' : 'Suspend'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Future<void> _approveVerification(String uid) async {
    try {
      await _adminService.approveVerification(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider approved and live.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _rejectVerification(String uid) async {
    final reason = await _promptReason(title: 'Reject verification', hint: 'Why is this provider being rejected?');
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await _adminService.rejectVerification(uid, reason.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification rejected.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _suspend(String uid, String targetType) async {
    final reason = await _promptReason(title: 'Suspend account', hint: 'Reason (fake bookings, payment circumvention, spamming, other)...');
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await _adminService.suspendAccount(uid: uid, targetType: targetType, reason: reason.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account suspended.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _reinstate(String uid, String targetType) async {
    try {
      await _adminService.reinstateAccount(uid: uid, targetType: targetType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account reinstated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<String?> _promptReason({required String title, required String hint}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
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
  }
}

class _DirectoryEntry {
  final UserModel user;
  final Map<String, dynamic>? provider;
  _DirectoryEntry({required this.user, this.provider});

  /// Providers' suspension status lives on their `providers/{uid}` doc
  /// (alongside `available`); plain consumers' lives on their `users/{uid}`
  /// doc. Check whichever is authoritative for this entry.
  bool get isSuspended => user.role == 'producer'
      ? (provider?['accountStatus'] as String?) == 'suspended'
      : user.accountStatus == 'suspended';
}
