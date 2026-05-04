// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:interva/main.dart';
import 'package:interva/services/storage_service.dart';
import 'package:interva/providers/theme_provider.dart';
import 'package:interva/providers/build_session_provider.dart';
import 'package:interva/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Setup for SharedPreferences in tests
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    // Note: In a real test suite, you'd mock the StorageService or properly initialize it.

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
          ChangeNotifierProvider(create: (_) => BuildSessionProvider(storageService)),
          ChangeNotifierProvider(create: (_) => SettingsProvider(storageService)),
        ],
        child: const IntervaApp(),
      ),
    );

    // Verify that our app starts and displays the title.
    expect(find.text('Interva'), findsOneWidget);
    
    // Verify that the empty state message is shown.
    expect(find.text('No intervals added yet.\nTap + to create one.'), findsOneWidget);

    // Tap the '+' icon.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that the "Add Interval" sheet appears (checking for a common label).
    expect(find.text('Interval Name'), findsOneWidget);
  });
}
