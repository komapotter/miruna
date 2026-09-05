import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miruna/domain/decision_counts.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/features/apps/app_edit_screen.dart';
import 'package:miruna/features/apps/decision_graph_screen.dart';
import 'package:miruna/platform/app_monitor.dart';
import 'package:miruna/platform/installed_app.dart';
import 'package:miruna/platform/permission_status.dart';
import 'package:miruna/providers.dart';

const _app = WatchedApp(
  packageName: 'com.instagram.android',
  displayName: 'Instagram',
  warningPeriod: Duration(hours: 1),
);

const _now = DateTime(2026, 9, 5, 14, 30);

void main() {
  testWidgets('opens the graph from the app edit screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appMonitorProvider.overrideWithValue(_FakeAppMonitor()),
        ],
        child: const MaterialApp(home: AppEditScreen(app: _app)),
      ),
    );

    await tester.tap(find.text('記録を見る'));
    await tester.pumpAndSettle();

    expect(find.text('Instagramの記録'), findsOneWidget);
    expect(find.text('日'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);
    expect(find.text('年'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no decisions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appMonitorProvider.overrideWithValue(_FakeAppMonitor()),
        ],
        child: const MaterialApp(
          home: DecisionGraphScreen(
            packageName: 'com.instagram.android',
            displayName: 'Instagram',
            now: _now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('まだ記録がありません'), findsOneWidget);
    expect(find.textContaining('はい'), findsNothing);
  });

  testWidgets('shows day totals and switches to month and year', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appMonitorProvider.overrideWithValue(
            _FakeAppMonitor(
              counts: const DecisionCounts([
                DailyDecisionCount(
                  packageName: 'com.instagram.android',
                  dateKey: '2026-07-01',
                  yesCount: 1,
                  noCount: 2,
                ),
                DailyDecisionCount(
                  packageName: 'com.instagram.android',
                  dateKey: '2026-09-05',
                  yesCount: 2,
                  noCount: 1,
                ),
              ]),
            ),
          ),
        ],
        child: const MaterialApp(
          home: DecisionGraphScreen(
            packageName: 'com.instagram.android',
            displayName: 'Instagram',
            now: _now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('はい 2回 · いいえ 1回'), findsOneWidget);
    expect(find.byType(DecisionBarChart), findsOneWidget);

    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();
    expect(find.text('はい 3回 · いいえ 3回'), findsOneWidget);

    await tester.tap(find.text('年'));
    await tester.pumpAndSettle();
    expect(find.text('はい 3回 · いいえ 3回'), findsOneWidget);
  });
}

class _FakeAppMonitor implements AppMonitor {
  _FakeAppMonitor({this.counts = DecisionCounts.empty});

  final DecisionCounts counts;

  @override
  Future<PermissionStatus> getPermissionStatus() async =>
      PermissionStatus.unsupported();

  @override
  Future<void> openSettings(String type) async {}

  @override
  Future<void> requestNotifications() async {}

  @override
  Future<List<InstalledApp>> listInstalledApps() async => const [];

  @override
  Future<List<WatchedApp>> getWatchedApps() async => const [_app];

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

  @override
  Future<DecisionCounts> getDecisionCounts({
    String? packageName,
    DateTime? from,
    DateTime? to,
  }) async {
    return counts.filtered(packageName: packageName, from: from, to: to);
  }
}
