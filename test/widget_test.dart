import 'package:flutter_test/flutter_test.dart';
import 'package:cero/main.dart';

void main() {
  testWidgets('arranca y muestra el nombre', (tester) async {
    await tester.pumpWidget(const CeroApp());
    expect(find.text('Cero'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('Hoy'), findsWidgets);
  });
}
