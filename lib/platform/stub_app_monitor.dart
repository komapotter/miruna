import 'dart:convert';

import 'package:miruna/domain/cooldown.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/platform/app_monitor.dart';
import 'package:miruna/platform/installed_app.dart';
import 'package:miruna/platform/permission_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iOS and other platforms: settings persist locally, monitoring is unavailable.
class StubAppMonitor implements AppMonitor {
  StubAppMonitor({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  @override
  Future<PermissionStatus> getPermissionStatus() async {
    return PermissionStatus.unsupported();
  }

  @override
  Future<void> openSettings(String type) async {}

  @override
  Future<void> requestNotifications() async {}

  @override
  Future<List<InstalledApp>> listInstalledApps() async => const [];

  @override
  Future<List<WatchedApp>> getWatchedApps() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_appsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (map) => WatchedApp.fromChannelMap(
            map.map((key, value) => MapEntry(key as Object, value as Object?)),
          ),
        )
        .toList();
  }

  @override
  Future<void> upsertWatchedApp(WatchedApp app) async {
    final apps = [...await getWatchedApps()];
    final index = apps.indexWhere((item) => item.packageName == app.packageName);
    if (index >= 0) {
      apps[index] = app;
    } else {
      apps.add(app);
    }
    await _saveApps(apps);
  }

  @override
  Future<void> removeWatchedApp(String packageName) async {
    final apps = await getWatchedApps();
    await _saveApps(
      apps.where((app) => app.packageName != packageName).toList(),
    );
  }

  @override
  Future<Duration> getDefaultWarningPeriod() async {
    final prefs = await _prefs;
    final ms = prefs.getInt(_periodKey);
    return Duration(milliseconds: ms ?? Cooldown.defaultPeriod.inMilliseconds);
  }

  @override
  Future<void> setDefaultWarningPeriod(Duration period) async {
    final prefs = await _prefs;
    await prefs.setInt(_periodKey, period.inMilliseconds);
  }

  @override
  Future<bool> isMonitoring() async => false;

  @override
  Future<void> setMonitoring(bool enabled) async {}

  Future<void> _saveApps(List<WatchedApp> apps) async {
    final prefs = await _prefs;
    final payload = apps
        .map(
          (app) => {
            ...app.toChannelMap(),
            'lastClosedAtMs': app.lastClosedAt?.millisecondsSinceEpoch,
            'sessionAllowed': app.sessionAllowed,
          },
        )
        .toList();
    await prefs.setString(_appsKey, jsonEncode(payload));
  }

  static const _appsKey = 'stub_watched_apps';
  static const _periodKey = 'stub_default_warning_period_ms';
}
