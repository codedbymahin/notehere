import 'package:flutter/material.dart';

/// Result returned by [showConfirmDialog].
enum ConfirmResult { stay, discard }

/// Shows the standard "Discard changes?" dialog used when the user tries
/// to leave a screen with unsaved input.
///
/// Returns [ConfirmResult.stay] when the user cancels the action, and
/// [ConfirmResult.discard] when they confirm they want to lose the
/// pending changes.
Future<ConfirmResult> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Discard',
  String cancelLabel = 'Stay',
}) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return result == true ? ConfirmResult.discard : ConfirmResult.stay;
}
