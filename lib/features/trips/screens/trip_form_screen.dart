import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/api/trip_repository.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/models/trip.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/city_field.dart';
import '../../../core/widgets/form_section_card.dart';
import '../../../core/widgets/photo_picker_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/auth_dropdown_field.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../legal/safety_disclaimer.dart';

class TripFormScreen extends StatefulWidget {
  const TripFormScreen({super.key, this.trip});

  final Trip? trip;

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fromCity = '';
  String _toCity = '';
  late final TextEditingController _airlineController;
  late final TextEditingController _maxWeightController;
  late final TextEditingController _rateController;
  late final TextEditingController _departureController;
  late DateTime? _departureDateTime;
  late String? _currency;
  late DeliveryMethod _deliveryMethod;
  late PickupMethod _pickupMethod;
  String? _pickedPhotoPath;

  // Traveler's point of view; mirrors GoodFormScreen labels.
  static const _pickupMethodLabels = {
    PickupMethod.travelerPicksUp: "I'll pick it up myself",
    PickupMethod.senderDelivers: 'Sender delivers it to me',
  };

  // First-person wording, unlike DeliveryMethod.label used on feed cards.
  static const _deliveryMethodLabels = {
    DeliveryMethod.receiverPickup: 'Receiver will collect',
    DeliveryMethod.travelerDelivers: 'I will dispatch to receiver',
  };

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _fromCity = trip?.fromCity ?? '';
    _toCity = trip?.toCity ?? '';
    _airlineController = TextEditingController(text: trip?.airlineName ?? '');
    _maxWeightController = TextEditingController(
      text: trip != null ? trip.maxWeightKg.toString() : '',
    );
    _rateController = TextEditingController(
      text: trip != null ? trip.ratePerKg.toString() : '',
    );
    _departureDateTime = trip?.departureDateTime;
    _departureController = TextEditingController(
      text: _formatDateTime(_departureDateTime),
    );
    // New trip defaults to the preferred currency; editing keeps its own.
    _currency =
        trip?.currencyType ?? context.read<PreferencesProvider>().currency;
    _deliveryMethod = trip?.deliveryMethod ?? DeliveryMethod.receiverPickup;
    _pickupMethod = trip?.pickupMethod ?? PickupMethod.travelerPicksUp;
  }

  @override
  void dispose() {
    _airlineController.dispose();
    _maxWeightController.dispose();
    _rateController.dispose();
    _departureController.dispose();
    super.dispose();
  }

  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDateTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureDateTime ?? now),
    );
    if (time == null) return;

    if (!mounted) return;
    setState(() {
      _departureDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _departureController.text = _formatDateTime(_departureDateTime);
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null && mounted) setState(() => _pickedPhotoPath = picked.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromCity.trim().isEmpty || _toCity.trim().isEmpty) {
      setState(() => _errorMessage = 'Please pick a from and to city.');
      return;
    }
    if (_departureDateTime == null) {
      setState(() => _errorMessage = 'Please pick a departure date & time.');
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
      final repository = TripRepository(context.read<AuthProvider>().client);
      final maxWeight = double.parse(_maxWeightController.text);
      final rate = double.parse(_rateController.text);

      final Trip saved;
      if (_isEditing) {
        saved = await repository.update(
          widget.trip!.id,
          fromCity: _fromCity.trim(),
          toCity: _toCity.trim(),
          departureDateTime: _departureDateTime,
          airlineName: _airlineController.text.trim(),
          maxWeightKg: maxWeight,
          ratePerKg: rate,
          currencyType: _currency,
          deliveryMethod: _deliveryMethod,
          pickupMethod: _pickupMethod,
          photoPath: _pickedPhotoPath,
        );
      } else {
        saved = await repository.create(
          fromCity: _fromCity.trim(),
          toCity: _toCity.trim(),
          departureDateTime: _departureDateTime!,
          airlineName: _airlineController.text.trim(),
          maxWeightKg: maxWeight,
          ratePerKg: rate,
          currencyType: _currency!,
          deliveryMethod: _deliveryMethod,
          pickupMethod: _pickupMethod,
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Trip' : 'Post a Trip')),
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
                        existingUrl: widget.trip?.photoUrl,
                        onPick: _pickPhoto,
                        onClear: () => setState(() => _pickedPhotoPath = null),
                      ),
                      const SizedBox(height: 16),
                      FormSectionCard(
                        title: 'ROUTE',
                        children: [
                          CityField(
                            label: 'From city',
                            icon: Icons.flight_takeoff_rounded,
                            initialValue: _fromCity,
                            onChanged: (value) => _fromCity = value,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          CityField(
                            label: 'To city',
                            icon: Icons.flight_land_rounded,
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
                        title: 'FLIGHT & CAPACITY',
                        children: [
                          AuthTextField(
                            label: 'Departure date & time',
                            icon: Icons.calendar_today_outlined,
                            controller: _departureController,
                            readOnly: true,
                            onTap: _pickDateTime,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please pick a date & time'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            label: 'Airline name',
                            icon: Icons.airlines_outlined,
                            controller: _airlineController,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            label: 'Max weight available (kg)',
                            icon: Icons.scale_outlined,
                            controller: _maxWeightController,
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
                        title: 'PRICING',
                        children: [
                          AuthTextField(
                            label: 'Rate per kg',
                            icon: Icons.payments_outlined,
                            controller: _rateController,
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
                                'Pickup at ${_fromCity.isEmpty ? 'origin' : _fromCity}',
                            icon: Icons.luggage_outlined,
                            value: _pickupMethodLabels[_pickupMethod],
                            items: _pickupMethodLabels.values.toList(),
                            onChanged: (label) => setState(() {
                              _pickupMethod = _pickupMethodLabels.entries
                                  .firstWhere((e) => e.value == label)
                                  .key;
                            }),
                          ),
                          const SizedBox(height: 14),
                          AuthDropdownField(
                            label:
                                'Delivery at ${_toCity.isEmpty ? 'destination' : _toCity}',
                            icon: Icons.local_shipping_outlined,
                            value: _deliveryMethodLabels[_deliveryMethod],
                            items: _deliveryMethodLabels.values.toList(),
                            onChanged: (label) => setState(() {
                              _deliveryMethod = _deliveryMethodLabels.entries
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
                          style: TextStyle(color: AppColors.error, fontSize: 13),
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
            : Text(_isEditing ? 'Save Changes' : 'Post Trip'),
      ),
    );
  }
}
