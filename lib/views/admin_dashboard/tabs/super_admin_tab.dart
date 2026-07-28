import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';

/// Super Admin–only tab. Visible only when the signed-in user has
/// role == 'super_admin'. Allows:
///   • Viewing and searching all current admins
///   • Promoting a regular user to admin (subject to quota)
///   • Suspending / reinstating an admin
///   • Demoting an admin back to consumer
///   • Adjusting the max-admin quota
class SuperAdminTab extends StatefulWidget {
  const SuperAdminTab({super.key});

  @override
  State<SuperAdminTab> createState() => _SuperAdminTabState();
}

class _SuperAdminTabState extends State<SuperAdminTab> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();

  final _promoteEmailController = TextEditingController();
  late Future<int> _quotaFuture;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _quotaFuture = _adminService.getAdminQuota();
  }

  void _refreshQuota() => setState(() {
        _quotaFuture = _adminService.getAdminQuota();
      });

  @override
  void dispose() {
    _promoteEmailController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildQuotaCard(),
        const SizedBox(height: 24),
        _buildPromoteCard(),
        const SizedBox(height: 24),
        const Text(
          'Current Admins',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildAdminList(),
      ],
    );
  }

  // ---------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.brandSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Super Admin Console',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Manage admin accounts, control access quota, and monitor admin activity. '
            'These controls are not visible to regular admins.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaCard() {
    return FutureBuilder<int>(
      future: _quotaFuture,
      builder: (context, snapshot) {
        final quota = snapshot.data ?? 5;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Quota',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Maximum number of admin accounts allowed on the platform.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _quotaButton(Icons.remove, () {
                    if (quota > 1) _updateQuota(quota - 1);
                  }),
                  const SizedBox(width: 16),
                  Text(
                    '$quota',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _quotaButton(Icons.add, () => _updateQuota(quota + 1)),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Set manually'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                    ),
                    onPressed: () => _showSetQuotaDialog(quota),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quotaButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.brandPrimary),
      ),
    );
  }

  Widget _buildPromoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promote User to Admin',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the email address of an existing user to grant them admin access.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promoteEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'User email address',
              prefixIcon: Icon(Icons.person_search_outlined, color: AppColors.brandPrimary),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFE0F2F1),
              labelStyle: TextStyle(color: AppColors.brandPrimary),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upgrade_outlined),
              label: const Text('Promote to Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _promoteByEmail,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.adminsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load admins: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brandPrimary),
          );
        }
        final admins = snapshot.data!;
        if (admins.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No admins yet. Promote a user above to get started.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return Column(
          children: admins.map((admin) => _adminCard(admin)).toList(),
        );
      },
    );
  }

  Widget _adminCard(Map<String, dynamic> admin) {
    final uid = admin['uid'] as String? ?? '';
    final name = admin['fullName'] as String? ?? '';
    final email = admin['email'] as String? ?? '';
    final district = admin['district'] as String? ?? '';
    final status = admin['accountStatus'] as String? ?? 'active';
    final isSuspended = status == 'suspended';
    final isSelf = uid == _currentUid; // shouldn't happen (super_admin), but guard anyway

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSuspended
            ? Border.all(color: Colors.red.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.manage_accounts_outlined,
                  size: 20,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? email : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    Text(
                      '$email${district.isNotEmpty ? ' • $district' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              _statusBadge(isSuspended ? 'Suspended' : 'Active', isSuspended ? Colors.red : Colors.green),
            ],
          ),
          if (isSuspended && admin['suspensionReason'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${admin['suspensionReason']}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Suspend / Reinstate button
              if (!isSelf)
                OutlinedButton.icon(
                  icon: Icon(
                    isSuspended ? Icons.lock_open_outlined : Icons.block_outlined,
                    size: 16,
                  ),
                  label: Text(isSuspended ? 'Reinstate' : 'Suspend'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSuspended ? Colors.green : Colors.orange,
                    side: BorderSide(color: isSuspended ? Colors.green : Colors.orange),
                  ),
                  onPressed: () => isSuspended ? _reinstateAdmin(uid) : _suspendAdmin(uid),
                ),
              const SizedBox(width: 8),
              // Demote button
              if (!isSelf)
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_downward_outlined, size: 16),
                  label: const Text('Demote'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () => _demoteAdmin(uid, name.isEmpty ? email : name),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // ---------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------

  Future<void> _updateQuota(int newMax) async {
    try {
      await _adminService.setAdminQuota(newMax);
      _refreshQuota();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin quota updated to $newMax.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showSetQuotaDialog(int currentQuota) async {
    final controller = TextEditingController(text: '$currentQuota');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set admin quota'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Max number of admins',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) await _updateQuota(result);
  }

  Future<void> _promoteByEmail() async {
    final email = _promoteEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a user email address.')),
      );
      return;
    }

    // Look up the user by email
    try {
      final snap = await _authService.getUserByEmail(email);
      if (snap == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with that email address.')),
        );
        return;
      }

      await _adminService.promoteToAdmin(snap.uid);
      _promoteEmailController.clear();
      _refreshQuota();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${snap.fullName.isEmpty ? email : snap.fullName} is now an admin.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _suspendAdmin(String uid) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend admin'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for suspension...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    try {
      await _adminService.suspendAdmin(
        uid: uid,
        reason: reason.trim(),
        currentSuperAdminUid: _currentUid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin suspended.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _reinstateAdmin(String uid) async {
    try {
      await _adminService.reinstateAdmin(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin reinstated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _demoteAdmin(String uid, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demote admin'),
        content: Text(
          'This will remove admin access from $displayName and revert them to a regular consumer account. '
          'They will be logged out of the admin panel on their next login. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Demote'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _adminService.demoteAdmin(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$displayName has been demoted to consumer.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
