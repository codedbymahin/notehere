/// Lightweight, package-free date formatting helpers shared across the UI.
///
/// Kept intentionally tiny so the app stays free of `package:intl` and
/// other transitive dependencies — most of what a notes app shows is
/// only ever "Today", "Yesterday", or "MMM d, yyyy".
class DateFormatter {
  DateFormatter._();

  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Returns `Today` / `Yesterday` / `MMM d, yyyy` (e.g. `Jul 3, 2026`).
  static String relativeDay(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return absolute(local);
  }

  /// Formats a date as `MMM d, yyyy`, e.g. `Jul 3, 2026`.
  static String absolute(DateTime date) {
    final local = date.toLocal();
    final month = _monthNames[local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }

  /// Formats a date as `MMM d, yyyy · HH:mm` for richer contexts
  /// like the create/update footer of a note card.
  static String full(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${absolute(local)} · $hour:$minute';
  }
}
