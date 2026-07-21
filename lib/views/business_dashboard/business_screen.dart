import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/photo_widgets.dart';
import 'job_history_screen.dart';
import 'messages_screen.dart';
import 'pending_jobs_screen.dart';
import 'ratings_screen.dart';
import 'settings_screen.dart';
import 'top_customers_screen.dart';
import 'unfinished_jobs_screen.dart';

/// Provider (business) dashboard shell.
/// Bottom navigation: Overview (home) • Settings
class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load job requests, ratings, top customers and chat threads once on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderProfileController>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _BrandHeader(),
            Expanded(
              child: controller.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brandPrimary))
                  : IndexedStack(
                      index: _tabIndex,
                      children: const [
                        _OverviewTab(),
                        SettingsScreen(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandSecondary.withValues(alpha:0.18),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.brandPrimary),
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon:
                  Icon(Icons.more_horiz, color: AppColors.brandPrimary),
              label: 'Settings'),
        ],
      ),
    );
  }
}

// =====================================================================
// BRAND HEADER — replaces the generic "Business Dashboard" app bar.
// Shows just the business photo, name and the availability toggle.
// =====================================================================

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final profile = controller.profile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandPrimary, AppColors.brandSecondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: profile.profilePhotoPath.isEmpty
                  ? const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.storefront,
                          size: 26, color: AppColors.brandPrimary),
                    )
                  : UrPlugPhoto(
                      path: profile.profilePhotoPath,
                      width: 52,
                      height: 52,
                      placeholderIcon: Icons.storefront,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.businessName.isEmpty
                      ? 'Your Business'
                      : profile.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (profile.tradeTitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      profile.tradeTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha:0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Switch(
                value: profile.isAvailable,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha:0.4),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white.withValues(alpha:0.2),
                onChanged: (_) => context
                    .read<ProviderProfileController>()
                    .toggleAvailability(),
              ),
              Text(
                profile.isAvailable ? 'Available' : 'Away',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// OVERVIEW TAB — six square action tiles, nothing else.
// =====================================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to check?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a tile to view the details.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.02,
            children: [
              _ActionTile(
                icon: Icons.pending_actions,
                label: 'Pending Jobs',
                gradient: const [Color(0xFF14A38B), Color(0xFF0B5E56)],
                badgeCount: controller.pendingJobCount,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PendingJobsScreen()),
                ),
              ),
              _ActionTile(
                icon: Icons.build_circle,
                label: 'Unfinished Jobs',
                gradient: const [Color(0xFF2DD4BF), Color(0xFF0D9488)],
                badgeCount: controller.ongoingJobCount,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UnfinishedJobsScreen()),
                ),
              ),
              _ActionTile(
                icon: Icons.chat_bubble,
                label: 'Messages',
                gradient: const [Color(0xFF14A38B), Color(0xFF0B5E56)],
                badgeCount: controller.unreadMessageCount,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MessagesScreen()),
                ),
              ),
              _ActionTile(
                icon: Icons.history,
                label: 'Job History',
                gradient: const [Color(0xFF6C7A99), Color(0xFF4A5670)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const JobHistoryScreen()),
                ),
              ),
              _ActionTile(
                icon: Icons.star,
                label: 'Ratings & Reviews',
                gradient: const [Color(0xFFFFB020), Color(0xFFE0921E)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RatingsScreen()),
                ),
              ),
              _ActionTile(
                icon: Icons.workspace_premium,
                label: 'Top Customers',
                gradient: const [Color(0xFF10B981), Color(0xFF065F46)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TopCustomersScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final int? badgeCount;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentRedOrange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



