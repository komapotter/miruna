class PermissionStatus {
  const PermissionStatus({
    required this.supportsMonitoring,
    required this.usageAccess,
    required this.overlay,
    required this.notifications,
    required this.accessibility,
    required this.batteryUnrestricted,
  });

  final bool supportsMonitoring;
  final bool usageAccess;
  final bool overlay;
  final bool notifications;
  final bool accessibility;
  final bool batteryUnrestricted;

  bool get canMonitor =>
      supportsMonitoring && overlay && (usageAccess || accessibility);

  factory PermissionStatus.unsupported() {
    return const PermissionStatus(
      supportsMonitoring: false,
      usageAccess: false,
      overlay: false,
      notifications: false,
      accessibility: false,
      batteryUnrestricted: false,
    );
  }

  factory PermissionStatus.fromChannelMap(Map<Object?, Object?> map) {
    return PermissionStatus(
      supportsMonitoring: map['supportsMonitoring'] as bool? ?? false,
      usageAccess: map['usageAccess'] as bool? ?? false,
      overlay: map['overlay'] as bool? ?? false,
      notifications: map['notifications'] as bool? ?? false,
      accessibility: map['accessibility'] as bool? ?? false,
      batteryUnrestricted: map['batteryUnrestricted'] as bool? ?? false,
    );
  }
}
