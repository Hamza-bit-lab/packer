import 'package:url_launcher/url_launcher.dart';

Future<void> callPhoneNumber(String phoneNumber) async {
  await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
}

Future<void> openWhatsAppChat(String phoneNumber, {String? message}) async {
  final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = Uri.https(
    'wa.me',
    '/$digitsOnly',
    message != null ? {'text': message} : null,
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
