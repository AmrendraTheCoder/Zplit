import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zplit/main.dart';

void main() {
  testWidgets('App launches and shows onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ZplitApp()),
    );
    await tester.pumpAndSettle();

    // Verify the onboarding screen is shown with ZPLIT branding
    expect(find.text('ZPLIT'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
