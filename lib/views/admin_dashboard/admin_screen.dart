import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'tabs/overview_tab.dart';
import 'tabs/directory_tab.dart';
import 'tabs/reviews_tab.dart';
import 'tabs/disputes_appeals_tab.dart';
import 'tabs/broadcasts_tab.dart';
import 'tabs/audit_log_tab.dart';
import 'tabs/super_admin_tab.dart';

/// Admin dashboard shell.
///
/// SECURITY: reaching this widget (e.g. via the hardcoded bootstrap admin
/// email, or a role check at login) is not sufficient on its own — this
/// screen re-verifies admin status directly against Firestore on load
/// (defense in depth), so a role change or suspension takes effect
/// immediately rather than only at next login. See SECURITY.md for why
/// this still isn't a substitute for Firestore security rules + custom
/// claims.
///
/// The 7th "Admin Mgmt" tab is only rendered when the signed-in user has
/// role == 'super_admin'. Regular admins see exactly 6 tabs.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = AuthService();

  bool _checking = true;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
  }

  Future<void> _verifyAdmin() async {
    bool isAdmin = false;
    String? role;
    try {
      isAdmin = await _authService.isCurrentUserAdmin();
      if (isAdmin) {
        role = await _authService.getCurrentUserRole();
      }
    } catch (_) {
      isAdmin = false;
    }

    if (!mounted) return;

    if (!isAdmin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    setState(() {
      _isAdmin = true;
      _isSuperAdmin = role == 'super_admin';
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.screenBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
      );
    }

    if (!_isAdmin) {
      // We're already navigating away in _verifyAdmin(); render nothing.
      return const SizedBox.shrink();
    }

    final int tabCount = _isSuperAdmin ? 7 : 6;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ur Plug Hub',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              Text(
                _isSuperAdmin ? 'Super Admin • Full Access' : 'Platform Command Center',
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w300),
              ),
            ],
          ),
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_isSuperAdmin)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Super Admin', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Secure Sign Out',
              onPressed: () async {
                await _authService.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              const Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 18)),
              const Tab(text: 'Directory', icon: Icon(Icons.people_outline, size: 18)),
              const Tab(text: 'Reviews', icon: Icon(Icons.rate_review_outlined, size: 18)),
              const Tab(text: 'Disputes & Appeals', icon: Icon(Icons.gavel_outlined, size: 18)),
              const Tab(text: 'Broadcasts', icon: Icon(Icons.campaign_outlined, size: 18)),
              const Tab(text: 'Audit Log', icon: Icon(Icons.history_outlined, size: 18)),
              if (_isSuperAdmin)
                const Tab(text: 'Admin Mgmt', icon: Icon(Icons.admin_panel_settings_outlined, size: 18)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const OverviewTab(),
            const DirectoryTab(),
            const ReviewsTab(),
            const DisputesAppealsTab(),
            const BroadcastsTab(),
            const AuditLogTab(),
            if (_isSuperAdmin) const SuperAdminTab(),
          ],
        ),
      ),
    );
  }
}
