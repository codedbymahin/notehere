/// Package-free date formatting helpers.
///
/// We deliberately avoid the `intl` package to keep the dependency
/// tree small. All helpers work in the device's local time zone and
/// use a single set of English month / weekday names.
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

  static const List<String> _weekdayLong = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Returns a human-friendly date label.
  ///
  /// * Today → `Today`
  /// * Yesterday → `Yesterday`
  /// * Earlier this week → weekday name, e.g. `Monday`
  /// * Same calendar year → `Jul 3`
  /// * Different year → `Jul 3, 2024`
  static String relativeDay(DateTime when) {
    final now = DateTime.now();
    final date = when.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    if (diff > 1 && diff < 7) {
      return _weekdayLong[date.weekday - 1];
    }

    if (date.year == today.year) {
      return '${_monthNames[date.month - 1]} ${date.day}';
    }

    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Long weekday name, e.g. `Monday`.
  static String weekdayLong(DateTime when) {
    final date = when.toLocal();
    return _weekdayLong[date.weekday - 1];
  }

  /// Absolute date — `Jul 3, 2024`.
  static String absolute(DateTime when) {
    final date = when.toLocal();
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Returns a greeting appropriate for the local time of day.
  ///
  /// * 05:00–11:59 → `Good morning`
  /// * 12:00–16:59 → `Good afternoon`
  /// * 17:00–21:59 → `Good evening`
  /// * otherwise   → `Welcome back`
  static String greetingFor([DateTime? at]) {
    final hour = (at ?? DateTime.now()).toLocal().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 22) return 'Good evening';
    return 'Welcome back';
  }
}
