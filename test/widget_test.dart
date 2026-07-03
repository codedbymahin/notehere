// Smoke tests for the NoteHere foundation.
//
// These tests verify the building blocks of the app without booting the
// real Firebase backend. End-to-end behaviour is exercised with a real
// Firebase project via `flutter run`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:note_here/app/theme/app_theme.dart';
import 'package:note_here/app/widgets/confirm_dialog.dart';
import 'package:note_here/app/widgets/empty_state_view.dart';

void main() {
  group('EmptyStateView', () {
    testWidgets('renders the no-notes state with the create CTA', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: EmptyStateView.noNotes(onAction: () {})),
        ),
      );

      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('renders the no-results state with a clear-search CTA', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: EmptyStateView.noResults(onAction: () {})),
        ),
      );

      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      expect(find.text('No matching notes'), findsOneWidget);
    });
  });

  group('showConfirmDialog', () {
    testWidgets('returns ConfirmResult.stay when cancelled', (
      WidgetTester tester,
    ) async {
      ConfirmResult? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showConfirmDialog(
                    context,
                    title: 'Discard changes?',
                    message: 'You have unsaved changes.',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(result, ConfirmResult.stay);
    });

    testWidgets('returns ConfirmResult.discard when confirmed', (
      WidgetTester tester,
    ) async {
      ConfirmResult? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showConfirmDialog(
                    context,
                    title: 'Discard changes?',
                    message: 'You have unsaved changes.',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(result, ConfirmResult.discard);
    });
  });
}
