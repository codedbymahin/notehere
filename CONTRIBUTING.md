# Contributing to NoteHere

Thanks for your interest in improving NoteHere! This guide will help you get
a development environment up and running so you can submit a change.

## Code of conduct

By participating you agree to keep the community welcoming and respectful.

## Filing issues

- **Bug reports** — please use the *Bug report* issue template and include
  the Flutter version (`flutter --version`), the device / browser you saw
  the bug on, and the steps to reproduce it.
- **Feature requests** — open a *Feature request* ticket. Note that
  NoteHere is intentionally a small CRUD app; new features should stay
  beginner-friendly and not bloat the dependency footprint.

## Development setup

1. Install the [Flutter stable channel](https://docs.flutter.dev/get-started/install)
   (this project pins the Dart SDK to `^3.12.2`).
2. Clone your fork and run `flutter pub get`.
3. Configure Firebase for the platforms you want to develop on:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Enable Cloud Firestore in your Firebase project and apply permissive
   rules for development:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /notes/{noteId} {
         allow read, write: if true;
       }
     }
   }
   ```
5. Run the app with `flutter run -d chrome` (or another device).

## Workflow

1. Fork the repository and create a feature branch off `main`
   (`git checkout -b feat/my-improvement`).
2. Keep commits focused. Use [Conventional Commits](https://www.conventionalcommits.org/)
   prefixes (`feat:`, `fix:`, `chore:`, `docs:` …) so the changelog stays easy to curate.
3. Run the local checks before pushing:
   ```bash
   flutter analyze
   flutter test
   dart format lib/ test/
   ```
4. Open a pull request describing **what** changed and **why**. Screenshots
   or screen recordings are very welcome for UI changes.

## Style

- Two-space indent, single quotes, trailing commas when they improve diffs
  (matches `dart format` defaults).
- Public APIs are documented with `///` doc comments; private helpers can
  use `//` line comments where useful.
- Prefer small, composable widgets over deeply nested inline trees.

## Reviewing

Maintainers aim to respond to new pull requests within a few business days.
If you spot a typo or small issue, please open a PR rather than an issue —
it's faster for everyone.