import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/platform/installed_app.dart';
import 'package:miruna/platform/permission_status.dart';

abstract class AppMonitor {
  Future<PermissionStatus> getPermissionStatus();

  Future<void> openSettings(String type);

  Future<void> requestNotifications();

  Future<List<InstalledApp>> listInstalledApps();

  Future<List<WatchedApp>> getWatchedApps();

  Future<void> upsertWatchedApp(WatchedApp app);

  Future<void> removeWatchedApp(String packageName);

  Future<Duration> getDefaultWarningPeriod();

  Future<void> setDefaultWarningPeriod(Duration period);

  Future<bool> isMonitoring();

  Future<void> setMonitoring(bool enabled);
}
