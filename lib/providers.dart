import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miruna/domain/decision_counts.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/platform/android_app_monitor.dart';
import 'package:miruna/platform/app_monitor.dart';
import 'package:miruna/platform/permission_status.dart';
import 'package:miruna/platform/stub_app_monitor.dart';

final appMonitorProvider = Provider<AppMonitor>((ref) {
  if (Platform.isAndroid) {
    return AndroidAppMonitor();
  }
  return StubAppMonitor();
});

class MonitorSnapshot {
  const MonitorSnapshot({
    required this.apps,
    required this.permissions,
    required this.monitoring,
    required this.defaultWarningPeriod,
  });

  final List<WatchedApp> apps;
  final PermissionStatus permissions;
  final bool monitoring;
  final Duration defaultWarningPeriod;
}

class MonitorController extends AsyncNotifier<MonitorSnapshot> {
  AppMonitor get _monitor => ref.read(appMonitorProvider);

  @override
  Future<MonitorSnapshot> build() => _load();

  Future<MonitorSnapshot> _load() async {
    final permissions = await _monitor.getPermissionStatus();
    final apps = await _monitor.getWatchedApps();
    final monitoring = await _monitor.isMonitoring();
    final defaultWarningPeriod = await _monitor.getDefaultWarningPeriod();
    return MonitorSnapshot(
      apps: apps,
      permissions: permissions,
      monitoring: monitoring,
      defaultWarningPeriod: defaultWarningPeriod,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> upsert(WatchedApp app) async {
    await _monitor.upsertWatchedApp(app);
    await refresh();
  }

  Future<void> remove(String packageName) async {
    await _monitor.removeWatchedApp(packageName);
    await refresh();
  }

  Future<void> setDefaultWarningPeriod(Duration period) async {
    await _monitor.setDefaultWarningPeriod(period);
    await refresh();
  }

  Future<bool> setMonitoring(bool enabled) async {
    final current = state.value;
    if (enabled && current != null && !current.permissions.canMonitor) {
      return false;
    }
    await _monitor.setMonitoring(enabled);
    await refresh();
    return true;
  }
}

final monitorControllerProvider =
    AsyncNotifierProvider<MonitorController, MonitorSnapshot>(
      MonitorController.new,
    );

final decisionCountsProvider =
    FutureProvider.autoDispose.family<DecisionCounts, String>((ref, packageName) {
      return ref.read(appMonitorProvider).getDecisionCounts(
        packageName: packageName,
      );
    });
