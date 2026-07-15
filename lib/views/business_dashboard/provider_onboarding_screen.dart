import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/provider_profile.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/photo_widgets.dart';
import '../../widgets/shared_widgets.dart';
import 'business_screen.dart';

/// First-login onboarding wizard for providers.
///
/// Captures everything shown on the customer-facing
/// provider_detail_screen.dart so a new provider's public profile is
/// complete from day one:
///   Step 1 — Profile photo + business identity + profession
///   Step 2 — Years of experience + brief bio
///   Step 3 — Location, entered manually (district + landmark) so
///            customers are matched by the place the provider put in,
///            not the device's GPS position
///   Step 4 — Photos of the business/work customers can browse
class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  State<ProviderOnboardingScreen> createState() =>
      _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  int _currentStep = 0;
  bool _saving = false;
  final ImagePicker _picker = ImagePicker();

  // Step 1 — Identity & Profession
  final _step1Key = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _customProfessionController = TextEditingController();
  String? _selectedProfession;
  String _profilePhotoPath = '';

  // Step 2 — Experience & Bio
  final _step2Key = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  int _yearsOfExperience = 1;

  // Step 3 — Location (entered manually by the provider)
  final _step3Key = GlobalKey<FormState>();
  final _districtController = TextEditingController();
  final _landmarkController = TextEditingController();

  // Step 4 — Business / work photos
  final List<String> _businessPhotos = [];
  bool _addingPhoto = false;

  static const String _otherProfessionLabel = 'Other (type your own)';

  // Open, editable list of professions. Customers filter by these, but a
  // provider is never limited to it — "Other" lets them type anything.
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

  @override
  void dispose() {
    _businessNameController.dispose();
    _customProfessionController.dispose();
    _bioController.dispose();
    _districtController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  bool get _isOtherProfession => _selectedProfession == _otherProfessionLabel;

  // ---------------------------------------------------------------
  // PHOTO PICKING
  // ---------------------------------------------------------------

  Future<ImageSource?> _askImageSource() {
    return showModalBottomSheet<ImageSource>(
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
  }

  Future<void> _pickProfilePhoto() async {
    final source = await _askImageSource();
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 82);
    if (file == null) return;
    setState(() => _profilePhotoPath = file.path);
  }

  Future<void> _addBusinessPhotos() async {
    final source = await _askImageSource();
    if (source == null) return;
    setState(() => _addingPhoto = true);
    try {
      if (source == ImageSource.camera) {
        final file = await _picker.pickImage(source: source, imageQuality: 82);
        if (file != null) {
          setState(() => _businessPhotos.add(file.path));
        }
      } else {
        final files = await _picker.pickMultiImage(imageQuality: 82);
        if (files.isNotEmpty) {
          setState(() => _businessPhotos.addAll(files.map((f) => f.path)));
        }
      }
    } finally {
      if (mounted) setState(() => _addingPhoto = false);
    }
  }

  void _removeBusinessPhoto(String path) {
    setState(() => _businessPhotos.remove(path));
  }

  // ---------------------------------------------------------------
  // VALIDATION / NAVIGATION
  // ---------------------------------------------------------------

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        final formOk = _step1Key.currentState!.validate();
        if (formOk && _selectedProfession == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please choose your profession or service'),
              backgroundColor: AppColors.warning,
            ),
          );
          return false;
        }
        if (formOk &&
            _isOtherProfession &&
            _customProfessionController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please type your profession or service'),
              backgroundColor: AppColors.warning,
            ),
          );
          return false;
        }
        return formOk;
      case 1:
        return _step2Key.currentState!.validate();
      case 2:
        return _step3Key.currentState!.validate();
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _saving = true);

    final controller = context.read<ProviderProfileController>();
    final String finalProfession = _isOtherProfession
        ? _customProfessionController.text.trim()
        : (_selectedProfession ?? '');

    final profile = ProviderProfile(
      businessName: _businessNameController.text.trim(),
      tradeTitle: finalProfession,
      yearsOfExperience: _yearsOfExperience,
      bio: _bioController.text.trim(),
      district: _districtController.text.trim(),
      landmarkDescription: _landmarkController.text.trim(),
      profilePhotoPath: _profilePhotoPath,
      businessPhotoPaths: List<String>.from(_businessPhotos),
    );

    final ok = await controller.completeOnboarding(profile);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile setup complete. Welcome to Ur Plug!'),
          backgroundColor: AppColors.brandSecondary,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BusinessScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Set Up Your Provider Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // STEP INDICATOR
  // ---------------------------------------------------------------

  Widget _buildStepIndicator() {
    const labels = ['Business', 'Experience', 'Location', 'Photos'];
    return Container(
      color: AppColors.brandPrimary,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Row(
        children: List.generate(labels.length, (i) {
          final bool isActive = i == _currentStep;
          final bool isDone = i < _currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone || isActive
                              ? AppColors.accentRedOrange
                              : Colors.white24,
                        ),
                      ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isDone || isActive
                          ? AppColors.accentRedOrange
                          : Colors.white24,
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 16, color: AppColors.brandPrimary)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? AppColors.brandPrimary
                                    : Colors.white70,
                              ),
                            ),
                    ),
                    if (i < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color:
                              isDone ? AppColors.accentRedOrange : Colors.white24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.white : Colors.white60,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepOne();
      case 1:
        return _buildStepTwo();
      case 2:
        return _buildStepThree();
      case 3:
        return _buildStepFour();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------
  // STEP 1 — PROFILE PHOTO, BUSINESS IDENTITY & PROFESSION
  // ---------------------------------------------------------------

  Widget _buildStepOne() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Tell customers who you are'),
          const SizedBox(height: 4),
          const Text(
            'This information appears on your public profile card.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
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
                  label: Text(_profilePhotoPath.isEmpty
                      ? 'Upload profile photo'
                      : 'Change profile photo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          UrPlugTextField(
            controller: _businessNameController,
            label: 'Business / Display Name',
            hint: 'e.g. Sarah\u2019s Tech Sparks',
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
            onChanged: (val) {
              setState(() => _selectedProfession = val);
            },
            validator: (v) =>
                v == null ? 'Please choose your profession or service' : null,
          ),
          if (_isOtherProfession) ...[
            const SizedBox(height: 16),
            UrPlugTextField(
              controller: _customProfessionController,
              label: 'Type your profession / service',
              hint: 'e.g. Generator Servicing, Bridal Makeup, Landscaping',
              icon: Icons.edit_outlined,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please type your profession or service'
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // STEP 2 — YEARS OF EXPERIENCE & BIO
  // ---------------------------------------------------------------

  Widget _buildStepTwo() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Your experience'),
          const SizedBox(height: 4),
          const Text(
            'Customers trust providers who share their track record.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
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
                  inactiveColor:
                      AppColors.brandPrimary.withValues(alpha: 0.15),
                  label: _yearsOfExperience >= 30
                      ? '30+'
                      : '$_yearsOfExperience',
                  onChanged: (val) {
                    setState(() => _yearsOfExperience = val.round());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          UrPlugTextField(
            controller: _bioController,
            label: 'Brief Bio',
            hint:
                'e.g. Specialized in domestic house wiring, solar installations, and emergency fault finding across Kampala.',
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
          const SizedBox(height: 8),
          Text(
            'Tip: mention the exact problems you solve and the areas you cover.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // STEP 3 — LOCATION (MANUAL ENTRY)
  // ---------------------------------------------------------------

  Widget _buildStepThree() {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Where can customers find you?'),
          const SizedBox(height: 4),
          const Text(
            'Tell us your district and a nearby landmark — this is exactly what we use to match you with nearby customers, so keep it accurate. You can update it any time, including later if you move.',
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
            controller: _landmarkController,
            label: 'Location Landmark Description',
            hint:
                'e.g. Kirinya Trading Centre, near the TotalEnergies Station',
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // STEP 4 — BUSINESS / WORK PHOTOS
  // ---------------------------------------------------------------

  Widget _buildStepFour() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Show off your work'),
        const SizedBox(height: 4),
        const Text(
          'Add photos of your business and past jobs — customers can browse these on your profile.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 16),
        BusinessPhotoGrid(
          photoPaths: _businessPhotos,
          onAdd: _addBusinessPhotos,
          onRemove: _removeBusinessPhoto,
          busy: _addingPhoto,
        ),
        const SizedBox(height: 12),
        Text(
          _businessPhotos.isEmpty
              ? 'Optional, but profiles with photos get picked more often.'
              : '${_businessPhotos.length} photo(s) added. You can add more any time from your dashboard.',
          style: const TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // ---------------------------------------------------------------

  Widget _buildBottomBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _saving ? null : () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Back',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: UrPlugPrimaryButton(
                label: _currentStep == 3 ? 'Finish Setup' : 'Continue',
                icon: _currentStep == 3
                    ? Icons.check_circle_outline
                    : Icons.arrow_forward,
                busy: _saving,
                onPressed: _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
