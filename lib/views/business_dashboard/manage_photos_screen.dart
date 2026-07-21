import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/photo_widgets.dart';
import '../../widgets/shared_widgets.dart';

/// Lets a provider change their profile photo and manage the gallery of
/// business/work photos that customers see on their public profile.
class ManagePhotosScreen extends StatefulWidget {
  const ManagePhotosScreen({super.key});

  @override
  State<ManagePhotosScreen> createState() => _ManagePhotosScreenState();
}

class _ManagePhotosScreenState extends State<ManagePhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _updatingProfilePhoto = false;
  bool _addingPhoto = false;

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

  Future<void> _changeProfilePhoto() async {
    final controller = context.read<ProviderProfileController>();
    final source = await _askImageSource();
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 82);
    if (file == null) return;

    if(!mounted) return;
    setState(() => _updatingProfilePhoto = true);
    final ok = await controller.setProfilePhoto(file.path);
    
    if (!mounted) return;
    setState(() => _updatingProfilePhoto = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your profile photo.')),
      );
    }
  }

  Future<void> _addBusinessPhotos() async {
    final controller = context.read<ProviderProfileController>();
    final source = await _askImageSource();
    if (source == null) return;
    
    setState(() => _addingPhoto = true);
    try {
      if (source == ImageSource.camera) {
        final file = await _picker.pickImage(source: source, imageQuality: 82);
        if (file != null) {
          await controller.addBusinessPhoto(file.path);
        }
      } else {
        final files = await _picker.pickMultiImage(imageQuality: 82);
        if (files.isNotEmpty) {
          await controller.addBusinessPhotos(files.map((f) => f.path).toList());
        }
      }
    } finally {
      if (mounted) setState(() => _addingPhoto = false);
    }
  }

  Future<void> _removeBusinessPhoto(String path) async {
    // FIX: Read controller state safely prior to async flow
    final controller = context.read<ProviderProfileController>();
    await controller.removeBusinessPhoto(path);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();
    final profile = controller.profile;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text(
          'Manage Photos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Profile Photo'),
            const SizedBox(height: 4),
            const Text(
              'This is what customers see next to your business name.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Center(
              child: Column(
                children: [
                  UrPlugAvatarPicker(
                    photoPath: profile.profilePhotoPath,
                    onTap: _updatingProfilePhoto ? () {} : _changeProfilePhoto,
                    radius: 50,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _updatingProfilePhoto ? null : _changeProfilePhoto,
                    icon: _updatingProfilePhoto
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined, size: 16),
                    label: Text(profile.profilePhotoPath.isEmpty
                        ? 'Upload profile photo'
                        : 'Change profile photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Business & Work Photos'),
            const SizedBox(height: 4),
            const Text(
              'Show customers your business and examples of jobs you\u2019ve done.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            BusinessPhotoGrid(
              photoPaths: profile.businessPhotoPaths,
              onAdd: _addBusinessPhotos,
              onRemove: _removeBusinessPhoto,
              busy: _addingPhoto,
            ),
            const SizedBox(height: 12),
            Text(
              '${profile.businessPhotoPaths.length} photo(s) on your public profile.',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}