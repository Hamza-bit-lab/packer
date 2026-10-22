import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/verify_email_screen.dart';
import '../../feedback/screens/feature_requests_screen.dart';
import '../../legal/privacy_policy_screen.dart';
import '../../legal/safety_guidelines_screen.dart';
import '../../legal/terms_of_service_screen.dart';
import '../../notifications/screens/notification_preferences_screen.dart';
// Go Premium — on hold, re-enable later:
// import '../../premium/widgets/go_premium_banner.dart';
import '../../route_alerts/screens/route_alerts_screen.dart';
import '../widgets/currency_picker_sheet.dart';
import '../widgets/delete_account_dialog.dart';
import 'edit_profile_screen.dart';
import 'id_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currency = context.watch<PreferencesProvider>().currency;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: SectionHeader(title: 'Settings'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Go Premium — on hold, re-enable later:
                    // const GoPremiumBanner(),
                    // const SizedBox(height: 22),
                    if (!user.emailVerified) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.mark_email_unread_outlined,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Verify your email',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "We've emailed you a 6-digit code. Verifying builds trust with other travelers and senders.",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const VerifyEmailScreen(),
                                ),
                              ),
                              child: const Text('Enter code'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    const _SectionLabel('Account'),
                    _MenuRow(
                      icon: Icons.account_circle_outlined,
                      label: 'Account',
                      subtitle: 'Name, photo, phone, and email',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: user.isIdVerified
                          ? Icons.verified_user_rounded
                          : Icons.shield_outlined,
                      iconColor: user.isIdVerified ? AppColors.success : null,
                      label: user.isIdVerified
                          ? 'ID Verified'
                          : 'Verify Your ID',
                      subtitle: user.isIdVerified
                          ? 'Your identity has been confirmed'
                          : 'Build trust with other travelers and senders',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const IdVerificationScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Notifications'),
                    _MenuRow(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      subtitle: 'Choose what you get notified about',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationPreferencesScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: Icons.bookmark_border_rounded,
                      label: 'Route Alerts',
                      subtitle: 'Get notified about trips on saved routes',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RouteAlertsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Preferences'),
                    _MenuRow(
                      icon: Icons.attach_money_rounded,
                      label: 'Currency',
                      subtitle: currency ?? 'Set your preferred currency',
                      onTap: () => CurrencyPickerSheet.show(context),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('Feedback'),
                    _MenuRow(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Feature Requests',
                      subtitle: 'Suggest features and vote on ideas',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FeatureRequestsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: Icons.star_border_rounded,
                      label: 'Rate the App',
                      subtitle: "Leave a review once we're live on the store",
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "We'll add this once the app is live on the store.",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel('About'),
                    _InfoTile(
                      icon: Icons.info_outline_rounded,
                      label: 'App Version',
                      value: _appVersion ?? '…',
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      subtitle: 'View our terms of service',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      subtitle: 'View our privacy policy',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: Icons.shield_moon_outlined,
                      label: 'Safety Guidelines',
                      subtitle: 'Tips for safe meetups and exchanges',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SafetyGuidelinesScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Material(
                        color: AppColors.error.withValues(alpha: 0.05),
                        child: InkWell(
                          onTap: () => context.read<AuthProvider>().logout(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Log Out',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: () => DeleteAccountDialog.show(context),
                        child: Text(
                          'Delete Account',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// Flat settings row with a leading icon.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Icon(icon, size: 23, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Non-interactive version of [_MenuRow], no chevron.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Icon(icon, size: 23, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
