import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/firestore_service.dart';

/// Sort order applied on top of the live Firestore list.
enum NoteSortOrder { newestFirst, oldestFirst }

/// Application-level state for notes.
///
/// Subscribes to the live Firestore stream so the list reflects
/// additions, edits and deletions in real time, and exposes simple
/// CRUD methods that screens can invoke. Search and sort are applied
/// lazily on top of the underlying list — no duplicate storage.
class NoteProvider extends ChangeNotifier {
  NoteProvider({FirestoreService? service})
    : _service = service ?? FirestoreService() {
    _subscribe();
  }

  /// Debounce window applied to search updates. Keeps the typing
  /// experience smooth while still feeling instantaneous.
  static const Duration _searchDebounce = Duration(milliseconds: 280);

  final FirestoreService _service;
  StreamSubscription<List<Note>>? _subscription;
  Timer? _searchDebounceTimer;

  List<Note> _notes = <Note>[];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  NoteSortOrder _sortOrder = NoteSortOrder.newestFirst;

  /// Currently loaded notes (newest first). Returns an unmodifiable view.
  List<Note> get notes => List.unmodifiable(_notes);

  /// Notes filtered by the active search query and reordered by the
  /// active sort order. Recomputed on every read so the list always
  /// reflects the latest Firestore snapshot.
  List<Note> get visibleNotes {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<Note>.from(_notes)
        : _notes
              .where(
                (note) =>
                    note.title.toLowerCase().contains(query) ||
                    note.description.toLowerCase().contains(query),
              )
              .toList();
    filtered.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return _sortOrder == NoteSortOrder.newestFirst ? -cmp : cmp;
    });
    return List.unmodifiable(filtered);
  }

  String get searchQuery => _searchQuery;
  NoteSortOrder get sortOrder => _sortOrder;

  /// True while the initial Firestore snapshot has not arrived.
  bool get isLoading => _isLoading;

  /// Last error message produced by the provider, if any.
  String? get errorMessage => _errorMessage;

  /// Updates the active search query.
  ///
  /// The value is committed after a short debounce window so rapid
  /// keystrokes do not trigger a list rebuild per character. The
  /// pending update is cancelled if the user keeps typing.
  void setSearchQuery(String value) {
    if (value == _searchQuery && _searchDebounceTimer == null) return;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      _searchQuery = value;
      notifyListeners();
    });
  }

  /// Updates the active sort order.
  void setSortOrder(NoteSortOrder order) {
    if (order == _sortOrder) return;
    _sortOrder = order;
    notifyListeners();
  }

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
      final stamped = note.copyWith(updatedAt: DateTime.now());
      await _service.updateNote(stamped);
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
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _describe(error);
      rethrow;
    }
  }

  /// Re-creates a previously deleted note (used by the Undo Snackbar).
  /// The original id is intentionally dropped — Firestore will mint a
  /// new one and the resulting note keeps the same content.
  Future<void> restoreNote(Note note) async {
    try {
      final draft = Note.newDraft(
        title: note.title,
        description: note.description,
      );
      await _service.createNote(draft);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _describe(error);
      rethrow;
    }
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
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to do that.';
        case 'not-found':
          return 'We could not find that note.';
        case 'unavailable':
        case 'network-request-failed':
          return 'You appear to be offline. Check your connection and try again.';
        case 'deadline-exceeded':
          return 'The request took too long. Please try again.';
        case 'cancelled':
          return 'The operation was cancelled.';
        case 'already-exists':
          return 'This note already exists.';
      }
      return error.message ?? 'Something went wrong. Please try again.';
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid input.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
