import 'package:flutter_test/flutter_test.dart';
import 'package:mcp/main.dart';

void main() {
  testWidgets('StoreApp basic load smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StoreApp());
    expect(find.text('QuickStore'), findsOneWidget);
    expect(find.text('Wireless Headphones'), findsOneWidget);
  });
}
