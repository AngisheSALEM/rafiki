import 'package:flutter_test/flutter_test.dart';
import 'package:rafiki_mobile_app/main.dart';

void main() {
  testWidgets('Rafiki app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RafikiApp());
    expect(find.byType(RafikiApp), findsOneWidget);
  });
}
