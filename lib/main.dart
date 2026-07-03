import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/providers/note_provider.dart';
import 'app/routes/app_routes.dart';
import 'app/screens/add_edit_note_screen.dart';
import 'app/screens/notes_list_screen.dart';
import 'app/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NoteHereApp());
}

/// Root widget. Owns the [MultiProvider] that injects the app-level
/// state into the widget tree and configures routing + theming.
class NoteHereApp extends StatelessWidget {
  const NoteHereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NoteProvider>(create: (_) => NoteProvider()),
      ],
      child: MaterialApp(
        title: 'NoteHere',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.notesList,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.notesList:
        return _buildRoute(const NotesListScreen(), settings);
      case AppRoutes.addEditNote:
        final noteId = _extractNoteId(settings.arguments);
        return _buildRoute(AddEditNoteScreen(noteId: noteId), settings);
    }
    return null;
  }

  Route<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }

  /// Extracts the optional note id from route arguments. Accepts either
  /// a `Map<String, dynamic>` (when the caller uses `pushNamed` with
  /// `arguments: {'id': ...}`) or a plain string such as `'/note?id=abc'`.
  String? _extractNoteId(Object? arguments) {
    if (arguments is Map) {
      final id = arguments['id'];
      if (id is String && id.isNotEmpty) return id;
    }
    if (arguments is String && arguments.startsWith('/note')) {
      return Uri.tryParse(arguments)?.queryParameters['id'];
    }
    return null;
  }
}
