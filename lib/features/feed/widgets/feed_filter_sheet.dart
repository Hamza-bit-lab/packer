import 'package:flutter/material.dart';

import '../../../core/api/feed_repository.dart';
import '../../../core/theme/app_theme.dart';

const _baseSortOptions = {
  null: 'Newest first',
  'price_low': 'Price: low to high',
  'price_high': 'Price: high to low',
  'rating': 'Highest rated',
};

/// Bottom sheet for date/weight range and sort; returns [FeedFilters] or null.
class FeedFilterSheet extends StatefulWidget {
  const FeedFilterSheet({
    super.key,
    required this.filters,
    required this.showDateRange,
  });

  final FeedFilters filters;

  /// Traveler-only options: date range and experience sort.
  final bool showDateRange;

  @override
  State<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<FeedFilterSheet> {
  late DateTime? _dateFrom = widget.filters.dateFrom;
  late DateTime? _dateTo = widget.filters.dateTo;
  late final _minWeightController = TextEditingController(
    text: widget.filters.minWeight?.toStringAsFixed(0) ?? '',
  );
  late final _maxWeightController = TextEditingController(
    text: widget.filters.maxWeight?.toStringAsFixed(0) ?? '',
  );
  late String? _sort = widget.filters.sort;

  @override
  void dispose() {
    _minWeightController.dispose();
    _maxWeightController.dispose();
    super.dispose();
  }

  Future<void> _pickDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _dateFrom = picked);
  }

  Future<void> _pickDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? _dateFrom ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _dateTo = picked);
  }

  void _apply() {
    Navigator.of(context).pop(
      FeedFilters(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        minWeight: double.tryParse(_minWeightController.text),
        maxWeight: double.tryParse(_maxWeightController.text),
        sort: _sort,
      ),
    );
  }

  void _clear() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _minWeightController.clear();
      _maxWeightController.clear();
      _sort = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filter & Sort',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 18),
            if (widget.showDateRange) ...[
              Text(
                'Departure date range',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DateChip(
                      label: _dateFrom == null
                          ? 'From'
                          : _formatDate(_dateFrom!),
                      onTap: _pickDateFrom,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateChip(
                      label: _dateTo == null ? 'To' : _formatDate(_dateTo!),
                      onTap: _pickDateTo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            Text(
              'Weight range (kg)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Min',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Max',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Sort by',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _sort,
              items:
                  {
                        ..._baseSortOptions,
                        if (widget.showDateRange)
                          'experience': 'Most experienced traveler',
                      }.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _sort = value),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: const Text('Clear all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 15),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
