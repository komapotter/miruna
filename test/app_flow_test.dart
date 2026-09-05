import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miruna/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding explains Android-only monitoring then opens the list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MirunaApp()));
    await tester.pumpAndSettle();

    expect(find.text('見たな'), findsOneWidget);
    expect(find.text('監視は Android でのみ利用できます'), findsOneWidget);

    await tester.tap(find.text('始める'));
    await tester.pumpAndSettle();

    expect(find.text('監視するアプリを追加してください'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('この端末では監視できません'), findsOneWidget);
  });
}
