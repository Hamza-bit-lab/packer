// Go Premium is on hold for now — this whole file is commented out (not removed).
// To bring the feature back, uncomment this file and the matching lines in
// home_screen.dart and profile_screen.dart (search for "Go Premium").
//
// import 'package:flutter/material.dart';
//
// import '../../../core/theme/app_theme.dart';
//
// /// UI only for now — no billing/IAP wired up yet. Both actions below just
// /// tell the user it's coming rather than pretending to charge anything.
// class GoPremiumScreen extends StatelessWidget {
//   const GoPremiumScreen({super.key});
//
//   void _comingSoon(BuildContext context) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Premium is coming soon.')));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Go Premium')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
//               decoration: BoxDecoration(
//                 gradient: AppColors.heroGradient,
//                 borderRadius: BorderRadius.circular(AppRadii.card),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     width: 64,
//                     height: 64,
//                     alignment: Alignment.center,
//                     decoration: BoxDecoration(
//                       color: AppColors.onPrimary.withValues(alpha: 0.12),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.workspace_premium_rounded,
//                       color: AppColors.onPrimary,
//                       size: 34,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Unlock Premium',
//                     style: TextStyle(
//                       color: AppColors.onPrimary,
//                       fontWeight: FontWeight.w800,
//                       fontSize: 22,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     'Get the most out of every trip and shipment',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: AppColors.onPrimary.withValues(alpha: 0.75),
//                       fontSize: 13.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 22),
//             Container(
//               padding: const EdgeInsets.all(18),
//               decoration: BoxDecoration(
//                 color: AppColors.surface,
//                 borderRadius: BorderRadius.circular(AppRadii.card),
//                 border: Border.all(color: AppColors.border),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'What you get',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w800,
//                       fontSize: 16,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const _Benefit(
//                     icon: Icons.block_rounded,
//                     label: 'Remove all ads',
//                   ),
//                   const SizedBox(height: 14),
//                   const _Benefit(
//                     icon: Icons.trending_up_rounded,
//                     label: 'Priority placement for your listings',
//                   ),
//                   const SizedBox(height: 14),
//                   const _Benefit(
//                     icon: Icons.notifications_active_rounded,
//                     label: 'Unlimited saved route alerts',
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 18),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppColors.surface,
//                 borderRadius: BorderRadius.circular(AppRadii.card),
//                 border: Border.all(color: AppColors.primary, width: 1.6),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.radio_button_checked_rounded,
//                     color: AppColors.primary,
//                   ),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Monthly Premium',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 15,
//                             color: AppColors.textPrimary,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           'Billed monthly · Cancel anytime',
//                           style: TextStyle(
//                             color: AppColors.textSecondary,
//                             fontSize: 12.5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Text(
//                     r'$4.99',
//                     style: TextStyle(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.w800,
//                       fontSize: 17,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 22),
//             ElevatedButton(
//               onPressed: () => _comingSoon(context),
//               child: const Text('Continue with Monthly Premium'),
//             ),
//             const SizedBox(height: 12),
//             Center(
//               child: TextButton(
//                 onPressed: () => _comingSoon(context),
//                 child: const Text('Restore Purchases'),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Subscription renews automatically unless cancelled at least 24 hours before the end of the current period. '
//               'You can manage or cancel it anytime from your account settings.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: AppColors.textTertiary,
//                 fontSize: 11.5,
//                 height: 1.4,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _Benefit extends StatelessWidget {
//   const _Benefit({required this.icon, required this.label});
//
//   final IconData icon;
//   final String label;
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 20, color: AppColors.primary),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             label,
//             style: TextStyle(
//               color: AppColors.textPrimary,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
