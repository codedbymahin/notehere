import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single note stored in Firestore.
///
/// Used by the service and provider layers to exchange note data
/// between Firestore and the UI.
class Note {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convenience constructor for creating a brand-new note that has not
  /// been persisted yet. The id is generated locally; [createdAt] and
  /// [updatedAt] are set to the current time.
  factory Note.newDraft({required String title, required String description}) {
    final now = DateTime.now();
    return Note(
      id: '',
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Returns a copy of this note with the provided fields replaced.
  /// Passing `clearUpdatedAt: true` removes the timestamp entirely.
  Note copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    );
  }

  /// Creates a [Note] from a Firestore document snapshot.
  factory Note.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = _readTimestamp(data['createdAt']);
    final rawUpdated = data['updatedAt'];
    final updatedAt = rawUpdated == null ? null : _readTimestamp(rawUpdated);
    return Note(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Builds a Firestore-friendly map for saving this note.
  ///
  /// The `id` is intentionally excluded because it is the document id.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  static DateTime _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
