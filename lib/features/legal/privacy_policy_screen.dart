import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'safety_disclaimer.dart';

/// Kept in sync with the website's privacy page.
const List<SafetyDisclaimerSection> _privacySections = [
  SafetyDisclaimerSection(
    'Who this policy covers',
    'This policy applies to anyone who uses the Packer app, whether as a traveler listing spare luggage space or a sender listing an item to be carried. By creating an account, you agree to the collection and use of information described here.',
  ),
  SafetyDisclaimerSection(
    'Information we collect',
    '• Account information: name, email address, phone number, country, and password (stored hashed, never in plain text).\n'
        '• Profile information: an optional profile photo, and the average rating and review count generated from completed trips.\n'
        '• Trip & listing information: routes, dates, airline, available weight, rate per kilogram, item descriptions, and offered rewards you choose to post.\n'
        '• Booking & rating information: requests you send or receive, who pays the traveler, their status, the photo a traveler attaches as proof of delivery, and any ratings or comments left after a completed handover.\n'
        '• Messages: the messages you send and receive in the app\'s chat.\n'
        '• Identity verification (optional): if you choose to verify, the type of document (CNIC or passport) and a photo of it. It is stored privately, reviewed only by our team, and never shown to other users.\n'
        '• Notifications & preferences: your notification settings, saved route alerts, preferred currency, and a push-notification token that identifies your device.\n'
        '• Safety & feedback: reports you file, users you block, and the ideas and votes you post on the feature board.\n'
        '• Technical logs: basic information such as app version, device type, and approximate location derived from your network address, used for security and troubleshooting.\n\n'
        'We do not collect payment card details. Packer does not process payments — travelers and senders settle directly with each other.',
  ),
  SafetyDisclaimerSection(
    'How we use your information',
    '• To operate the core features of the app — posting trips and items, matching, booking requests, and ratings.\n'
        '• To calculate estimated costs based on weight and rate.\n'
        '• To send you the notifications and emails the app needs to work — booking updates, new messages, route-alert matches, verification codes, and password-reset codes — in line with the notification settings you choose.\n'
        '• To maintain trust and safety, including displaying ratings, review counts, and an ID Verified badge on public profiles, and reviewing reports.\n'
        '• To investigate misuse, fraud, or violations of our terms.',
  ),
  SafetyDisclaimerSection(
    'What other users can see',
    'Packer is built around real people meeting in person, so some information is visible to other users by design:\n\n'
        '• Public profile: your name, country, profile photo, average rating, and review count are visible to anyone browsing the app.\n'
        '• ID Verified badge: if your identity check is approved, a badge appears on your profile. The document and its details are never shown.\n'
        '• Phone number: becomes visible to the other party only once a booking request is accepted, so you can arrange the handover by call or WhatsApp. It is never shown before that point.\n'
        '• Messages: visible only to the person you send them to.\n'
        '• Feature board: your name is shown next to ideas you post.\n'
        '• Your email address and password are never shown to other users.',
  ),
  SafetyDisclaimerSection(
    'Sharing',
    'We do not sell personal information and do not share it with advertisers. Limited technical information may be shared with infrastructure providers who host the app and deliver emails and push notifications (for example Google Firebase Cloud Messaging), strictly to operate the service, and we may disclose information where required by law.',
  ),
  SafetyDisclaimerSection(
    'Retention',
    'We retain account and trip information for as long as an account is active.\n\n'
        'Deleting your account: you can delete your account yourself at any time under Settings → Delete Account (your password is required). This permanently removes your profile, trips, items, bookings, messages, ratings, notifications, saved route alerts, and device tokens, along with every photo you uploaded, including any ID document. Requests still in progress are cancelled and the other person is told. Beyond that, we keep information only where the law requires it, for example to resolve a dispute or comply with a legal obligation.',
  ),
  SafetyDisclaimerSection(
    'International use',
    'Packer connects travelers and senders across borders. Your information may be processed and stored in a country other than where you live, and may be visible to a user in a different country as part of arranging a cross-border trip.',
  ),
  SafetyDisclaimerSection(
    'Your rights',
    'You can view and edit your name, photo, phone number, and country in the app, reset a forgotten password with an emailed code, and delete your account under Settings. Depending on where you live, you may also have the right to access a copy of the personal information we hold about you or to object to certain uses of it. Contact us through the app and we will respond within a reasonable period.',
  ),
  SafetyDisclaimerSection(
    "Children's privacy",
    'Packer is not intended for use by anyone under the age of 18. We do not knowingly collect information from minors.',
  ),
  SafetyDisclaimerSection(
    'Changes',
    'We may update this policy from time to time. Material changes will be reflected by an updated "last updated" date.',
  ),
  SafetyDisclaimerSection(
    'Contact',
    'Questions about this policy can be sent to our support team through the app.',
  ),
];

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in _privacySections) ...[
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
