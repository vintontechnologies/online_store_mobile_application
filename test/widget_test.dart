
import 'package:flutter_test/flutter_test.dart';
import 'package:vintonstore_mobile/main.dart';

void main() {
  testWidgets('VintonStore app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const VintonStoreApp());

    expect(find.text('VintonStore'), findsOneWidget);
    expect(find.text('Featured products'), findsOneWidget);
    expect(find.text('Wireless Headphones'), findsOneWidget);
  });
}
