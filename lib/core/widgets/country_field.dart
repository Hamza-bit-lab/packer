import 'package:flutter/material.dart';

import '../services/world_data_service.dart';
import 'searchable_text_field.dart';

/// Searchable country field backed by the world countries list.
class CountryField extends StatelessWidget {
  const CountryField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return SearchableTextField<String>(
      label: 'Country',
      icon: Icons.public_rounded,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      loadOptions: WorldDataService.instance.loadCountries,
      optionLabel: (option) => option,
      matches: (option, query) =>
          option.toLowerCase().startsWith(query.toLowerCase()),
    );
  }
}
