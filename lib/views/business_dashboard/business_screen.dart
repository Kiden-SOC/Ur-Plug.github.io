import 'package:flutter/material.dart';
import '../auth/login_screen.dart'; 
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/provider_profile.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/photo_widgets.dart';
import '../../widgets/shared_widgets.dart';
import 'manage_photos_screen.dart';
import 'provider_chat_screen.dart';
import 'provider_onboarding_screen.dart';
import 'service_listings_screen.dart';

/// Provider (business) dashboard.
/// Tabs: Overview • Job Requests • Messages • Ratings • Profile
class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  String username = '';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load job requests, ratings and chat threads once on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderProfileController>().loadDashboardData();
    });
  }

  void _logout() {
    context.read<ProviderProfileController>().clearSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  static const List<String> _titles = [
    'Business Dashboard',
    'Job Requests',
    'Messages',
    'My Ratings',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: Text(
          _titles[_tabIndex],
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Logout from Ur Plug', 
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Logout', 
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              onPressed: _logout,
            ),
          ),
        ],
      ),
      body: controller.loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.brandPrimary))
          : IndexedStack(
              index: _tabIndex,
              children: const [
                _OverviewTab(),
                _JobRequestsTab(),
                _MessagesTab(),
                _RatingsTab(),
                _ProfileTab(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandSecondary.withValues(alpha: 0.18),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon:
                  Icon(Icons.dashboard, color: AppColors.brandPrimary),
              label: 'Home'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: controller.pendingJobCount > 0,
              label: Text('${controller.pendingJobCount}'),
              child: const Icon(Icons.work_outline),
            ),
            selectedIcon:
                const Icon(Icons.work, color: AppColors.brandPrimary),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: controller.unreadMessageCount > 0,
              label: Text('${controller.unreadMessageCount}'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon:
                const Icon(Icons.chat_bubble, color: AppColors.brandPrimary),
            label: 'Messages',
          ),
          const NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star, color: AppColors.brandPrimary),
              label: 'Ratings'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.brandPrimary),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// =====================================================================
