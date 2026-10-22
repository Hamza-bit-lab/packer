import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Blue checkmark badge for verified users.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 15});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Email verified',
      child: Icon(Icons.verified_rounded, color: AppColors.info, size: size),
    );
  }
}
