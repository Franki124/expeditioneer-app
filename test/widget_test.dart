import 'package:flutter_test/flutter_test.dart';

import 'package:expeditioneer_journal/app.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(ExpeditioneerApp());
    await tester.pumpAndSettle();

    expect(find.text('The Expedition Journal'), findsOneWidget);
  });
}
