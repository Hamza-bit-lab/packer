import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Groups a few form fields under a titled card — used to break the long
/// flat field list on the Trip/Good forms into readable sections instead of
/// one unbroken scroll.
class FormSectionCard extends StatelessWidget {
  const FormSectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: AppRadii.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
