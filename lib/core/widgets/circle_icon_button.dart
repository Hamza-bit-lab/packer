import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small white circular icon button with an optional unread dot.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showDot = false,
    this.background = Colors.white,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;
  final Color background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: background,
          shape: CircleBorder(side: BorderSide(color: AppColors.border)),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                color: foreground ?? AppColors.textPrimary,
                size: 19,
              ),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: background, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
