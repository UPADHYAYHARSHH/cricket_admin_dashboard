import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';

void main() {
  group('AdminBreakpoints.sizeFor', () {
    test('classifies phone widths as compact', () {
      expect(AdminBreakpoints.sizeFor(320), AdminSize.compact);
      expect(AdminBreakpoints.sizeFor(360), AdminSize.compact);
      expect(AdminBreakpoints.sizeFor(390), AdminSize.compact);
      expect(AdminBreakpoints.sizeFor(430), AdminSize.compact);
      expect(AdminBreakpoints.sizeFor(699), AdminSize.compact);
    });

    test('classifies tablet and small laptop as medium', () {
      expect(AdminBreakpoints.sizeFor(700), AdminSize.medium);
      expect(AdminBreakpoints.sizeFor(834), AdminSize.medium);
      expect(AdminBreakpoints.sizeFor(999), AdminSize.medium);
    });

    test('classifies desktop as expanded', () {
      expect(AdminBreakpoints.sizeFor(1000), AdminSize.expanded);
      expect(AdminBreakpoints.sizeFor(1440), AdminSize.expanded);
      expect(AdminBreakpoints.sizeFor(2560), AdminSize.expanded);
    });

    test('boundaries are contiguous with no gaps or overlaps', () {
      // Every width must land in exactly one bucket, and the transitions must
      // happen exactly on the documented constants.
      expect(AdminBreakpoints.sizeFor(AdminBreakpoints.medium - 1),
          AdminSize.compact);
      expect(AdminBreakpoints.sizeFor(AdminBreakpoints.medium),
          AdminSize.medium);
      expect(AdminBreakpoints.sizeFor(AdminBreakpoints.expanded - 1),
          AdminSize.medium);
      expect(AdminBreakpoints.sizeFor(AdminBreakpoints.expanded),
          AdminSize.expanded);
    });
  });

  group('size predicates', () {
    test('are mutually exclusive and collectively exhaustive', () {
      for (final size in AdminSize.values) {
        final flags = [size.isCompact, size.isMedium, size.isExpanded];
        expect(flags.where((f) => f).length, 1,
            reason: '$size matched more than one size flag');
      }
    });

    test('isAtLeastMedium is true for everything except compact', () {
      for (final size in AdminSize.values) {
        expect(size.isAtLeastMedium, size != AdminSize.compact);
      }
    });
  });

  group('table space', () {
    test('a phone never gets a data table', () {
      expect(AdminBreakpoints.sizeFor(360), AdminSize.compact);
      expect(360 >= AdminBreakpoints.table, isFalse);
    });

    test('the table threshold is above the expanded breakpoint', () {
      // A permanent sidebar takes space, so the table threshold must sit above
      // the point where the sidebar appears.
      expect(AdminBreakpoints.table, greaterThan(AdminBreakpoints.expanded));
    });
  });

  group('segmented controls', () {
    testWidgets('drop the icon only in the narrowest range', (
      WidgetTester tester,
    ) async {
      Future<bool> isIconless(double width) async {
        late bool value;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Builder(
              builder: (context) {
                value = AdminBreakpoints.segmentedControlIsIconless(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        return value;
      }

      expect(await isIconless(320), isTrue);
      expect(await isIconless(360), isTrue);
      expect(await isIconless(
        AdminBreakpoints.segmentedControlIconFloor - 1,
      ), isTrue);
      expect(
        await isIconless(AdminBreakpoints.segmentedControlIconFloor),
        isFalse,
      );
      expect(await isIconless(1440), isFalse);
    });

    test('the icon floor is narrower than the phone breakpoint', () {
      // A split-screen window can be wider than the icon floor while still
      // using a phone layout, so the two thresholds are not the same thing.
      expect(
        AdminBreakpoints.segmentedControlIconFloor,
        lessThan(AdminBreakpoints.medium),
      );
    });
  });

  group('page padding', () {
    testWidgets('tightens on a phone and relaxes on desktop', (
      WidgetTester tester,
    ) async {
      Future<double> paddingFor(double width) async {
        late double value;
        // Inject MediaQuery directly rather than resizing the test surface,
        // which is not applied synchronously.
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Builder(
              builder: (context) {
                value = AdminBreakpoints.pagePadding(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        return value;
      }

      final compact = await paddingFor(390);
      final medium = await paddingFor(834);
      final expanded = await paddingFor(1440);

      expect(compact, lessThan(medium));
      expect(medium, lessThanOrEqualTo(expanded));
    });
  });
}
