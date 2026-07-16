import 'package:flutter_test/flutter_test.dart';
import 'package:followup_tracker/main.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const FollowUpTrackerApp());
    await tester.pump();
    expect(find.byType(FollowUpTrackerApp), findsOneWidget);
  });
}
