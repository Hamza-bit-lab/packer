import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/user.dart';
import '../../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 40});

  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.profilePicUrl;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  _Initials(user: user, size: size),
            )
          : _Initials(user: user, size: size),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.user, required this.size});

  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      user.initials,
      style: TextStyle(
        color: AppColors.onPrimary,
        fontWeight: FontWeight.w700,
        fontSize: size * 0.36,
      ),
    );
  }
}