// TAB 1 — OVERVIEW
// =====================================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final profile = controller.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header card
          UrPlugCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipOval(
                  child: profile.profilePhotoPath.isEmpty
                      ? CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppColors.brandPrimary.withValues(alpha: 0.1),
                          child: const Icon(Icons.storefront,
                              size: 28, color: AppColors.brandPrimary),
                        )
                      : UrPlugPhoto(
                          path: profile.profilePhotoPath,
                          width: 56,
                          height: 56,
                          placeholderIcon: Icons.storefront,
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      Text(
                        profile.tradeTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.brandSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Availability toggle
                Column(
                  children: [
                    Switch(
                      value: profile.isAvailable,
                      activeThumbColor: AppColors.brandSecondary,
                      onChanged: (_) => context
                          .read<ProviderProfileController>()
                          .toggleAvailability(),
                    ),
                    Text(
                      profile.isAvailable ? 'Available' : 'Away',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: profile.isAvailable
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              _StatCard(
                icon: Icons.work_outline,
                label: 'Pending Jobs',
                value: '${controller.pendingJobCount}',
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.star_outline,
                label: 'Avg. Rating',
                value: controller.ratings.isEmpty
                    ? '—'
                    : controller.averageRating.toStringAsFixed(1),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.mark_chat_unread_outlined,
                label: 'Unread',
                value: '${controller.unreadMessageCount}',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Manage service listings entry point
          const SectionTitle('Quick Actions'),
          const SizedBox(height: 10),
          UrPlugCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.design_services,
                      color: AppColors.brandSecondary),
                  title: const Text('Manage Service Listings',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.brandPrimary)),
                  subtitle: Text(
                    '${controller.services.length} listing(s) published',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.brandPrimary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ServiceListingsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppColors.brandSecondary),
                  title: const Text('Manage Business Photos',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.brandPrimary)),
                  subtitle: Text(
                    '${profile.businessPhotoPaths.length} photo(s) posted to customers',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.brandPrimary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ManagePhotosScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_note,
                      color: AppColors.brandSecondary),
                  title: const Text('Edit Profile & Profession',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.brandPrimary)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.brandPrimary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ProviderOnboardingScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Photos posted to customers
          const SectionTitle('Photos Posted to Customers'),
          const SizedBox(height: 10),
          if (profile.businessPhotoPaths.isEmpty)
            UrPlugCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'No photos yet. Add some so customers can see your work.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ManagePhotosScreen()),
                      );
                    },
                    child: const Text('Add Photos'),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profile.businessPhotoPaths.length + 1,
                separatorBuilder: (value, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == profile.businessPhotoPaths.length) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ManagePhotosScreen()),
                        );
                      },
                      child: Container(
                        width: 84,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.brandPrimary.withValues(alpha: 0.25)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add_a_photo_outlined,
                            color: AppColors.brandPrimary),
                      ),
                    );
                  }
                  final path = profile.businessPhotoPaths[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: UrPlugPhoto(
                      path: path,
                      width: 84,
                      height: 84,
                      placeholderIcon: Icons.photo,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),

          // Latest job requests preview
          const SectionTitle('Latest Job Requests'),
          const SizedBox(height: 10),
          if (controller.jobRequests.isEmpty)
            const UrPlugCard(
              child: Text(
                'No job requests yet. Customers will find you through your profile and location.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else
            ...controller.jobRequests
                .take(2)
                .map((job) => _JobRequestCard(job: job)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: UrPlugCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brandSecondary, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.brandPrimary)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// TAB 2 — JOB REQUESTS
// =====================================================================

class _JobRequestsTab extends StatelessWidget {
  const _JobRequestsTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();

    if (controller.jobRequests.isEmpty) {
      return const EmptyState(
        icon: Icons.work_outline,
        title: 'No job requests yet',
        subtitle:
            'When customers request your services, their jobs will appear here for you to accept or decline.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: controller.jobRequests
          .map((job) => _JobRequestCard(job: job))
          .toList(),
    );
  }
}

class _JobRequestCard extends StatelessWidget {
  final JobRequest job;
  const _JobRequestCard({required this.job});

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
                backgroundColor:
                    AppColors.brandPrimary.withValues(alpha: 0.1),
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
              _statusPillFor(job.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(job.serviceNeeded,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textDark, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.near_me,
                  size: 14, color: AppColors.brandSecondary),
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
              const Icon(Icons.schedule,
                  size: 14, color: AppColors.brandSecondary),
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderChatScreen(
                          customerName: job.customerName),
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
                label: const Text('Message Customer',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPillFor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return const StatusPill(
            label: 'Pending', color: AppColors.warning, icon: Icons.schedule);
      case JobStatus.accepted:
        return const StatusPill(
            label: 'Accepted',
            color: AppColors.success,
            icon: Icons.check_circle);
      case JobStatus.declined:
        return StatusPill(
            label: 'Declined',
            color: Colors.red.shade700,
            icon: Icons.cancel);
      case JobStatus.completed:
        return const StatusPill(
            label: 'Completed',
            color: AppColors.brandSecondary,
            icon: Icons.task_alt);
    }
  }
}

// =====================================================================
// TAB 3 — MESSAGES (provider inbox)
// =====================================================================

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();

    if (controller.threads.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No conversations yet',
        subtitle:
            'When customers message you about a job, the conversation will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.threads.length,
      separatorBuilder: (value, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final thread = controller.threads[index];
        return UrPlugCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor:
                  AppColors.brandPrimary.withValues(alpha: 0.1),
              child: const Icon(Icons.person_outline,
                  color: AppColors.brandPrimary),
            ),
            title: Text(thread.customerName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.brandPrimary)),
            subtitle: Text(
              thread.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: thread.unreadCount > 0
                    ? AppColors.textDark
                    : AppColors.textMuted,
                fontWeight: thread.unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(thread.time,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                if (thread.unreadCount > 0)
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: AppColors.brandSecondary,
                    child: Text('${thread.unreadCount}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            onTap: () {
              context
                  .read<ProviderProfileController>()
                  .markThreadRead(thread.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProviderChatScreen(customerName: thread.customerName),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =====================================================================
// TAB 4 — RATINGS RECEIVED
// =====================================================================

class _RatingsTab extends StatelessWidget {
  const _RatingsTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();

    if (controller.ratings.isEmpty) {
      return const EmptyState(
        icon: Icons.star_outline,
        title: 'No ratings yet',
        subtitle:
            'Complete jobs and customers will leave verified reviews here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        UrPlugCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(controller.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandPrimary)),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < controller.averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                  height: 50,
                  width: 1,
                  color: AppColors.brandPrimary.withValues(alpha: 0.1)),
              Column(
                children: [
                  Text('${controller.ratings.length}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandPrimary)),
                  const Text('Verified Reviews',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...controller.ratings.map((rating) => UrPlugCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.brandPrimary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_outline,
                            size: 16, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rating.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brandPrimary,
                                  fontSize: 13)),
                          Text(rating.date,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(rating.stars.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(rating.comment,
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 12.5,
                          height: 1.4)),
                ],
              ),
            )),
      ],
    );
  }
}

// =====================================================================
// TAB 5 — MY PROFILE (mirrors the customer-facing detail screen)
// =====================================================================

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final profile = controller.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UrPlugCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ClipOval(
                  child: profile.profilePhotoPath.isEmpty
                      ? CircleAvatar(
                          radius: 45,
                          backgroundColor:
                              AppColors.brandPrimary.withValues(alpha: 0.1),
                          child: const Icon(Icons.storefront,
                              size: 45, color: AppColors.brandPrimary),
                        )
                      : UrPlugPhoto(
                          path: profile.profilePhotoPath,
                          width: 90,
                          height: 90,
                          placeholderIcon: Icons.storefront,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.businessName.isEmpty
                      ? 'Your Business'
                      : profile.businessName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary),
                ),
                Text(profile.tradeTitle,
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.brandSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const StatusPill(
                        label: 'Verified Plug',
                        color: AppColors.brandSecondary,
                        icon: Icons.verified),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: profile.isAvailable ? 'Available Now' : 'Away',
                      color: profile.isAvailable
                          ? AppColors.success
                          : AppColors.textMuted,
                      icon: Icons.circle,
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric(Icons.history_toggle_off, 'Experience',
                        '${profile.yearsOfExperience} Years'),
                    _metric(
                        Icons.star_outline,
                        'Avg. Rating',
                        controller.ratings.isEmpty
                            ? '—'
                            : controller.averageRating.toStringAsFixed(1)),
                    _metric(Icons.design_services, 'Listings',
                        '${controller.services.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Smart landmark location (matches the customer-facing block)
          UrPlugCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.near_me,
                        color: AppColors.brandSecondary, size: 20),
                    SizedBox(width: 8),
                    Text('Smart Matched Location',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.brandPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  profile.landmarkDescription.isEmpty
                      ? 'No landmark set yet — edit your profile to add one.'
                      : profile.landmarkDescription,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w500),
                ),
                if (profile.district.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${profile.district} District',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
                const SizedBox(height: 4),
                const Text(
                  'This is how customers see your location via Ur Plug smart matching.',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(child: SectionTitle('Business Photos')),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManagePhotosScreen()),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (profile.businessPhotoPaths.isEmpty)
            const Text(
                'No photos added yet. Add some so customers can see your work.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profile.businessPhotoPaths.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: UrPlugPhoto(
                  path: profile.businessPhotoPaths[index],
                  placeholderIcon: Icons.photo,
                ),
              ),
            ),
          const SizedBox(height: 16),

          const SectionTitle('About My Business'),
          const SizedBox(height: 6),
          Text(
            profile.bio.isEmpty ? 'No bio written yet.' : profile.bio,
            style: const TextStyle(
                color: AppColors.textDark, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),

          UrPlugPrimaryButton(
            label: 'Edit Profile',
            icon: Icons.edit,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProviderOnboardingScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.brandSecondary, size: 24),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.brandPrimary)),
      ],
    );
  }
}


