import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Renders an image from a local file path (mobile/desktop) or a blob/web
/// path (Flutter web), falling back to a neutral placeholder icon if the
/// path is empty or fails to load. Used everywhere a provider's profile
/// photo or business/work photo needs to be shown.
class UrPlugPhoto extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;

  const UrPlugPhoto({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return _placeholder();
    }
    if (kIsWeb || path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, exception, stackTrace) => _placeholder(),
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, child, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.brandPrimary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(placeholderIcon,
          color: AppColors.brandPrimary.withValues(alpha: 0.4),
          size: (width ?? 40) * 0.5),
    );
  }
}

/// Circular avatar for a provider's profile photo with a small camera badge
/// for editing. Tapping the whole avatar triggers [onTap].
class UrPlugAvatarPicker extends StatelessWidget {
  final String photoPath;
  final double radius;
  final VoidCallback onTap;

  const UrPlugAvatarPicker({
    super.key,
    required this.photoPath,
    required this.onTap,
    this.radius = 45,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipOval(
            child: photoPath.isEmpty
                ? Container(
                    width: radius * 2,
                    height: radius * 2,
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    child: Icon(Icons.storefront,
                        size: radius, color: AppColors.brandPrimary),
                  )
                : UrPlugPhoto(
                    path: photoPath,
                    width: radius * 2,
                    height: radius * 2,
                    placeholderIcon: Icons.storefront,
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: radius * 0.32,
              backgroundColor: AppColors.brandSecondary,
              child: Icon(Icons.camera_alt,
                  size: radius * 0.32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable grid of business/work photos with an "add photo" tile and a
/// delete button on each thumbnail. Used on the onboarding flow and on the
/// dedicated "Manage Photos" screen.
class BusinessPhotoGrid extends StatelessWidget {
  final List<String> photoPaths;
  final VoidCallback onAdd;
  final void Function(String path) onRemove;
  final bool busy;

  const BusinessPhotoGrid({
    super.key,
    required this.photoPaths,
    required this.onAdd,
    required this.onRemove,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photoPaths.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        if (index == photoPaths.length) {
          return InkWell(
            onTap: busy ? null : onAdd,
            borderRadius: BorderRadius.circular(12),
            child: DottedAddTile(busy: busy),
          );
        }
        final path = photoPaths[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              UrPlugPhoto(path: path, placeholderIcon: Icons.photo),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(path),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DottedAddTile extends StatelessWidget {
  final bool busy;
  const DottedAddTile({super.key, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.25),
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brandPrimary),
            )
          : const Icon(Icons.add_a_photo_outlined,
              color: AppColors.brandPrimary, size: 26),
    );
  }
}
