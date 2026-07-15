import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/provider_profile.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/shared_widgets.dart';

/// Provider service listing management.
/// Add, edit, pause/activate and delete the services shown to customers.
class ServiceListingsScreen extends StatelessWidget {
  const ServiceListingsScreen({super.key});

  void _openServiceSheet(BuildContext context, {ServiceListing? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Add Service Listing' : 'Edit Service Listing',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Customers browse these listings when choosing a provider.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                UrPlugTextField(
                  controller: titleController,
                  label: 'Service Title',
                  hint: 'e.g. Full House Wiring',
                  icon: Icons.design_services,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter a service title'
                      : null,
                ),
                const SizedBox(height: 16),
                UrPlugTextField(
                  controller: descController,
                  label: 'Short Description',
                  hint:
                      'e.g. Complete wiring for new builds including certification.',
                  icon: Icons.notes,
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please describe this service'
                      : null,
                ),
                const SizedBox(height: 24),
                UrPlugPrimaryButton(
                  label: existing == null ? 'Publish Listing' : 'Save Changes',
                  icon: existing == null ? Icons.publish : Icons.save,
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final controller =
                        context.read<ProviderProfileController>();
                    if (existing == null) {
                      controller.addService(titleController.text.trim(),
                          descController.text.trim());
                    } else {
                      controller.updateService(
                        existing.id,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                      );
                    }
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final services = controller.services;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Service Listings',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openServiceSheet(context),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Service',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: services.isEmpty
          ? const EmptyState(
              icon: Icons.design_services,
              title: 'No service listings yet',
              subtitle:
                  'Add the services you offer so customers can find and book you. Tap "Add Service" to publish your first listing.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: services.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final service = services[index];
                return UrPlugCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(service.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.brandPrimary)),
                          ),
                          StatusPill(
                            label: service.isActive ? 'Active' : 'Paused',
                            color: service.isActive
                                ? AppColors.success
                                : AppColors.textMuted,
                            icon: service.isActive
                                ? Icons.check_circle
                                : Icons.pause_circle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(service.description,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              height: 1.4)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _openServiceSheet(context,
                                existing: service),
                            icon: const Icon(Icons.edit, size: 16),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.brandPrimary),
                            label: const Text('Edit',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold)),
                          ),
                          TextButton.icon(
                            onPressed: () => context
                                .read<ProviderProfileController>()
                                .toggleServiceActive(service.id),
                            icon: Icon(
                                service.isActive
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 16),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.brandSecondary),
                            label: Text(
                                service.isActive ? 'Pause' : 'Activate',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  title: const Text('Delete listing?',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brandPrimary)),
                                  content: Text(
                                    'Customers will no longer see "${service.title}". This cannot be undone.',
                                    style: const TextStyle(
                                        fontSize: 13, height: 1.4),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('Cancel',
                                          style: TextStyle(
                                              color: AppColors.textMuted)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.red.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        context
                                            .read<
                                                ProviderProfileController>()
                                            .removeService(service.id);
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(Icons.delete_outline,
                                size: 20, color: Colors.red.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
