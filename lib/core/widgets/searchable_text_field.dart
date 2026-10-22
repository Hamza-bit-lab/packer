import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Text field with async autocomplete; falls back to the typed text.
class SearchableTextField<T extends Object> extends StatefulWidget {
  const SearchableTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.initialValue,
    required this.onChanged,
    required this.loadOptions,
    required this.optionLabel,
    required this.matches,
    this.subtitleFor,
    this.validator,
    this.decoration,
    this.style,
  });

  final String label;
  final IconData icon;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final Future<List<T>> Function() loadOptions;
  final String Function(T option) optionLabel;
  final String? Function(T option)? subtitleFor;
  final bool Function(T option, String query) matches;
  final String? Function(String?)? validator;

  /// Replaces the default decoration, e.g. for the feed's search bar.
  final InputDecoration? decoration;
  final TextStyle? style;

  @override
  State<SearchableTextField<T>> createState() => _SearchableTextFieldState<T>();
}

class _SearchableTextFieldState<T extends Object>
    extends State<SearchableTextField<T>> {
  List<T> _options = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.loadOptions().then((options) {
      if (!mounted) return;
      setState(() {
        _options = options;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      initialValue: TextEditingValue(text: widget.initialValue ?? ''),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable.empty();

        // Shorter labels rank first (e.g. "London" before "Londonderry").
        final matched =
            _options.where((option) => widget.matches(option, query)).toList()
              ..sort(
                (a, b) => widget
                    .optionLabel(a)
                    .length
                    .compareTo(widget.optionLabel(b).length),
              );
        return matched.take(30);
      },
      displayStringForOption: widget.optionLabel,
      onSelected: (option) => widget.onChanged(widget.optionLabel(option)),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style:
              widget.style ??
              TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration:
              widget.decoration ??
              InputDecoration(
                labelText: widget.label,
                prefixIcon: Icon(
                  widget.icon,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
              ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, minWidth: 280),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final subtitle = widget.subtitleFor?.call(option);
                  return ListTile(
                    dense: true,
                    title: Text(
                      widget.optionLabel(option),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subtitle == null
                        ? null
                        : Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
