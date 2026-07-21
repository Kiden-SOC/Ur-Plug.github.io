import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/shared_widgets.dart';

/// Lets an existing provider edit their district, town and landmark —
/// pre-filled with whatever they already saved, so location updates are a
/// quick edit rather than a fresh entry.
class EditLocationScreen extends StatefulWidget {
  const EditLocationScreen({super.key});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _districtController;
  late TextEditingController _townController;
  late TextEditingController _landmarkController;
  bool _saving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final profile = context.read<ProviderProfileController>().profile;
    _districtController = TextEditingController(text: profile.district);
    _townController = TextEditingController(text: profile.town);
    _landmarkController =
        TextEditingController(text: profile.landmarkDescription);
  }

  @override
  void dispose() {
    _districtController.dispose();
    _townController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final controller = context.read<ProviderProfileController>();
    final ok = await controller.updateLocation(
      latitude: controller.profile.latitude,
      longitude: controller.profile.longitude,
      district: _districtController.text.trim(),
      town: _townController.text.trim(),
      landmarkDescription: _landmarkController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated.'),
          backgroundColor: AppColors.brandSecondary,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save changes. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.brandPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Edit Location',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Where can customers find you?'),
              const SizedBox(height: 4),
              const Text(
                'This is exactly what we use to match you with nearby customers, so keep it accurate.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              UrPlugTextField(
                controller: _districtController,
                label: 'District',
                hint: 'e.g. Kampala, Wakiso, Gulu',
                icon: Icons.map,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter your district'
                    : null,
              ),
              const SizedBox(height: 16),
              UrPlugTextField(
                controller: _townController,
                label: 'Town',
                hint: 'e.g. Kireka, Bweyogerere, Ntinda',
                icon: Icons.location_city,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter your town'
                    : null,
              ),
              const SizedBox(height: 16),
              UrPlugTextField(
                controller: _landmarkController,
                label: 'Location Landmark Description',
                hint: 'e.g. Kirinya Trading Centre, near the TotalEnergies Station',
                icon: Icons.near_me,
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please describe your location with a landmark';
                  }
                  if (v.trim().length < 10) {
                    return 'Add a clearer landmark (e.g. "near the market taxi stage")';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              UrPlugCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppColors.brandSecondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _landmarkController.text.trim().isEmpty
                            ? 'Your landmark will appear on your public profile under "Smart Matched Location".'
                            : 'Preview: "${_landmarkController.text.trim()}"',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              UrPlugPrimaryButton(
                label: 'Save Location',
                icon: Icons.check_circle_outline,
                busy: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
