class WatchedApp {
  const WatchedApp({
    required this.packageName,
    required this.displayName,
    required this.warningPeriod,
    this.cooldownPeriod = Duration.zero,
    this.enabled = true,
    this.lastClosedAt,
    this.sessionAllowed = false,
    this.unlockedUntil,
  });

  final String packageName;
  final String displayName;
  final Duration warningPeriod;
  final Duration cooldownPeriod;
  final bool enabled;
  final DateTime? lastClosedAt;
  final bool sessionAllowed;
  final DateTime? unlockedUntil;

  WatchedApp copyWith({
    String? displayName,
    Duration? warningPeriod,
    Duration? cooldownPeriod,
    bool? enabled,
    DateTime? lastClosedAt,
    bool? sessionAllowed,
    DateTime? unlockedUntil,
  }) {
    return WatchedApp(
      packageName: packageName,
      displayName: displayName ?? this.displayName,
      warningPeriod: warningPeriod ?? this.warningPeriod,
      cooldownPeriod: cooldownPeriod ?? this.cooldownPeriod,
      enabled: enabled ?? this.enabled,
      lastClosedAt: lastClosedAt ?? this.lastClosedAt,
      sessionAllowed: sessionAllowed ?? this.sessionAllowed,
      unlockedUntil: unlockedUntil ?? this.unlockedUntil,
    );
  }

  Map<String, dynamic> toChannelMap() {
    return {
      'packageName': packageName,
      'displayName': displayName,
      'warningPeriodMs': warningPeriod.inMilliseconds,
      'cooldownPeriodMs': cooldownPeriod.inMilliseconds,
      'enabled': enabled,
    };
  }

  factory WatchedApp.fromChannelMap(Map<Object?, Object?> map) {
    final closed = map['lastClosedAtMs'];
    final unlocked = map['unlockedUntilMs'];
    final cooldownMs = map['cooldownPeriodMs'];
    return WatchedApp(
      packageName: map['packageName'] as String,
      displayName: map['displayName'] as String,
      warningPeriod: Duration(
        milliseconds: (map['warningPeriodMs'] as num).toInt(),
      ),
      cooldownPeriod: Duration(
        milliseconds: cooldownMs is num ? cooldownMs.toInt() : 0,
      ),
      enabled: map['enabled'] as bool? ?? true,
      lastClosedAt: closed is num
          ? DateTime.fromMillisecondsSinceEpoch(closed.toInt())
          : null,
      sessionAllowed: map['sessionAllowed'] as bool? ?? false,
      unlockedUntil: unlocked is num
          ? DateTime.fromMillisecondsSinceEpoch(unlocked.toInt())
          : null,
    );
  }
}
