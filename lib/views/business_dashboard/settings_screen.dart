import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/shared_widgets.dart';
import '../auth/login_screen.dart';
import 'edit_business_info_screen.dart';
import 'edit_location_screen.dart';
import 'manage_photos_screen.dart';
import 'service_listings_screen.dart';

/// Settings hub — everything the provider manages about their business
/// lives here: identity, photos, location and service listings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
        content: const Text(
          'You\u2019ll need to sign in again to access your dashboard.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<ProviderProfileController>().clearSession();
              Navigator.of(dialogContext).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final profile = controller.profile;

    final String locationSummary = [
      if (profile.town.isNotEmpty) profile.town,
      if (profile.district.isNotEmpty) '${profile.district} District',
    ].join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Business Settings'),
          const SizedBox(height: 4),
          const Text(
            'Everything customers see about your business — keep it up to date.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          _SettingsTile(
            icon: Icons.storefront,
            title: 'Business Info',
            subtitle: profile.businessName.isEmpty
                ? 'Add your business name, photo & about'
                : '${profile.businessName} \u2022 ${profile.tradeTitle}',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const EditBusinessInfoScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.photo_library_outlined,
            title: 'Business Photos',
            subtitle: profile.businessPhotoPaths.isEmpty
                ? 'Add photos of your business and past jobs'
                : '${profile.businessPhotoPaths.length} photo(s) visible to customers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManagePhotosScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.near_me_outlined,
            title: 'Location',
            subtitle: locationSummary.isEmpty
                ? 'Add your district, town & landmark'
                : locationSummary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditLocationScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.design_services_outlined,
            title: 'Service Listings',
            subtitle: controller.services.isEmpty
                ? 'List the services customers can find you for'
                : '${controller.services.length} listing(s) published',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ServiceListingsScreen()),
            ),
          ),

          const SizedBox(height: 28),
          const SectionTitle('Account'),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: 'Sign out of your provider account',
            iconColor: Colors.red.shade700,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color tint = iconColor ?? AppColors.brandSecondary;
    return UrPlugCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tint.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: tint, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: AppColors.brandPrimary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.brandPrimary),
        onTap: onTap,
      ),
    );
  }
}