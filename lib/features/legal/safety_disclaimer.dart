import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// One titled paragraph of the safety/liability notice — also reused
/// as-is (title/body only, no icon) by the Privacy Policy and Terms of
/// Service screens, which is why [icon] defaults rather than being required.
class SafetyDisclaimerSection {
  const SafetyDisclaimerSection(
    this.title,
    this.body, [
    this.icon = Icons.article_outlined,
    this.isWarning = false,
  ]);

  final String title;
  final String body;
  final IconData icon;

  /// True for the one section that needs to stand out — what can never be
  /// sent — rendered in the error color instead of the neutral brand tint.
  final bool isWarning;
}

const List<SafetyDisclaimerSection> safetyDisclaimerSections = [
  SafetyDisclaimerSection(
    'What Packer is',
    "Packer connects travelers with spare luggage space to senders who need something carried abroad. We do not inspect, handle, transport, or take possession of any item ourselves — the agreement to carry a specific item, and full legal responsibility for it, is between the traveler and the sender.",
    Icons.info_outline_rounded,
  ),
  SafetyDisclaimerSection(
    'What can never be sent or carried',
    'It is strictly forbidden to send, request, offer to carry, or carry anything illegal, restricted, or banned by customs or border-control authorities, the civil aviation authority governing the flight, or airport/airline security regulations. This includes — without limitation — illegal drugs or narcotics, weapons, firearms or ammunition, explosives, flammable or otherwise hazardous materials, counterfeit goods, and any other item prohibited under applicable law.',
    Icons.block_rounded,
    true,
  ),
  SafetyDisclaimerSection(
    "The traveler's responsibility",
    'Before accepting or carrying anything, you must personally inspect the item and confirm it matches what was described, and that you are satisfied it is legal and safe to carry. Always decline anything you cannot verify, that arrives sealed against inspection, or that you have any doubt about.',
    Icons.luggage_outlined,
  ),
  SafetyDisclaimerSection(
    "The sender's responsibility",
    'You are responsible for accurately describing the item you send and for warranting that it is legal to send and to carry across the relevant border. Never seal an item in a way that prevents the traveler from inspecting it before departure.',
    Icons.outbox_outlined,
  ),
  SafetyDisclaimerSection(
    'Our position',
    'Packer accepts no responsibility or liability whatsoever for any illegal, prohibited, or dangerous item sent or carried through the platform, or for any resulting consequence — including seizure, fines, detention, or criminal liability. That responsibility rests entirely with the sender and the traveler who agreed to it. Accounts found violating this policy may be suspended or removed, and may be reported to the relevant authorities.',
    Icons.gavel_rounded,
  ),
];

/// Shared dialog for the one-time notice and the booking gate.
class SafetyDisclaimerDialog extends StatelessWidget {
  const SafetyDisclaimerDialog({super.key, required this.isConfirmation});

  final bool isConfirmation;

  /// One-time informational notice; caller manages the "seen" flag.
  static Future<void> showOnce(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SafetyDisclaimerDialog(isConfirmation: false),
    );
  }

  /// Mandatory gate; true only if the user agrees.
  static Future<bool> confirm(BuildContext context) async {
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SafetyDisclaimerDialog(isConfirmation: true),
    );
    return agreed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: AppColors.warning,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isConfirmation
                        ? 'Before you send an item'
                        : 'Before you continue',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  children: [
                    for (final section in safetyDisclaimerSections) ...[
                      _SectionCard(section: section),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(isConfirmation ? true : null),
                      child: Text(
                        isConfirmation
                            ? 'I Understand & Agree'
                            : 'I Understand',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isConfirmation) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final SafetyDisclaimerSection section;

  @override
  Widget build(BuildContext context) {
    final accent = section.isWarning ? AppColors.error : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: section.isWarning ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(section.icon, size: 15, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
