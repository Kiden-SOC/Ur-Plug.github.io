import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/audit_log_entry.dart';
import '../../../services/admin_service.dart';

class AuditLogTab extends StatefulWidget {
  const AuditLogTab({super.key});

  @override
  State<AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<AuditLogTab> {
  final AdminService _adminService = AdminService();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AuditLogEntry>>(
      stream: _adminService.auditLogStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load the audit log: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
        }

        var entries = snapshot.data!;
        if (_query.trim().isNotEmpty) {
          final q = _query.toLowerCase();
          entries = entries.where((e) =>
              e.action.toLowerCase().contains(q) ||
              e.adminName.toLowerCase().contains(q) ||
              e.targetType.toLowerCase().contains(q) ||
              e.targetId.toLowerCase().contains(q)).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by admin, action, or target...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No matching audit log entries.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) => _entryTile(entries[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _entryTile(AuditLogEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.action.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brandPrimary),
                ),
              ),
              Text(
                '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year} ${entry.createdAt.hour}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('By ${entry.adminName} • ${entry.targetType}: ${entry.targetId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          if (entry.reason != null && entry.reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Reason: ${entry.reason}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
