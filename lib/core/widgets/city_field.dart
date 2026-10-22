import 'package:flutter/material.dart';

import '../services/world_data_service.dart';
import 'searchable_text_field.dart';

/// Searchable city field; the value is a plain city name string.
class CityField extends StatelessWidget {
  const CityField({
    super.key,
    required this.label,
    required this.icon,
    required this.initialValue,
    required this.onChanged,
    this.validator,
    this.decoration,
    this.style,
  });

  final String label;
  final IconData icon;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  /// Replaces the default decoration, e.g. for the feed's search bar.
  final InputDecoration? decoration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SearchableTextField<CityEntry>(
      label: label,
      icon: icon,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      decoration: decoration,
      style: style,
      loadOptions: WorldDataService.instance.loadCities,
      optionLabel: (option) => option.city,
      subtitleFor: (option) => option.country,
      matches: (option, query) =>
          option.city.toLowerCase().startsWith(query.toLowerCase()),
    );
  }
}
