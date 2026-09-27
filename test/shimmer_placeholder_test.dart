import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_admin_panel/common/widgets/shimmer_placeholder.dart';

/// Resizes the test surface.
///
/// A `MediaQueryData(size:)` override only changes what `MediaQuery.of`
/// reports; a `LayoutBuilder` still measures against the real 800x600 test
/// surface. Every skeleton here derives its column count from its own
/// constraints, so the surface itself has to be resized.
void setSurface(WidgetTester tester, double width, double height) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Wraps [child] in what a shimmer needs: a theme and a Material ancestor.
Widget host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

/// Number of distinct rows a wrap-based skeleton laid out.
///
/// Counting distinct vertical positions is how you tell "one column of N" from
/// "N columns on one row" without depending on the grid implementation.
int rowCount(WidgetTester tester, Finder finder) {
  final tops = <double>{};
  for (var i = 0; i < finder.evaluate().length; i++) {
    tops.add(tester.getTopLeft(finder.at(i)).dy);
  }
  return tops.length;
}

/// Finds the leading icon box of a tile, which is one per tile.
///
/// `ShimmerTileGrid` draws a 34x34 icon plus two text lines per tile, so the
/// icon is what identifies a tile boundary.
final tileIcon = find.byWidgetPredicate(
  (widget) =>
      widget is ShimmerBox && widget.width == 34 && widget.height == 34,
);

void main() {
  group('primitives', () {
    testWidgets('AppShimmer renders its child', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(const AppShimmer(child: ShimmerLine(width: 100))),
      );

      expect(find.byType(ShimmerLine), findsOneWidget);
    });

    testWidgets('ShimmerLine honours an explicit width',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              ShimmerLine(width: 120),
              ShimmerLine(width: 40),
            ],
          ),
        ),
      );

      expect(tester.getSize(find.byType(ShimmerLine).at(0)).width, 120);
      expect(tester.getSize(find.byType(ShimmerLine).at(1)).width, 40);
    });

    testWidgets('ShimmerCircle is round and the requested size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              ShimmerCircle(size: 56),
              ShimmerCircle(size: 24),
            ],
          ),
        ),
      );

      expect(tester.getSize(find.byType(ShimmerCircle).at(0)).width, 56);
      expect(tester.getSize(find.byType(ShimmerCircle).at(1)).height, 24);
    });
  });

  group('ShimmerTileGrid', () {
    // Each tile's leading icon is one 34x34 box, so it marks tile boundaries.
    Future<int> rowsFor(WidgetTester tester, double width) async {
      setSurface(tester, width, 900);
      await tester.pumpWidget(host(const ShimmerTileGrid()));
      return rowCount(tester, tileIcon);
    }

    testWidgets('defaults to two columns on a phone', (
      WidgetTester tester,
    ) async {
      // 4 tiles at 2 columns is 2 rows.
      expect(await rowsFor(tester, 360), 2);
    });

    testWidgets('honours an explicit single column', (
      WidgetTester tester,
    ) async {
      setSurface(tester, 360, 900);
      await tester.pumpWidget(
        host(
          const ShimmerTileGrid(
            count: 4,
            columnsAtExpanded: 4,
            columnsAtMedium: 2,
            columnsAtCompact: 1,
          ),
        ),
      );

      expect(rowCount(tester, tileIcon), 4);
    });

    testWidgets('uses fewer rows as the window widens', (
      WidgetTester tester,
    ) async {
      final phone = await rowsFor(tester, 390);
      final desktop = await rowsFor(tester, 1440);

      // The point of the grid is that the skeleton reflows the same way the
      // real content does.
      expect(desktop, lessThan(phone));
    });

    testWidgets('never renders more tiles than requested', (
      WidgetTester tester,
    ) async {
      setSurface(tester, 1440, 900);
      await tester.pumpWidget(host(const ShimmerTileGrid(count: 2)));

      expect(tileIcon, findsNWidgets(2));
    });
  });

  group('ShimmerTable', () {
    testWidgets('renders a header plus the requested body rows', (
      WidgetTester tester,
    ) async {
      setSurface(tester, 1200, 900);
      await tester.pumpWidget(
        host(const ShimmerTable(rows: 4, columns: 3)),
      );

      // Header row (3) + 4 body rows x 3 columns.
      expect(find.byType(ShimmerLine), findsNWidgets(3 + 4 * 3));
    });
  });

  group('ShimmerCardList', () {
    testWidgets('renders the requested number of cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const ShimmerCardList(count: 5)));

      expect(find.byType(ShimmerCircle), findsNWidgets(5));
    });

    testWidgets('omits the avatar when the real card has none', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const ShimmerCardList(count: 3, avatar: false)),
      );

      expect(find.byType(ShimmerCircle), findsNothing);
    });
  });

  group('ShimmerConfigGrid', () {
    testWidgets('is a single column on a phone', (WidgetTester tester) async {
      setSurface(tester, 360, 900);
      await tester.pumpWidget(host(const ShimmerConfigGrid(count: 3)));

      expect(rowCount(tester, find.byType(ShimmerConfigCard)), 3);
    });

    testWidgets('is two columns at tablet width', (WidgetTester tester) async {
      setSurface(tester, 800, 900);
      await tester.pumpWidget(host(const ShimmerConfigGrid(count: 4)));

      expect(rowCount(tester, find.byType(ShimmerConfigCard)), 2);
    });

    testWidgets('goes three columns on desktop', (WidgetTester tester) async {
      setSurface(tester, 1400, 900);
      await tester.pumpWidget(host(const ShimmerConfigGrid(count: 3)));

      expect(rowCount(tester, find.byType(ShimmerConfigCard)), 1);
    });
  });

  group('ShimmerPage', () {
    testWidgets('renders every supplied child', (WidgetTester tester) async {
      setSurface(tester, 500, 900);
      await tester.pumpWidget(
        host(
          const ShimmerPage(
            children: [
              ShimmerBanner(),
              SizedBox(height: 10),
              ShimmerFilterBar(),
              SizedBox(height: 10),
              ShimmerConfigGrid(),
            ],
          ),
        ),
      );

      expect(find.byType(ShimmerBanner), findsOneWidget);
      expect(find.byType(ShimmerFilterBar), findsOneWidget);
      expect(find.byType(ShimmerConfigGrid), findsOneWidget);
    });

    testWidgets('tall content does not overflow the viewport', (
      WidgetTester tester,
    ) async {
      // A tall skeleton must stay inside the surface rather than throwing a
      // layout overflow.
      setSurface(tester, 400, 400);
      await tester.pumpWidget(
        host(
          const ShimmerPage(
            children: [
              ShimmerConfigGrid(count: 3),
              ShimmerConfigGrid(count: 3),
              ShimmerConfigGrid(count: 3),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
