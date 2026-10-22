import 'package:flutter_test/flutter_test.dart';
import 'package:dangthithaiha/main.dart';

void main() {
  testWidgets('ChildGuardApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChildGuardApp());
    expect(find.text('CHILD GUARD MANAGER'), findsOneWidget);
  });
}
