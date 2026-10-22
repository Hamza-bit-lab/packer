import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom sheet to pick the preferred currency for trip posts.
class CurrencyPickerSheet extends StatelessWidget {
  const CurrencyPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (_) => const CurrencyPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<PreferencesProvider>().currency;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Preferred Currency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Used to pre-fill the currency when you post a trip.",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final code in kCurrencies)
                    ListTile(
                      onTap: () {
                        context.read<PreferencesProvider>().setCurrency(code);
                        Navigator.of(context).pop();
                      },
                      leading: Icon(
                        Icons.attach_money_rounded,
                        color: current == code
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        code,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: current == code
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: current == code
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 22,
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
