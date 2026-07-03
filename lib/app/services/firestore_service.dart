import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';

/// Thin wrapper around Cloud Firestore for the notes collection.
///
/// The rest of the app talks to Firestore exclusively through this
/// class so that the persistence layer is easy to swap or mock.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Firestore collection that stores notes.
  static const String notesCollection = 'notes';

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _firestore.collection(notesCollection);

  /// Real-time stream of every note, newest first.
  ///
  /// The UI subscribes to this so the list updates automatically
  /// whenever a note is added, edited or deleted.
  Stream<List<Note>> notesStream() {
    return _notesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Note.fromFirestore).toList());
  }

  /// One-shot fetch of all notes (used by tests and one-off reads).
  Future<List<Note>> getNotes() async {
    final snapshot = await _notesRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(Note.fromFirestore).toList();
  }

  /// Fetches a single note by id, or `null` if it doesn't exist.
  Future<Note?> getNote(String id) async {
    if (id.isEmpty) return null;
    final doc = await _notesRef.doc(id).get();
    if (!doc.exists) return null;
    return Note.fromFirestore(doc);
  }

  /// Creates a new note document and returns the persisted [Note].
  Future<Note> createNote(Note note) async {
    final docRef = await _notesRef.add(note.toFirestore());
    return note.copyWith(id: docRef.id);
  }

  /// Updates an existing note document identified by [note.id].
  Future<void> updateNote(Note note) async {
    if (note.id.isEmpty) {
      throw ArgumentError('Cannot update a note without an id.');
    }
    await _notesRef.doc(note.id).update(note.toFirestore());
  }

  /// Deletes the note document identified by [id].
  Future<void> deleteNote(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('Cannot delete a note without an id.');
    }
    await _notesRef.doc(id).delete();
  }
}
