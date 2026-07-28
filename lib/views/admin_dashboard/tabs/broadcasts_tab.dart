import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/admin_service.dart';
import '../../../utils/uganda_districts.dart';

class BroadcastsTab extends StatefulWidget {
  const BroadcastsTab({super.key});

  @override
  State<BroadcastsTab> createState() => _BroadcastsTabState();
}

class _BroadcastsTabState extends State<BroadcastsTab> {
  final AdminService _adminService = AdminService();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'all';
  String? _district;
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final districts = districtSubRegion.keys.map(_capitalize).toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Compose a broadcast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandPrimary)),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _audience,
          decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Everyone')),
            DropdownMenuItem(value: 'consumers', child: Text('Consumers only')),
            DropdownMenuItem(value: 'providers', child: Text('Providers only')),
          ],
          onChanged: (v) => setState(() => _audience = v ?? 'all'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _district,
          decoration: const InputDecoration(labelText: 'Region (optional)', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
          items: [
            const DropdownMenuItem(value: null, child: Text('All regions')),
            ...districts.map((d) => DropdownMenuItem(value: d, child: Text(d))),
          ],
          onChanged: (v) => setState(() => _district = v),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _sending ? null : _confirmAndSend,
          child: _sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Send broadcast'),
        ),
        const SizedBox(height: 28),
        const Text('Recent broadcasts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandPrimary)),
        const SizedBox(height: 12),
        _buildHistory(),
      ],
    );
  }

  Widget _buildHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.broadcastHistoryStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Text('No broadcasts sent yet.', style: TextStyle(color: Colors.grey));
        }
        return Column(
          children: items.map((b) {
            final sentAt = b['sentAt'] is Timestamp ? (b['sentAt'] as Timestamp).toDate() : null;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(b['body'] ?? '', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    '${b['audience']}${b['district'] != null ? ' • ${b['district']}' : ''} • ${b['recipientCount']} recipients'
                    '${sentAt != null ? ' • ${sentAt.day}/${sentAt.month}/${sentAt.year}' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _confirmAndSend() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in a title and message.')));
      return;
    }

    final audienceLabel = _audience == 'all' ? 'everyone' : _audience;
    final scopeLabel = _district != null ? ' in $_district' : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm broadcast'),
        content: Text('This will send a notification to $audienceLabel$scopeLabel. This cannot be recalled once sent. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);
    try {
      final count = await _adminService.sendBroadcast(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        audience: _audience,
        district: _district,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Broadcast sent to $count recipients.')));
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
