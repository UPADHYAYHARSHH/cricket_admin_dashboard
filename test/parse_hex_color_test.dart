import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_admin_panel/admin/presentation/screens/sports_management/widgets/sport_views.dart';

void main() {
  group('parseHexColor', () {
    test('parses a six-digit hex with a leading hash', () {
      expect(parseHexColor('#1B5E20'), const Color(0xFF1B5E20));
    });

    test('parses a six-digit hex without a leading hash', () {
      expect(parseHexColor('1B5E20'), const Color(0xFF1B5E20));
    });

    test('expands a three-digit hex', () {
      // The previous inline int.tryParse('#F00'.replaceFirst('#','0xFF'))
      // produced null here, so the swatch silently fell back to grey.
      expect(parseHexColor('#F00'), const Color(0xFFFF0000));
      expect(parseHexColor('#0A7'), const Color(0xFF00AA77));
    });

    test('respects an explicit eight-digit alpha value', () {
      expect(parseHexColor('#801B5E20'), const Color(0x801B5E20));
    });

    test('tolerates surrounding whitespace', () {
      expect(parseHexColor('  #1B5E20  '), const Color(0xFF1B5E20));
    });

    test('returns null for values it cannot represent', () {
      expect(parseHexColor(null), isNull);
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('#'), isNull);
      expect(parseHexColor('#12345'), isNull);
      expect(parseHexColor('rebeccapurple'), isNull);
      expect(parseHexColor('#GGGGGG'), isNull);
    });

    test('round-trips the default sport colour', () {
      expect(parseHexColor('#1B5E20'), isNotNull);
    });
  });
}
