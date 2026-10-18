import 'package:flutter_test/flutter_test.dart';
import 'package:miruna/domain/cooldown.dart';
import 'package:miruna/domain/duration_format.dart';

void main() {
  final now = DateTime.utc(2026, 8, 29, 12);

  group('Cooldown.decide', () {
    test('allows apps that are not watched', () {
      expect(
        Cooldown.decide(
          watched: false,
          enabled: true,
          sessionAllowed: false,
          lastClosedAt: now.subtract(const Duration(minutes: 5)),
          warningPeriod: const Duration(hours: 1),
          now: now,
        ),
        CooldownAction.allow,
      );
    });

    test('allows watched apps that are disabled', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: false,
          sessionAllowed: false,
          lastClosedAt: now.subtract(const Duration(minutes: 5)),
          warningPeriod: const Duration(hours: 1),
          now: now,
        ),
        CooldownAction.allow,
      );
    });

    test('allows the first launch when there is no close timestamp', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: true,
          sessionAllowed: false,
          lastClosedAt: null,
          warningPeriod: const Duration(hours: 1),
          now: now,
        ),
        CooldownAction.allow,
      );
    });

    test('allows when the current session was already confirmed', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: true,
          sessionAllowed: true,
          lastClosedAt: now.subtract(const Duration(minutes: 5)),
          warningPeriod: const Duration(hours: 1),
          now: now,
        ),
        CooldownAction.allow,
      );
    });

    test('warns when reopened inside the warning period', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: true,
          sessionAllowed: false,
          lastClosedAt: now.subtract(const Duration(minutes: 59)),
          warningPeriod: const Duration(hours: 1),
          now: now,
        ),
        CooldownAction.warn,
      );
    });

    test('allows when the warning period has elapsed', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: true,
          sessionAllowed: false,
          lastClosedAt: now.subtract(const Duration(hours: 1)),
          warningPeriod: const Duration(hours: 1),
          now: now,
        ),
        CooldownAction.allow,
      );
    });

    test('uses a per-app warning period', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: true,
          sessionAllowed: false,
          lastClosedAt: now.subtract(const Duration(hours: 2)),
          warningPeriod: const Duration(hours: 6),
          now: now,
        ),
        CooldownAction.warn,
      );
    });

    test('allows reopen while unlock cooldown is active', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: true,
          sessionAllowed: false,
          lastClosedAt: now.subtract(const Duration(minutes: 1)),
          warningPeriod: const Duration(hours: 1),
          now: now,
          unlockedUntil: now.add(const Duration(minutes: 4)),
        ),
        CooldownAction.allow,
      );
    });

    test('uses warning period after unlock cooldown expires', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: true,
          sessionAllowed: false,
          lastClosedAt: now.subtract(const Duration(minutes: 20)),
          warningPeriod: const Duration(hours: 1),
          now: now,
          unlockedUntil: now.subtract(const Duration(minutes: 1)),
        ),
        CooldownAction.warn,
      );
    });

    test('keeps old behaviour when cooldown is disabled', () {
      expect(
        Cooldown.decide(
          watched: true,
          enabled: true,
          sessionAllowed: false,
          lastClosedAt: now.subtract(const Duration(minutes: 5)),
          warningPeriod: const Duration(hours: 1),
          now: now,
          unlockedUntil: null,
        ),
        CooldownAction.warn,
      );
    });
  });

  group('Cooldown.unlockedUntil', () {
    test('is null when cooldown is disabled', () {
      expect(
        Cooldown.unlockedUntil(
          now: now,
          cooldownPeriod: Duration.zero,
        ),
        isNull,
      );
    });

    test('counts from the unlock time', () {
      expect(
        Cooldown.unlockedUntil(
          now: now,
          cooldownPeriod: const Duration(minutes: 5),
        ),
        now.add(const Duration(minutes: 5)),
      );
    });
  });

  group('Cooldown.remainingCooldown', () {
    test('returns null when never closed', () {
      expect(
        Cooldown.remainingCooldown(
          lastClosedAt: null,
          warningPeriod: const Duration(hours: 1),
          now: now,
        ),
        isNull,
      );
    });

    test('returns remaining time inside the window', () {
      expect(
        Cooldown.remainingCooldown(
          lastClosedAt: now.subtract(const Duration(minutes: 20)),
          warningPeriod: const Duration(hours: 1),
          now: now,
        ),
        const Duration(minutes: 40),
      );
    });
  });

  group('Cooldown.shouldRecordClose', () {
    test('does not record a close for an unconfirmed warning', () {
      expect(
        Cooldown.shouldRecordClose(unconfirmedWarning: true),
        isFalse,
      );
    });

    test('records a close for a confirmed or normal session', () {
      expect(
        Cooldown.shouldRecordClose(unconfirmedWarning: false),
        isTrue,
      );
    });
  });

  group('unlock cooldown options', () {
    test('defaults new apps to five minutes with short presets', () {
      expect(Cooldown.defaultCooldownPeriod, const Duration(minutes: 5));
      expect(Cooldown.cooldownPresets, const [
        Duration.zero,
        Duration(minutes: 3),
        Duration(minutes: 5),
        Duration(minutes: 10),
      ]);
    });
  });

  group('formatWarningPeriod', () {
    test('formats hours and minutes', () {
      expect(formatWarningPeriod(const Duration(hours: 1)), '1時間');
      expect(formatWarningPeriod(const Duration(minutes: 30)), '30分');
      expect(formatWarningPeriod(const Duration(hours: 6)), '6時間');
      expect(
        formatWarningPeriod(const Duration(hours: 1, minutes: 15)),
        '1時間15分',
      );
      expect(formatWarningPeriod(Duration.zero), 'なし');
    });
  });
}
