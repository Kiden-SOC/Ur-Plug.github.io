import 'package:flutter_test/flutter_test.dart';
import 'package:ur_plug/main.dart';

void main() {
  testWidgets('App loads successfully with starter text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UrPlugApp());

    // Verify that our starter text appears on screen.
    expect(find.textContaining('Ur Plug Mobile App'), findsOneWidget);
  });
}

