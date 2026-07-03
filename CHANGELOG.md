# Changelog

All notable changes to this project will be documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- Trimmed `pubspec.yaml` to remove unused dependencies and Flutter scaffold comments.
- Expanded `.gitignore` to cover IDE / editor artefacts and platform build outputs.
- Added `.editorconfig` for consistent formatting across editors.
- Rewrote `README.md` for first-time contributors.

## [1.0.0] - 2026-07-03

### Added
- Full CRUD notes backed by Cloud Firestore (`FirestoreService` + `NoteProvider`).
- Real-time updates via `Stream<List<Note>>` subscription.
- Notes list screen with search, sort (newest / oldest), empty states and undo delete.
- Add / Edit screen with character counters, friendly validation and autofocus.
- Light + dark Material 3 theme seeded from indigo.
- Responsive layout that adapts from phones to tablets / desktop web.
- Tests for the shared UI primitives (`AppButton`, `AppTextField`, `AppLoadingIndicator`).

### Notes
- `lib/firebase_options.dart` ships with placeholder values — regenerate it
  for your own Firebase project via `flutterfire configure`.