import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qgami_sdk/qgami.dart';

void main() {
  testWidgets('QgamiButton renders default label', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: QgamiButton(),
      ),
    );

    expect(find.text('Default Qgami Button'), findsOneWidget);
  });

  testWidgets('QgamiButton renders customBuilder child', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: QgamiButton(customBuilder: (_) => const Text('Custom CTA')),
      ),
    );

    expect(find.text('Custom CTA'), findsOneWidget);
    expect(find.text('Default Qgami Button'), findsNothing);
  });
}
