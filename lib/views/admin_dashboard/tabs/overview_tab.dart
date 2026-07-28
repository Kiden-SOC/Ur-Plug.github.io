import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/admin_service.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final AdminService _adminService = AdminService();

  late Future<List<Map<String, dynamic>>> _supplyDemandFuture;

  @override
  void initState() {
    super.initState();
    _supplyDemandFuture = _adminService.supplyDemandSummary();
  }

  void _refresh() {
    setState(() {
      _supplyDemandFuture = _adminService.supplyDemandSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricsRow(),
          const SizedBox(height: 24),
          const Text(
            'Supply vs. Demand',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Search activity vs. available providers by category and district over the last 30 days.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          _buildSupplyDemandTable(),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return StreamBuilder(
      stream: _adminService.usersStream(),
      builder: (context, usersSnap) {
        return StreamBuilder(
          stream: _adminService.providersStream(),
          builder: (context, providersSnap) {
            final totalUsers = usersSnap.data?.length ?? 0;
            final providers = providersSnap.data ?? [];
            final pendingVerification =
                providers.where((p) => p['verificationStatus'] == 'pending').length;
            final suspended = providers.where((p) => p['accountStatus'] == 'suspended').length;

            return Row(
              children: [
                _metricBlock('Total Users', '$totalUsers', Icons.people_outline),
                _metricBlock('Pending Verification', '$pendingVerification', Icons.hourglass_empty),
                _metricBlock('Suspended Providers', '$suspended', Icons.block_outlined),
              ],
            );
          },
        );
      },
    );
  }

  Widget _metricBlock(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.brandPrimary, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60), maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplyDemandTable() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supplyDemandFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
          );
        }
        if (snapshot.hasError) {
          return Text('Could not load analytics: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text(
              'No search activity recorded yet. This table fills in as customers search for services.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: rows.take(15).map((row) {
              final gap = row['gapScore'] as int;
              final isGap = gap > 0;
              return ListTile(
                title: Text('${row['category']} • ${row['district']}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(
                  '${row['searchVolume']} searches • ${row['availableProviders']} available providers',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isGap ? AppColors.warning : AppColors.success).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGap ? 'Supply gap' : 'Healthy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isGap ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
