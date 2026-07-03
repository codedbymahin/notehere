import 'package:flutter/material.dart';

/// A premium empty / error placeholder used in lieu of a notes list.
///
/// Shows a large circular illustration, a friendly title, a helpful
/// description, and an optional primary CTA. Sized to fill the
/// available space so it works well inside a `CustomScrollView`.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  /// Convenience constructor for the "no notes yet" empty state.
  const EmptyStateView.noNotes({super.key, this.onAction})
    : icon = Icons.menu_book_outlined,
      title = 'No notes yet',
      message = 'Capture your first thought and start building your '
          'private collection.',
      actionLabel = 'Create your first note',
      isError = false;

  /// Convenience constructor for the "no search results" state.
  const EmptyStateView.noResults({super.key, this.onAction})
    : icon = Icons.search_off_outlined,
      title = 'No matching notes',
      message = 'Try a different keyword or clear the search to see '
          'every note.',
      actionLabel = 'Clear search',
      isError = false;

  /// Convenience constructor for the "loading failed" state.
  const EmptyStateView.error({
    super.key,
    required this.message,
    this.onAction,
  }) : icon = Icons.cloud_off_outlined,
       title = "We couldn't reach your notes",
       actionLabel = 'Try again',
       isError = true;

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final accent = isError ? colorScheme.errorContainer : colorScheme.primaryContainer;
    final onAccent =
        isError ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 64, color: onAccent),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
