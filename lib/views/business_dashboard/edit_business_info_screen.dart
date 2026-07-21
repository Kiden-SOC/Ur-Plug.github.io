import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/photo_widgets.dart';
import '../../widgets/shared_widgets.dart';

/// Lets an existing provider edit their business name, profile photo,
/// profession and about/bio — pre-filled with what they already saved,
/// so they only ever change what needs changing.
class EditBusinessInfoScreen extends StatefulWidget {
  const EditBusinessInfoScreen({super.key});

  @override
  State<EditBusinessInfoScreen> createState() =>
      _EditBusinessInfoScreenState();
}

class _EditBusinessInfoScreenState extends State<EditBusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _businessNameController;
  late TextEditingController _customProfessionController;
  late TextEditingController _bioController;
  String? _selectedProfession;
  late String _profilePhotoPath;
  late int _yearsOfExperience;
  bool _saving = false;
  bool _initialized = false;

  static const String _otherProfessionLabel = 'Other (type your own)';

  static const List<String> _professions = [
    'Hair Dresser',
    'Electrician',
    'Plumber',
    'Mechanic',
    'Decorator',
    'Events Planner',
    'Carpenter',
    'Caterer',
    'Tutor',
    'Health Worker',
    'IT & Technology',
    'Agriculture Specialist',
    'Architect & Builder',
    'Cleaner',
    'Painter',
    'Tailor / Fashion Designer',
    'Photographer',
    'Mason / Builder',
    _otherProfessionLabel,
  ];

  bool get _isOtherProfession => _selectedProfession == _otherProfessionLabel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // Pre-fill every field with the provider's existing saved data.
    final profile = context.read<ProviderProfileController>().profile;
    _businessNameController = TextEditingController(text: profile.businessName);
    _bioController = TextEditingController(text: profile.bio);
    _profilePhotoPath = profile.profilePhotoPath;
    _yearsOfExperience = profile.yearsOfExperience;

    if (profile.tradeTitle.isEmpty) {
      _selectedProfession = null;
      _customProfessionController = TextEditingController();
    } else if (_professions.contains(profile.tradeTitle)) {
      _selectedProfession = profile.tradeTitle;
      _customProfessionController = TextEditingController();
    } else {
      _selectedProfession = _otherProfessionLabel;
      _customProfessionController =
          TextEditingController(text: profile.tradeTitle);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _customProfessionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.brandPrimary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.brandPrimary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 82);
    if (file == null) return;
    setState(() => _profilePhotoPath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProfession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose your profession or service'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    if (_isOtherProfession && _customProfessionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type your profession or service'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final controller = context.read<ProviderProfileController>();
    final finalProfession = _isOtherProfession
        ? _customProfessionController.text.trim()
        : (_selectedProfession ?? '');

    // Preserve everything else already saved (location, photos, etc.) and
    // only change the fields edited on this screen.
    final updated = controller.profile.copyWith(
      businessName: _businessNameController.text.trim(),
      tradeTitle: finalProfession,
      yearsOfExperience: _yearsOfExperience,
      bio: _bioController.text.trim(),
      profilePhotoPath: _profilePhotoPath,
    );

    final ok = await controller.updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business info updated.'),
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
        title: const Text('Edit Business Info',
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
              Center(
                child: Column(
                  children: [
                    UrPlugAvatarPicker(
                      photoPath: _profilePhotoPath,
                      onTap: _pickProfilePhoto,
                      radius: 48,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: const Text('Change profile photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              UrPlugTextField(
                controller: _businessNameController,
                label: 'Business / Display Name',
                icon: Icons.store,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter your business name'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedProfession,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Profession / Service',
                  prefixIcon:
                      const Icon(Icons.handyman, color: AppColors.brandPrimary),
                  filled: true,
                  fillColor: AppColors.surface,
                  labelStyle: const TextStyle(
                      color: AppColors.brandPrimary, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.brandSecondary, width: 2),
                  ),
                ),
                items: _professions
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedProfession = val),
                validator: (v) =>
                    v == null ? 'Please choose your profession or service' : null,
              ),
              if (_isOtherProfession) ...[
                const SizedBox(height: 16),
                UrPlugTextField(
                  controller: _customProfessionController,
                  label: 'Type your profession / service',
                  icon: Icons.edit_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please type your profession or service'
                      : null,
                ),
              ],
              const SizedBox(height: 20),
              UrPlugCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_toggle_off,
                            color: AppColors.brandSecondary, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Years of Experience',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _yearsOfExperience >= 30
                              ? '30+ Years'
                              : '$_yearsOfExperience ${_yearsOfExperience == 1 ? "Year" : "Years"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _yearsOfExperience.toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 30,
                      activeColor: AppColors.brandSecondary,
                      inactiveColor: AppColors.brandPrimary.withValues(alpha:0.15),
                      label: _yearsOfExperience >= 30
                          ? '30+'
                          : '$_yearsOfExperience',
                      onChanged: (val) =>
                          setState(() => _yearsOfExperience = val.round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              UrPlugTextField(
                controller: _bioController,
                label: 'About My Business',
                icon: Icons.description_outlined,
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please write a short bio about your services';
                  }
                  if (v.trim().length < 30) {
                    return 'Add a little more detail (at least 30 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              UrPlugPrimaryButton(
                label: 'Save Changes',
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