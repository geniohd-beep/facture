import 'package:flutter_test/flutter_test.dart';
import 'package:facture/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FactureApp());
    expect(find.text('Facture'), findsOneWidget);
  });
}
