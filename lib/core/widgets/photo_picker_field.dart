import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Photo preview/picker for the Trip and Good forms.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.pickedPath,
    required this.existingUrl,
    required this.onPick,
    required this.onClear,
  });

  final String? pickedPath;
  final String? existingUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;

  bool get _hasPhoto => pickedPath != null || existingUrl != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 160,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (pickedPath != null)
              Image.file(File(pickedPath!), fit: BoxFit.cover)
            else if (existingUrl != null)
              CachedNetworkImage(
                imageUrl: existingUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _placeholder(),
              )
            else
              _placeholder(),
            if (_hasPhoto)
              Positioned(
                top: 6,
                right: 6,
                child: IconButton.filled(
                  onPressed: onClear,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.ink.withValues(alpha: 0.6),
                    minimumSize: const Size(32, 32),
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            color: AppColors.textSecondary,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            'Add a photo (optional)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
