import 'package:flutter_test/flutter_test.dart';
import 'package:miruna/domain/watched_app.dart';

void main() {
  test('toChannelMap includes cooldownPeriodMs', () {
    const app = WatchedApp(
      packageName: 'com.instagram.android',
      displayName: 'Instagram',
      warningPeriod: Duration(hours: 1),
      cooldownPeriod: Duration(minutes: 15),
    );

    expect(app.toChannelMap(), {
      'packageName': 'com.instagram.android',
      'displayName': 'Instagram',
      'warningPeriodMs': 3600000,
      'cooldownPeriodMs': 900000,
      'enabled': true,
    });
  });

  test('fromChannelMap treats a missing cooldown field as disabled', () {
    final app = WatchedApp.fromChannelMap({
      'packageName': 'com.instagram.android',
      'displayName': 'Instagram',
      'warningPeriodMs': 3600000,
      'enabled': true,
      'sessionAllowed': false,
    });

    expect(app.cooldownPeriod, Duration.zero);
    expect(app.unlockedUntil, isNull);
  });

  test('fromChannelMap reads cooldown and unlock expiry', () {
    final app = WatchedApp.fromChannelMap({
      'packageName': 'com.instagram.android',
      'displayName': 'Instagram',
      'warningPeriodMs': 3600000,
      'cooldownPeriodMs': 900000,
      'enabled': true,
      'lastClosedAtMs': 1000,
      'sessionAllowed': false,
      'unlockedUntilMs': 2000,
    });

    expect(app.cooldownPeriod, const Duration(minutes: 15));
    expect(
      app.unlockedUntil,
      DateTime.fromMillisecondsSinceEpoch(2000),
    );
    expect(
      app.lastClosedAt,
      DateTime.fromMillisecondsSinceEpoch(1000),
    );
  });
}
