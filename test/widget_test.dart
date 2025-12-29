import 'package:flutter_test/flutter_test.dart';
import 'package:near/app/app.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const NearApp());
    expect(find.text('near'), findsOneWidget);
  });
}
