// Go Premium is on hold for now — this whole file is commented out (not removed).
// To bring the feature back, uncomment this file and the matching lines in
// home_screen.dart and profile_screen.dart (search for "Go Premium").
//
// import 'package:flutter/material.dart';
//
// import '../../../core/theme/app_theme.dart';
// import '../screens/go_premium_screen.dart';
//
// /// Always-gold promo card pointing at [GoPremiumScreen] — shared between
// /// Settings and Home so the two entry points stay visually identical.
// class GoPremiumBanner extends StatelessWidget {
//   const GoPremiumBanner({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       borderRadius: BorderRadius.circular(AppRadii.card),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(AppRadii.card),
//         onTap: () => Navigator.of(
//           context,
//         ).push(MaterialPageRoute(builder: (_) => const GoPremiumScreen())),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             gradient: AppColors.heroGradient,
//             borderRadius: BorderRadius.circular(AppRadii.card),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(
//                   color: AppColors.onPrimary.withValues(alpha: 0.12),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.workspace_premium_rounded,
//                   color: AppColors.onPrimary,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Go Premium',
//                       style: TextStyle(
//                         color: AppColors.onPrimary,
//                         fontWeight: FontWeight.w800,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'Remove ads & unlock more features',
//                       style: TextStyle(
//                         color: AppColors.onPrimary.withValues(alpha: 0.75),
//                         fontSize: 12.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(Icons.chevron_right_rounded, color: AppColors.onPrimary),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
