/// Named route constants used by [MaterialApp] and `Navigator.pushNamed`.
///
/// The Add / Edit screen receives the note id via the route arguments:
/// `Navigator.of(context).pushNamed(AppRoutes.addEditNote, arguments: {'id': noteId})`.
abstract class AppRoutes {
  AppRoutes._();

  /// Landing screen — also the app's initial route.
  static const String notesList = '/';

  /// Add a new note, or edit an existing one when `arguments['id']` is set.
  static const String addEditNote = '/note';
}
