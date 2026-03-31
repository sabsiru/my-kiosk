import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk_app/app.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KioskApp()));
    expect(find.text('주문하기'), findsOneWidget);
  });
}
