import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../views/business_dashboard/provider_chat_screen.dart';

/// Contact modal that appears when provider taps "Contact Customer"
/// Provides options to call directly or send a message
class ContactModal extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final String userUid;
  final String userName;

  const ContactModal({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    required this.userUid,
    required this.userName,
  });

  @override
  State<ContactModal> createState() => _ContactModalState();
}

class _ContactModalState extends State<ContactModal> {
  bool _isLoading = false;

  Future<void> _makeCall() async {
    if (widget.phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Uri callUri = Uri(scheme: 'tel', path: widget.phoneNumber);
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not initiate phone call'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openChat() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderChatScreen(
          customerUid: widget.userUid,
          customerName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Contact Customer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (widget.phoneNumber.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.phoneNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.call, color: AppColors.brandSecondary),
            ),
            title: const Text(
              'Make a Call',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Call directly via phone'),
            onTap: _isLoading ? null : () => _makeCall(),
            enabled: !_isLoading,
          ),
          const Divider(height: 0),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.message_outlined, color: AppColors.brandPrimary),
            ),
            title: const Text(
              'Send Message',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Chat inside the app'),
            onTap: _isLoading ? null : _openChat,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
