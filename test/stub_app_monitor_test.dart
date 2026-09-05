import 'package:flutter_test/flutter_test.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/platform/stub_app_monitor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('StubAppMonitor persists watched apps and default period', () async {
    SharedPreferences.setMockInitialValues({});
    final monitor = StubAppMonitor();

    expect(await monitor.isMonitoring(), isFalse);
    expect((await monitor.getPermissionStatus()).supportsMonitoring, isFalse);
    expect(await monitor.listInstalledApps(), isEmpty);

    await monitor.setDefaultWarningPeriod(const Duration(hours: 6));
    expect(await monitor.getDefaultWarningPeriod(), const Duration(hours: 6));

    await monitor.upsertWatchedApp(
      const WatchedApp(
        packageName: 'com.slack',
        displayName: 'Slack',
        warningPeriod: Duration(hours: 1),
      ),
    );
    final apps = await monitor.getWatchedApps();
    expect(apps, hasLength(1));
    expect(apps.single.packageName, 'com.slack');
    expect(apps.single.warningPeriod, const Duration(hours: 1));
    expect((await monitor.getDecisionCounts()).entries, isEmpty);
  });
}
