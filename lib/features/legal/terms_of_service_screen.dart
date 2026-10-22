import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'safety_disclaimer.dart';

/// Kept in sync with the website's terms page, in app wording.
const List<SafetyDisclaimerSection> _termsSections = [
  SafetyDisclaimerSection(
    'Acceptance',
    'By using the Packer app, you agree to these terms. If you do not agree with them, please do not use the app.',
  ),
  SafetyDisclaimerSection(
    'Use of the app',
    'The app is provided to connect travelers with spare luggage space to senders who need something carried abroad. You agree not to misuse the app, interfere with its operation, or attempt to access it other than through the interfaces we provide.',
  ),
  SafetyDisclaimerSection(
    'What Packer is',
    'Packer is a marketplace that introduces travelers with spare luggage space to senders who need something carried abroad. We do not transport, store, or handle any item ourselves — the agreement to carry an item, and the responsibility for it, is between the traveler and the sender.',
  ),
  SafetyDisclaimerSection(
    'Your account',
    'You are responsible for keeping your login secure and for what happens under your account. You can delete your account at any time from Settings. We may suspend or remove accounts that break these terms or our safety rules — for example by sending or carrying prohibited items, or by misusing reports, messages, or ratings.',
  ),
  SafetyDisclaimerSection(
    'Prohibited items & liability',
    'It is strictly forbidden to send, request, offer to carry, or carry anything illegal, restricted, or banned by customs, border-control, or aviation authorities. See Safety Guidelines in Settings for the full policy on prohibited items and where liability rests.',
  ),
  SafetyDisclaimerSection(
    'Information accuracy',
    'We take care to keep the app\'s content accurate and current, but we provide it "as is" without warranties of any kind.',
  ),
  SafetyDisclaimerSection(
    'Intellectual property',
    'The Packer name, brand, text, and design elements in this app are owned by Packer or its licensors. Nothing here transfers any ownership to you.',
  ),
  SafetyDisclaimerSection(
    'Third-party links',
    'The app may link to external resources we do not control. We are not responsible for their content or practices.',
  ),
  SafetyDisclaimerSection(
    'Limitation of liability',
    'To the extent permitted by law, Packer is not liable for any indirect or consequential loss arising from your use of, or inability to use, this app.',
  ),
  SafetyDisclaimerSection(
    'Changes',
    'We may revise these terms at any time. The most recently published version is the one that applies.',
  ),
  SafetyDisclaimerSection(
    'Contact',
    'Questions about these terms can be sent to our support team through the app.',
  ),
];

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in _termsSections) ...[
                Text(
                  section.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  section.body,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
