import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/booking_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/otp_box_field.dart';

/// What [confirmDelivery] collects before a booking can be marked complete.
class DeliveryConfirmation {
  DeliveryConfirmation({required this.otp, required this.photoPath});

  final String otp;
  final String photoPath;
}

/// Runs the full delivery-confirmation flow: the existing safety reminder,
/// then emails a code to the receiver, asks the traveler to enter it, and
/// finally captures a proof photo. Returns null if cancelled at any step.
Future<DeliveryConfirmation?> confirmDelivery(
  BuildContext context, {
  required BookingRepository repository,
  required int bookingId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm delivery'),
      content: const Text(
        'Before marking this as delivered, make sure the sender has had the chance to inspect the contents in person. '
        "We'll email the receiver a code — you'll need it, plus a photo as proof of delivery. Continue?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return null;

  try {
    await repository.sendDeliveryOtp(bookingId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return null;
  }

  if (!context.mounted) return null;
  final otp = await showDialog<String>(
    context: context,
    builder: (context) =>
        _OtpEntryDialog(repository: repository, bookingId: bookingId),
  );
  if (otp == null || !context.mounted) return null;

  final XFile? photo;
  try {
    photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the camera: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return null;
  }
  if (photo == null) return null;

  return DeliveryConfirmation(otp: otp, photoPath: photo.path);
}

/// Asks the traveler for the 6-digit code the receiver got by email, with a
/// resend option — the receiver has no app of their own to read it from.
class _OtpEntryDialog extends StatefulWidget {
  const _OtpEntryDialog({required this.repository, required this.bookingId});

  final BookingRepository repository;
  final int bookingId;

  @override
  State<_OtpEntryDialog> createState() => _OtpEntryDialogState();
}

class _OtpEntryDialogState extends State<_OtpEntryDialog> {
  final _controller = TextEditingController();
  bool _isResending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await widget.repository.sendDeliveryOtp(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been emailed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _controller.text.trim().length == 6;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the delivery code',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text(
                "We've emailed a 6-digit code to the receiver. Ask them for it once you've handed the item over.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              OtpBoxField(
                controller: _controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) {
                  if (value.trim().length == 6) {
                    Navigator.of(context).pop(value.trim());
                  }
                },
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _isResending ? null : _resend,
                child: _isResending
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text('Resend code'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isComplete
                      ? () => Navigator.of(context).pop(_controller.text.trim())
                      : null,
                  child: const Text('Confirm'),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
