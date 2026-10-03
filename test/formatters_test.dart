import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_admin_panel/common/utils/formatters.dart';
import 'package:cricket_admin_panel/admin/presentation/screens/location_management/widgets/location_detail_widgets.dart';

void main() {
  group('formatHourlyRate', () {
    test('renders whole rupee amounts without a trailing decimal', () {
      expect(formatHourlyRate(500), '₹500');
      expect(formatHourlyRate(500.0), '₹500');
      expect(formatHourlyRate('750'), '₹750');
    });

    test('keeps paise when the rate is genuinely fractional', () {
      // A plain integer conversion would have silently rounded this away.
      expect(formatHourlyRate(49.5), '₹49.50');
      expect(formatHourlyRate('49.5'), '₹49.50');
    });

    test('groups thousands', () {
      expect(formatHourlyRate(1500), '₹1,500');
      expect(formatHourlyRate(120000), '₹1,20,000');
    });

    test('handles missing and junk values without throwing', () {
      expect(formatHourlyRate(null), '₹0');
      expect(formatHourlyRate(''), '₹0');
      expect(formatHourlyRate('abc'), '₹0');
    });
  });

  group('formatInr', () {
    test('leaves values under 1000 untouched', () {
      expect(formatInr(0), '0');
      expect(formatInr(7), '7');
      expect(formatInr(999), '999');
    });

    test('groups thousands', () {
      expect(formatInr(1000), '1,000');
      expect(formatInr(9999), '9,999');
      expect(formatInr(99999), '99,999');
    });

    test('uses Indian lakh/crore grouping', () {
      expect(formatInr(100000), '1,00,000');
      expect(formatInr(1234567), '12,34,567');
      expect(formatInr(10000000), '1,00,00,000');
    });

    test('handles negatives', () {
      expect(formatInr(-1000), '-1,000');
      expect(formatInr(-1234567), '-12,34,567');
    });

    test('never emits an empty or malformed group', () {
      for (var n = 0; n < 200000; n += 137) {
        final out = formatInr(n);
        final digitsOnly = out.replaceAll(',', '');
        expect(int.parse(digitsOnly), n, reason: 'round-trip failed for $n');
        expect(out.startsWith(','), false);
        expect(out.endsWith(','), false);
        expect(out.contains(',,'), false);
      }
    });
  });

  group('asInt', () {
    test('reads the numeric types Postgres actually returns', () {
      expect(asInt(1200), 1200);
      expect(asInt(1200.0), 1200);
      expect(asInt(1200.4), 1200);
      expect(asInt(1200.6), 1201);
    });

    test('parses numeric strings, which some columns arrive as', () {
      expect(asInt('1200'), 1200);
      expect(asInt(' 1200 '), 1200);
    });

    test('falls back rather than throwing on junk', () {
      expect(asInt(null), 0);
      expect(asInt('abc'), 0);
      expect(asInt('abc', fallback: -1), -1);
    });
  });

  group('asDouble', () {
    test('reads ints, doubles and numeric strings', () {
      expect(asDouble(1200), 1200.0);
      expect(asDouble(1200.5), 1200.5);
      expect(asDouble('1200.50'), 1200.5);
    });

    test('falls back rather than throwing on junk', () {
      expect(asDouble(null), 0.0);
      expect(asDouble('nope'), 0.0);
    });
  });

  group('formatDateTime', () {
    test('formats an ISO string as day, month, year and 12-hour time', () {
      // 15 Sep 2026 15:42 UTC -> 3:42 pm in a +05:30-free environment is
      // asserted structurally rather than by exact string, because the value is
      // converted to local time.
      final out = formatDateTime('2026-09-15T15:42:00Z');
      expect(out, matches(RegExp(r'^\d{1,2} \w{3} \d{4}, \d{1,2}:\d{2} (am|pm)$')));
    });

    test('renders midnight and noon correctly on a 12-hour clock', () {
      final midnight = formatDateTime(DateTime(2026, 1, 5, 0, 0));
      expect(midnight, contains('12:00 am'));

      final noon = formatDateTime(DateTime(2026, 1, 5, 12, 0));
      expect(noon, contains('12:00 pm'));
    });

    test('uses two-digit minutes', () {
      expect(formatDateTime(DateTime(2026, 1, 5, 9, 5)), contains('9:05 am'));
    });

    test('abbreviates the month correctly across the year', () {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      for (var i = 0; i < 12; i++) {
        expect(
          formatDateTime(DateTime(2026, i + 1, 15, 10, 0)),
          contains(months[i]),
          reason: 'month ${i + 1} abbreviated incorrectly',
        );
      }
    });

    test('returns an empty string for unparseable input instead of throwing', () {
      expect(formatDateTime(null), '');
      expect(formatDateTime(''), '');
      expect(formatDateTime('not-a-date'), '');
      expect(formatDateTime(<String>['unexpected']), '');
    });
  });

  group('formatRelative', () {
    test('describes recent timestamps', () {
      final now = DateTime.now();
      expect(formatRelative(now), 'just now');
      expect(
        formatRelative(now.subtract(const Duration(minutes: 5))),
        '5m ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(hours: 3))),
        '3h ago',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 2))),
        '2d ago',
      );
    });

    test('does not produce a negative age for clock skew', () {
      expect(
        formatRelative(DateTime.now().add(const Duration(hours: 2))),
        'just now',
      );
    });

    test('returns an empty string for unparseable input', () {
      expect(formatRelative(null), '');
      expect(formatRelative('nonsense'), '');
    });
  });
}
