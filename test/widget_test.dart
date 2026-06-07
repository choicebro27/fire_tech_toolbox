// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fire_tech_toolbox/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FireTechToolboxApp());
    expect(find.byType(FireTechToolboxApp), findsOneWidget);
  });
}
