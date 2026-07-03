# Changelog

All notable changes to this project will be documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed
- Major UI / UX redesign inspired by modern notes apps (Apple Notes / Google Keep / Notion tier):
  - New greeting-based home header with three stat tiles (Total Notes / Last Updated / Today).
  - Note cards now use a single overflow menu (more_vert) instead of inline icon buttons.
  - Two-line date footer (Created / Updated) using friendly "Today / Yesterday / Monday / Jul 3" labels.
  - Larger title, muted description preview, subtle outlined card.
- New `CenteredMaxWidth` layout primitive caps content at 880px on desktop / tablet.
- New convenience constructors on `EmptyStateView` (`noNotes`, `noResults`, `error`) with a 132px illustration halo and full-width primary CTA.
- Theme rebuilt around a deeper Material 3 surface palette; explicit light + dark mode depth; richer typography scale and component themes (cards, dialogs, snackbars, popup menus, inputs, buttons).
- `DateFormatter` extended with `weekdayLong`, `weekdayShort` and `greetingFor` helpers.
- `AddEditNoteScreen` gets a hero title block, 64px-tall save button and an inline delete action when editing.
- Modernised delete dialog copy ("This action cannot be undone.").

### Technical
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