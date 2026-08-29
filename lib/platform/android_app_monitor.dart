import 'package:flutter/services.dart';
import 'package:miruna/domain/cooldown.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/platform/app_monitor.dart';
import 'package:miruna/platform/installed_app.dart';
import 'package:miruna/platform/permission_status.dart';

class AndroidAppMonitor implements AppMonitor {
  AndroidAppMonitor({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.komapotter.miruna/monitor');

  final MethodChannel _channel;

  @override
  Future<PermissionStatus> getPermissionStatus() async {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getPermissionStatus',
    );
    return PermissionStatus.fromChannelMap(raw ?? const {});
  }

  @override
  Future<void> openSettings(String type) {
    return _channel.invokeMethod<void>('openSettings', {'type': type});
  }

  @override
  Future<void> requestNotifications() {
    return _channel.invokeMethod<void>('requestNotifications');
  }

  @override
  Future<List<InstalledApp>> listInstalledApps() async {
    final raw = await _channel.invokeMethod<List<Object?>>('listInstalledApps');
    return (raw ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(InstalledApp.fromChannelMap)
        .toList();
  }

  @override
  Future<List<WatchedApp>> getWatchedApps() async {
    final raw = await _channel.invokeMethod<List<Object?>>('getWatchedApps');
    return (raw ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(WatchedApp.fromChannelMap)
        .toList();
  }

  @override
  Future<void> upsertWatchedApp(WatchedApp app) {
    return _channel.invokeMethod<void>('upsertWatchedApp', app.toChannelMap());
  }

  @override
  Future<void> removeWatchedApp(String packageName) {
    return _channel.invokeMethod<void>('removeWatchedApp', {
      'packageName': packageName,
    });
  }

  @override
  Future<Duration> getDefaultWarningPeriod() async {
    final ms = await _channel.invokeMethod<int>('getDefaultWarningPeriodMs');
    return Duration(milliseconds: ms ?? Cooldown.defaultPeriod.inMilliseconds);
  }

  @override
  Future<void> setDefaultWarningPeriod(Duration period) {
    return _channel.invokeMethod<void>('setDefaultWarningPeriodMs', {
      'ms': period.inMilliseconds,
    });
  }

  @override
  Future<bool> isMonitoring() async {
    return await _channel.invokeMethod<bool>('isMonitoring') ?? false;
  }

  @override
  Future<void> setMonitoring(bool enabled) {
    return _channel.invokeMethod<void>('setMonitoring', {'enabled': enabled});
  }
}
