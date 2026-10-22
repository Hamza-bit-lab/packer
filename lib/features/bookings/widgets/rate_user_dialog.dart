import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class RatingSubmission {
  RatingSubmission({required this.stars, required this.comment});

  final int stars;
  final String comment;
}

class RateUserDialog extends StatefulWidget {
  const RateUserDialog({super.key, required this.userName});

  final String userName;

  @override
  State<RateUserDialog> createState() => _RateUserDialogState();
}

class _RateUserDialogState extends State<RateUserDialog> {
  int _stars = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.userName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return IconButton(
                onPressed: () => setState(() => _stars = starIndex),
                icon: Icon(
                  starIndex <= _stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Comment (optional)'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(
            RatingSubmission(stars: _stars, comment: _commentController.text),
          ),
          child: const Text('Submit'),
        ),
      ],
      backgroundColor: AppColors.surface,
    );
  }
}
