class WatchedApp {
  const WatchedApp({
    required this.packageName,
    required this.displayName,
    required this.warningPeriod,
    this.enabled = true,
    this.lastClosedAt,
    this.sessionAllowed = false,
  });

  final String packageName;
  final String displayName;
  final Duration warningPeriod;
  final bool enabled;
  final DateTime? lastClosedAt;
  final bool sessionAllowed;

  WatchedApp copyWith({
    String? displayName,
    Duration? warningPeriod,
    bool? enabled,
    DateTime? lastClosedAt,
    bool? sessionAllowed,
  }) {
    return WatchedApp(
      packageName: packageName,
      displayName: displayName ?? this.displayName,
      warningPeriod: warningPeriod ?? this.warningPeriod,
      enabled: enabled ?? this.enabled,
      lastClosedAt: lastClosedAt ?? this.lastClosedAt,
      sessionAllowed: sessionAllowed ?? this.sessionAllowed,
    );
  }

  Map<String, dynamic> toChannelMap() {
    return {
      'packageName': packageName,
      'displayName': displayName,
      'warningPeriodMs': warningPeriod.inMilliseconds,
      'enabled': enabled,
    };
  }

      factory WatchedApp.fromChannelMap(Map<Object?, Object?> map) {
        final closed = map['lastClosedAtMs'];
        return WatchedApp(
          packageName: map['packageName'] as String,
          displayName: map['displayName'] as String,
          warningPeriod: Duration(
            milliseconds: (map['warningPeriodMs'] as num).toInt(),
          ),
          enabled: map['enabled'] as bool? ?? true,
          lastClosedAt: closed is num
              ? DateTime.fromMillisecondsSinceEpoch(closed.toInt())
              : null,
          sessionAllowed: map['sessionAllowed'] as bool? ?? false,
        );
      }
}
