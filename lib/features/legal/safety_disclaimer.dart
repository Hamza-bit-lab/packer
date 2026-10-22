import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// One titled paragraph of the safety/liability notice.
class SafetyDisclaimerSection {
  const SafetyDisclaimerSection(this.title, this.body);

  final String title;
  final String body;
}

const List<SafetyDisclaimerSection> safetyDisclaimerSections = [
  SafetyDisclaimerSection(
    'What Packer is',
    "Packer connects travelers with spare luggage space to senders who need something carried abroad. We do not inspect, handle, transport, or take possession of any item ourselves — the agreement to carry a specific item, and full legal responsibility for it, is between the traveler and the sender.",
  ),
  SafetyDisclaimerSection(
    'What can never be sent or carried',
    'It is strictly forbidden to send, request, offer to carry, or carry anything illegal, restricted, or banned by customs or border-control authorities, the civil aviation authority governing the flight, or airport/airline security regulations. This includes — without limitation — illegal drugs or narcotics, weapons, firearms or ammunition, explosives, flammable or otherwise hazardous materials, counterfeit goods, and any other item prohibited under applicable law.',
  ),
  SafetyDisclaimerSection(
    "The traveler's responsibility",
    'Before accepting or carrying anything, you must personally inspect the item and confirm it matches what was described, and that you are satisfied it is legal and safe to carry. Always decline anything you cannot verify, that arrives sealed against inspection, or that you have any doubt about.',
  ),
  SafetyDisclaimerSection(
    "The sender's responsibility",
    'You are responsible for accurately describing the item you send and for warranting that it is legal to send and to carry across the relevant border. Never seal an item in a way that prevents the traveler from inspecting it before departure.',
  ),
  SafetyDisclaimerSection(
    'Our position',
    'Packer accepts no responsibility or liability whatsoever for any illegal, prohibited, or dangerous item sent or carried through the platform, or for any resulting consequence — including seizure, fines, detention, or criminal liability. That responsibility rests entirely with the sender and the traveler who agreed to it. Accounts found violating this policy may be suspended or removed, and may be reported to the relevant authorities.',
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
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: AppColors.warning,
        size: 32,
      ),
      title: Text(
        isConfirmation ? 'Before you send an item' : 'Before you continue',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final section in safetyDisclaimerSections) ...[
                Text(
                  section.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  section.body,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: isConfirmation
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      actions: [
        if (isConfirmation)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop(isConfirmation ? true : null),
          child: Text(isConfirmation ? 'I Understand & Agree' : 'I Understand'),
        ),
      ],
    );
  }
}
