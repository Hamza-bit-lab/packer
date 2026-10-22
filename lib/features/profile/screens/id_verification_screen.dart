import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/api/id_verification_repository.dart';
import '../../../core/models/id_verification.dart';
import '../../../core/models/user.dart' show IdVerificationStatus;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/photo_picker_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/widgets/id_verified_badge.dart';

class IdVerificationScreen extends StatefulWidget {
  const IdVerificationScreen({super.key});

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  IdVerification? _latest;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  DocumentType _documentType = DocumentType.cnic;
  String? _pickedPhotoPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final repository = IdVerificationRepository(
        context.read<AuthProvider>().client,
      );
      _latest = await repository.fetchLatest();
    } catch (_) {
      // No submission yet or a transient error; the form still works.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked != null && mounted) setState(() => _pickedPhotoPath = picked.path);
  }

  Future<void> _submit() async {
    if (_pickedPhotoPath == null) {
      setState(() => _errorMessage = 'Please add a photo of your document.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = IdVerificationRepository(
        context.read<AuthProvider>().client,
      );
      _latest = await repository.submit(
        documentType: _documentType.apiValue,
        photoPath: _pickedPhotoPath!,
      );
      _pickedPhotoPath = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Submitted for review.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('ApiException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ID Verification')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    final status = _latest?.status ?? IdVerificationStatus.none;

    if (status == IdVerificationStatus.approved) {
      return Column(
        children: [
          const SizedBox(height: 40),
          const IdVerifiedBadge(size: 64),
          const SizedBox(height: 16),
          const Text(
            "You're ID Verified",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Other travelers and senders can see your ID Verified badge on your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ],
      );
    }

    if (status == IdVerificationStatus.pending) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.secondary,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'Your ${_latest!.documentType.label} is under review',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify you once it's been reviewed. This usually takes a day or two.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == IdVerificationStatus.rejected) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your last submission was rejected',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _latest?.rejectionReason ??
                      'Please try again with a clearer photo.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Verify your identity with a CNIC or passport to earn an ID Verified badge — this builds trust with other travelers and senders.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        const SizedBox(height: 20),
        SegmentedButton<DocumentType>(
          segments: const [
            ButtonSegment(value: DocumentType.cnic, label: Text('CNIC')),
            ButtonSegment(
              value: DocumentType.passport,
              label: Text('Passport'),
            ),
          ],
          selected: {_documentType},
          onSelectionChanged: (selection) =>
              setState(() => _documentType = selection.first),
        ),
        const SizedBox(height: 16),
        PhotoPickerField(
          pickedPath: _pickedPhotoPath,
          existingUrl: null,
          onPick: _pickPhoto,
          onClear: () => setState(() => _pickedPhotoPath = null),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text('Submit for Review'),
        ),
      ],
    );
  }
}
