import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miruna/domain/decision_counts.dart';
import 'package:miruna/platform/android_app_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.komapotter.miruna/monitor');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps filtered decision counts from the monitor channel', () async {
    late MethodCall received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return [
            {
              'packageName': 'com.instagram.android',
              'date': '2026-09-05',
              'yesCount': 2,
              'noCount': 1,
            },
          ];
        });

    final monitor = AndroidAppMonitor(channel: channel);
    final counts = await monitor.getDecisionCounts(
      packageName: 'com.instagram.android',
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 30),
    );

    expect(received.method, 'getDecisionCounts');
    expect(received.arguments, {
      'packageName': 'com.instagram.android',
      'fromDate': '2026-09-01',
      'toDate': '2026-09-30',
    });
    expect(
      counts.entries.single,
      const DailyDecisionCount(
        packageName: 'com.instagram.android',
        dateKey: '2026-09-05',
        yesCount: 2,
        noCount: 1,
      ),
    );
  });
}
