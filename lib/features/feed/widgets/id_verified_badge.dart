import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Government ID verified badge; separate from the email [VerifiedBadge].
class IdVerifiedBadge extends StatelessWidget {
  const IdVerifiedBadge({super.key, this.size = 15});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'ID Verified',
      child: Icon(Icons.shield_rounded, color: AppColors.success, size: size),
    );
  }
}
