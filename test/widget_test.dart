// Smoke tests for the NoteHere foundation.
//
// These tests verify the building blocks of the app without booting the
// real Firebase backend. End-to-end behaviour is exercised with a real
// Firebase project via `flutter run`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:note_here/app/theme/app_theme.dart';
import 'package:note_here/app/widgets/app_button.dart';
import 'package:note_here/app/widgets/app_loading_indicator.dart';
import 'package:note_here/app/widgets/app_text_field.dart';

void main() {
  testWidgets('AppButton renders a label and fires onPressed', (
    WidgetTester tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(label: 'Save', onPressed: () => taps++),
        ),
      ),
    );

    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('AppTextField reacts to onChanged', (WidgetTester tester) async {
    var changes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppTextField(label: 'Title', onChanged: changes.add),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Hello');
    expect(changes, <String>['Hello']);
  });

  testWidgets('AppLoadingIndicator renders the spinner and the message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AppLoadingIndicator(message: 'Loading…'),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading…'), findsOneWidget);
  });
}
