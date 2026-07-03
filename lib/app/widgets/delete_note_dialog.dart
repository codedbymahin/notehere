import 'package:flutter/material.dart';

/// Shows the destructive confirmation dialog used before deleting a note.
///
/// Returns `true` when the user confirms the deletion, `false` (or `null`)
/// otherwise.
Future<bool> showDeleteNoteDialog(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete note?'),
      content: const Text(
        'This note will be removed from your collection. '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}
