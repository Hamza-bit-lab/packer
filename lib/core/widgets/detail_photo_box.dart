import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The photo at the top of a Trip/Good detail screen — falls back to a
/// bordered placeholder instead of leaving blank space when no photo was
/// posted.
class DetailPhotoBox extends StatelessWidget {
  const DetailPhotoBox({
    super.key,
    required this.photoUrl,
    required this.icon,
    required this.placeholderLabel,
  });

  final String? photoUrl;
  final IconData icon;
  final String placeholderLabel;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      height: 140,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(
            placeholderLabel,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
