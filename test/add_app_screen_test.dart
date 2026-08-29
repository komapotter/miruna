import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/features/apps/add_app_screen.dart';
import 'package:miruna/platform/app_monitor.dart';
import 'package:miruna/platform/installed_app.dart';
import 'package:miruna/platform/permission_status.dart';
import 'package:miruna/providers.dart';

void main() {
  testWidgets('hides package names in the installed app list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appMonitorProvider.overrideWithValue(_FakeAppMonitor()),
        ],
        child: const MaterialApp(home: AddAppScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1Password'), findsOneWidget);
    expect(find.text('com.onepassword.android'), findsNothing);
    expect(find.text('アプリ名で検索'), findsOneWidget);
  });
}

class _FakeAppMonitor implements AppMonitor {
  @override
  Future<PermissionStatus> getPermissionStatus() async =>
      PermissionStatus.unsupported();

  @override
  Future<void> openSettings(String type) async {}

  @override
  Future<void> requestNotifications() async {}

  @override
  Future<List<InstalledApp>> listInstalledApps() async => const [
    InstalledApp(
      packageName: 'com.onepassword.android',
      label: '1Password',
    ),
  ];

  @override
  Future<List<WatchedApp>> getWatchedApps() async => const [];

  @override
  Future<void> upsertWatchedApp(WatchedApp app) async {}

  @override
  Future<void> removeWatchedApp(String packageName) async {}

  @override
  Future<Duration> getDefaultWarningPeriod() async => const Duration(hours: 1);

  @override
  Future<void> setDefaultWarningPeriod(Duration period) async {}

  @override
  Future<bool> isMonitoring() async => false;

  @override
  Future<void> setMonitoring(bool enabled) async {}
}
