import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/firestore_service.dart';

/// Application-level state for notes.
///
/// Subscribes to the live Firestore stream so the list reflects
/// additions, edits and deletions in real time, and exposes simple
/// CRUD methods that screens can invoke.
class NoteProvider extends ChangeNotifier {
  NoteProvider({FirestoreService? service})
    : _service = service ?? FirestoreService() {
    _subscribe();
  }

  final FirestoreService _service;
  StreamSubscription<List<Note>>? _subscription;

  List<Note> _notes = <Note>[];
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastActionMessage;

  /// Currently loaded notes (newest first). Returns an unmodifiable view.
  List<Note> get notes => List.unmodifiable(_notes);

  /// True while the initial Firestore snapshot has not arrived.
  bool get isLoading => _isLoading;

  /// Last error message produced by the provider, if any.
  String? get errorMessage => _errorMessage;

  /// Optional one-shot message emitted after a CRUD action finishes.
  String? get lastActionMessage => _lastActionMessage;

  /// Fetches a single note from the local cache first, then falls back
  /// to a Firestore read so the edit screen always has fresh data.
  Future<Note?> getNote(String id) async {
    final cached = _notes
        .where((note) => note.id == id)
        .cast<Note?>()
        .firstWhere((_) => true, orElse: () => null);
    if (cached != null) return cached;
    return _service.getNote(id);
  }

  /// Creates a new note via the underlying service.
  ///
  /// Returns the created [Note] or throws so the UI can surface the error.
  Future<Note> createNote({
    required String title,
    required String description,
  }) async {
    try {
      final draft = Note.newDraft(title: title, description: description);
      final created = await _service.createNote(draft);
      _lastActionMessage = 'Note created.';
      _errorMessage = null;
      return created;
    } catch (error) {
      _errorMessage = _describe(error);
      rethrow;
    }
  }

  /// Updates an existing note and lets the real-time listener refresh
  /// the local cache.
  Future<void> updateNote(Note note) async {
    try {
      await _service.updateNote(note);
      _lastActionMessage = 'Note updated.';
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _describe(error);
      rethrow;
    }
  }

  /// Deletes a note by id.
  Future<void> deleteNote(String id) async {
    try {
      await _service.deleteNote(id);
      _lastActionMessage = 'Note deleted successfully.';
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _describe(error);
      rethrow;
    }
  }

  /// Clears the optional action message after the UI displays it.
  void clearLastActionMessage() {
    if (_lastActionMessage == null) return;
    _lastActionMessage = null;
    notifyListeners();
  }

  /// Clears the current error after the UI displays it.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _subscribe() {
    _subscription = _service.notesStream().listen(
      (notes) {
        _notes = notes;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = _describe(error);
        notifyListeners();
      },
    );
  }

  /// Translates a thrown error into a user-friendly message.
  static String _describe(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'A Firestore error occurred.';
    }
    return error.toString();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
