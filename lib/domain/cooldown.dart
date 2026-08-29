enum CooldownAction {
  /// Open without a warning dialog.
  allow,

  /// Show the yes/no warning dialog.
  warn,
}

/// Pure cooldown rules shared as the spec for the Android native monitor.
class Cooldown {
  const Cooldown._();

  static const defaultPeriod = Duration(hours: 1);
  static const closeGrace = Duration(seconds: 3);

  static const presets = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 3),
    Duration(hours: 6),
    Duration(hours: 24),
  ];

  static CooldownAction decide({
    required bool watched,
    required bool enabled,
    required bool sessionAllowed,
    required DateTime? lastClosedAt,
    required Duration warningPeriod,
    required DateTime now,
  }) {
    if (!watched || !enabled) {
      return CooldownAction.allow;
    }
    if (sessionAllowed) {
      return CooldownAction.allow;
    }
    if (lastClosedAt == null) {
      return CooldownAction.allow;
    }
    if (now.difference(lastClosedAt) < warningPeriod) {
      return CooldownAction.warn;
    }
    return CooldownAction.allow;
  }

  static Duration? remainingCooldown({
    required DateTime? lastClosedAt,
    required Duration warningPeriod,
    required DateTime now,
  }) {
    if (lastClosedAt == null) {
      return null;
    }
    final until = lastClosedAt.add(warningPeriod);
    if (!until.isAfter(now)) {
      return null;
    }
    return until.difference(now);
  }
}
