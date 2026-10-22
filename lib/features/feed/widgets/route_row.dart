import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class RouteRow extends StatelessWidget {
  const RouteRow({
    super.key,
    required this.fromCity,
    required this.toCity,
    this.background,
  });

  final String fromCity;
  final String toCity;

  /// Color behind the plane icon; must match the row background.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = background ?? AppColors.surface;

    return Row(
      children: [
        Text(
          fromCity,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Divider(color: AppColors.border, height: 1, thickness: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  color: resolvedBackground,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(
                      Icons.airplanemode_active_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          toCity,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
