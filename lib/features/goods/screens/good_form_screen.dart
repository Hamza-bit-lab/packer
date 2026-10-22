import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/api/good_repository.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/models/good.dart';
import '../../../core/models/trip.dart' show PickupMethod;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/city_field.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/photo_picker_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/auth_dropdown_field.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../legal/safety_disclaimer.dart';

class GoodFormScreen extends StatefulWidget {
  const GoodFormScreen({
    super.key,
    this.good,
    this.initialFromCity,
    this.initialToCity,
    this.submitLabel,
  });

  final Good? good;

  /// Prefills the route when posting a brand-new item (ignored when editing).
  final String? initialFromCity;
  final String? initialToCity;

  /// Overrides the submit button label.
  final String? submitLabel;

  @override
  State<GoodFormScreen> createState() => _GoodFormScreenState();
}

class _GoodFormScreenState extends State<GoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fromCity = '';
  String _toCity = '';
  late final TextEditingController _descriptionController;
  late final TextEditingController _receiverEmailController;
  late final TextEditingController _weightController;
  late final TextEditingController _rewardController;
  late String? _currency;
  late PickupMethod _pickupPreference;
  String? _pickedPhotoPath;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.good != null;

  // Sender's point of view; mirrors TripFormScreen labels.
  static const _pickupPreferenceLabels = {
    PickupMethod.senderDelivers: "I'll deliver it to the traveler",
    PickupMethod.travelerPicksUp: 'Traveler picks it up from me',
  };

  @override
  void initState() {
    super.initState();
    final good = widget.good;
    _fromCity = good?.fromCity ?? widget.initialFromCity ?? '';
    _toCity = good?.toCity ?? widget.initialToCity ?? '';
    _descriptionController = TextEditingController(
      text: good?.itemDescription ?? '',
    );
    _receiverEmailController = TextEditingController(
      text: good?.receiverEmail ?? '',
    );
    _weightController = TextEditingController(
      text: good != null ? good.weightKg.toString() : '',
    );
    _rewardController = TextEditingController(
      text: good != null ? good.offeredReward.toString() : '',
    );
    _currency = good?.currencyType;
    _pickupPreference = good?.pickupPreference ?? PickupMethod.senderDelivers;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _receiverEmailController.dispose();
    _weightController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null && mounted)
      setState(() => _pickedPhotoPath = picked.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromCity.trim().isEmpty || _toCity.trim().isEmpty) {
      setState(() => _errorMessage = 'Please pick a from and to city.');
      return;
    }
    if (_currency == null) {
      setState(() => _errorMessage = 'Please select a currency.');
      return;
    }

    // Posting a new listing needs the user's explicit agreement.
    if (!_isEditing) {
      final agreed = await SafetyDisclaimerDialog.confirm(context);
      if (!agreed || !mounted) return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = GoodRepository(context.read<AuthProvider>().client);
      final weight = double.parse(_weightController.text);
      final reward = double.parse(_rewardController.text);

      final Good saved;
      if (_isEditing) {
        saved = await repository.update(
          widget.good!.id,
          fromCity: _fromCity.trim(),
          toCity: _toCity.trim(),
          itemDescription: _descriptionController.text.trim(),
          receiverEmail: _receiverEmailController.text.trim(),
          weightKg: weight,
          offeredReward: reward,
          currencyType: _currency,
          pickupPreference: _pickupPreference,
          photoPath: _pickedPhotoPath,
        );
      } else {
        saved = await repository.create(
          fromCity: _fromCity.trim(),
          toCity: _toCity.trim(),
          itemDescription: _descriptionController.text.trim(),
          receiverEmail: _receiverEmailController.text.trim(),
          weightKg: weight,
          offeredReward: reward,
          currencyType: _currency!,
          pickupPreference: _pickupPreference,
          termsAccepted: true,
          photoPath: _pickedPhotoPath,
        );
      }

      if (mounted) Navigator.of(context).pop(saved);
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Item' : 'Post an Item')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PhotoPickerField(
                        pickedPath: _pickedPhotoPath,
                        existingUrl: widget.good?.photoUrl,
                        onPick: _pickPhoto,
                        onClear: () => setState(() => _pickedPhotoPath = null),
                      ),
                      const SizedBox(height: 16),
                      FormSectionCard(
                        title: 'ROUTE',
                        children: [
                          CityField(
                            label: 'From city',
                            icon: Icons.location_on_outlined,
                            initialValue: _fromCity,
                            onChanged: (value) => _fromCity = value,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          CityField(
                            label: 'To city',
                            icon: Icons.location_on_rounded,
                            initialValue: _toCity,
                            onChanged: (value) => _toCity = value,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FormSectionCard(
                        title: 'ITEM DETAILS',
                        children: [
                          AuthTextField(
                            label: 'What are you sending?',
                            icon: Icons.inventory_2_outlined,
                            controller: _descriptionController,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            label: 'Weight (kg)',
                            icon: Icons.scale_outlined,
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) => (double.tryParse(v ?? '') == null)
                                ? 'Enter a valid number'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FormSectionCard(
                        title: 'RECEIVER',
                        children: [
                          Text(
                            "Who's getting this at the other end? We'll email "
                            'them a confirmation code when the traveler marks '
                            'it delivered — they read it back to confirm, no '
                            'app needed on their side.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            label: "Receiver's email",
                            icon: Icons.alternate_email_rounded,
                            controller: _receiverEmailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Required';
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FormSectionCard(
                        title: 'REWARD',
                        children: [
                          AuthTextField(
                            label: 'Reward offered',
                            icon: Icons.card_giftcard_outlined,
                            controller: _rewardController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) => (double.tryParse(v ?? '') == null)
                                ? 'Enter a valid number'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AuthDropdownField(
                            label: 'Currency',
                            icon: Icons.attach_money_rounded,
                            value: _currency,
                            items: kCurrencies,
                            onChanged: (value) =>
                                setState(() => _currency = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FormSectionCard(
                        title: 'HANDOFF',
                        children: [
                          AuthDropdownField(
                            label:
                                'Handover at ${_fromCity.isEmpty ? 'origin' : _fromCity}',
                            icon: Icons.handshake_outlined,
                            value: _pickupPreferenceLabels[_pickupPreference],
                            items: _pickupPreferenceLabels.values.toList(),
                            onChanged: (label) => setState(() {
                              _pickupPreference = _pickupPreferenceLabels
                                  .entries
                                  .firstWhere((e) => e.value == label)
                                  .key;
                            }),
                          ),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _buildSubmitBar(),
          ],
        ),
      ),
    );
  }

  /// Fixed bottom bar for the submit button — gives this pushed form the
  /// same bottom-anchored weight as the tabbed screens, instead of a button
  /// that just scrolls away with the rest of the content.
  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ElevatedButton(
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
            : Text(
                widget.submitLabel ??
                    (_isEditing ? 'Save Changes' : 'Post Item'),
              ),
      ),
    );
  }
}
