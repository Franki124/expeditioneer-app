import 'package:flutter_test/flutter_test.dart';

import 'package:expeditioneer_journal/core/utils/countdown_formatter.dart';

void main() {
  group('formatCountdown', () {
    test('shows hours and minutes when over an hour remains', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final endAt = now.add(const Duration(hours: 2, minutes: 14));
      expect(formatCountdown(endAt, now: now), '2h 14m left');
    });

    test('shows only minutes when under an hour remains', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final endAt = now.add(const Duration(minutes: 45));
      expect(formatCountdown(endAt, now: now), '45m left');
    });

    test('shows Ended once the time has passed', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final endAt = now.subtract(const Duration(minutes: 1));
      expect(formatCountdown(endAt, now: now), 'Ended');
    });
  });
}
