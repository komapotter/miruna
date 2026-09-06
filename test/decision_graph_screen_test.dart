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

final _now = DateTime(2026, 9, 5, 14, 30);

void main() {
  test('scales stacked bars by yes plus no, not the taller series', () {
    expect(
      DecisionBarChart.maxStackedCount(const [
        PeriodDecisionCount(
          packageName: 'com.instagram.android',
          period: DecisionPeriod.day,
          periodKey: '2026-09-04',
          yesCount: 5,
          noCount: 1,
        ),
        PeriodDecisionCount(
          packageName: 'com.instagram.android',
          period: DecisionPeriod.day,
          periodKey: '2026-09-05',
          yesCount: 3,
          noCount: 4,
        ),
      ]),
      7,
    );
  });

  test('uses the same look/skip colors as the warning overlay', () {
    expect(DecisionBarChart.yesColor, const Color(0xFFB91C1C));
    expect(DecisionBarChart.noColor, const Color(0xFFD1D5DB));
  });

  test('builds right-side gauge ticks from the stacked max', () {
    expect(DecisionBarChart.gaugeValues(0), [0]);
    expect(DecisionBarChart.gaugeValues(1), [1, 0]);
    expect(DecisionBarChart.gaugeValues(7), [7, 5, 2, 0]);
    expect(DecisionBarChart.formatGaugeLabel(12896), '12,896');
  });

  testWidgets('opens the graph from the app edit screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appMonitorProvider.overrideWithValue(_FakeAppMonitor()),
        ],
        child: const MaterialApp(home: AppEditScreen(app: _app)),
      ),
    );

    expect(find.text('見る / 見ないの回数を年・月・日で表示します'), findsOneWidget);

    await tester.tap(find.text('見てしまった回数'));
    await tester.pumpAndSettle();

    expect(find.text('Instagramの記録'), findsOneWidget);
    expect(find.text('週'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);
    expect(find.text('年'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no decisions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appMonitorProvider.overrideWithValue(_FakeAppMonitor()),
        ],
        child: MaterialApp(
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
    expect(find.text('8月31日～9月6日'), findsOneWidget);
    expect(find.textContaining('見る'), findsNothing);
  });

  testWidgets('shows week averages and switches to month and year', (tester) async {
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
        child: MaterialApp(
          home: DecisionGraphScreen(
            packageName: 'com.instagram.android',
            displayName: 'Instagram',
            now: _now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('8月31日～9月6日'), findsOneWidget);
    expect(find.text('見る 0.3回 · 見ない 0.1回 (1日平均)'), findsOneWidget);
    expect(find.text('見る'), findsOneWidget);
    expect(find.text('見ない'), findsOneWidget);
    expect(find.byType(DecisionBarChart), findsOneWidget);

    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();
    expect(find.text('2025年10月～2026年9月'), findsOneWidget);
    expect(find.text('見る 0.3回 · 見ない 0.3回 (1か月平均)'), findsOneWidget);

    await tester.tap(find.text('年'));
    await tester.pumpAndSettle();
    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('見る 3回 · 見ない 3回 (1年平均)'), findsOneWidget);
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
