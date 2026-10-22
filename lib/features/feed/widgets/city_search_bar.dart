import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/city_field.dart';

class CitySearchBar extends StatelessWidget {
  const CitySearchBar({
    super.key,
    required this.initialFromCity,
    required this.initialToCity,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSearch,
  });

  final String initialFromCity;
  final String initialToCity;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;
  final VoidCallback onSearch;

  static const _decoration = InputDecoration(
    isDense: true,
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          Expanded(
            child: CityField(
              label: 'From city',
              icon: Icons.flight_takeoff_rounded,
              initialValue: initialFromCity,
              onChanged: onFromChanged,
              decoration: _decoration.copyWith(hintText: 'From city'),
              style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.border.withValues(alpha: 0.6),
          ),
          Expanded(
            child: CityField(
              label: 'To city',
              icon: Icons.flight_land_rounded,
              initialValue: initialToCity,
              onChanged: onToChanged,
              decoration: _decoration.copyWith(hintText: 'To city'),
              style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: IconButton.filled(
              onPressed: onSearch,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(40, 40),
              ),
              icon: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
