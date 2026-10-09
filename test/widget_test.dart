import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuri/main.dart';

void main() {
  testWidgets('KuriApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KuriApp());
    expect(find.text('കുറി'), findsOneWidget);
  });

  testWidgets('Renders Column View on mobile viewport', (WidgetTester tester) async {
    // Set mobile screen size (375 x 667)
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const KuriApp());

    // Add a member to populate list
    await tester.enterText(find.byType(TextField), 'അനീഷ്');
    await tester.tap(find.text('ചേർക്കുക'));
    await tester.pumpAndSettle();

    // Verify Column View list view exists
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('Renders Row View on web desktop viewport', (WidgetTester tester) async {
    // Set desktop web screen size (1280 x 800)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const KuriApp());

    // Add a member to populate list
    await tester.enterText(find.byType(TextField), 'അനീഷ്');
    await tester.tap(find.text('ചേർക്കുക'));
    await tester.pumpAndSettle();

    // Verify Row View Wrap widget exists
    expect(find.byType(Wrap), findsOneWidget);
  });
}

