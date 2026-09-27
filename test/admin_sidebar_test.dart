import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_admin_panel/admin/presentation/screens/layout/admin_sidebar.dart';

void main() {
  group('adminNavGroups', () {
    List<AdminNavItem> allItems() =>
        adminNavGroups.expand((group) => group.items).toList();

    test('covers every screen index exactly once', () {
      // The sidebar selects an `IndexedStack` index. A missing or duplicated
      // index means a nav entry opens the wrong screen, or that one screen can
      // only be reached from nowhere. This is the invariant that breaks
      // silently, so it is asserted rather than left to review.
      final indices = allItems().map((item) => item.index).toList()..sort();

      expect(
        indices,
        List<int>.generate(10, (i) => i),
        reason: 'nav indices must be 0..9 with no gaps or duplicates',
      );
    });

    test('has no duplicate labels', () {
      final labels = allItems().map((item) => item.label).toList();
      expect(labels.toSet().length, labels.length);
    });

    test('every item has a non-empty label', () {
      for (final item in allItems()) {
        expect(item.label.trim(), isNotEmpty, reason: 'index ${item.index}');
      }
    });

    test('no group is empty', () {
      for (final group in adminNavGroups) {
        expect(group.items, isNotEmpty, reason: 'group "${group.label}"');
      }
    });

    test('only the first group may be unlabelled', () {
      // A heading-less group in the middle of the list reads as a continuation
      // of the previous group, which is how the old sidebar ended up with
      // "App Config" apparently belonging to the notifications section.
      for (var i = 1; i < adminNavGroups.length; i++) {
        expect(
          adminNavGroups[i].label,
          isNotNull,
          reason: 'group at position $i needs a heading',
        );
      }
    });

    test('Payouts is grouped with the marketplace, not trailing the list', () {
      // Index 9 is last in the IndexedStack but should not be last on screen.
      final visualOrder = allItems().map((item) => item.label).toList();
      expect(visualOrder.indexOf('Payouts'),
          lessThan(visualOrder.indexOf('Send notification')));
    });
  });

  group('AdminSidebar', () {
    // A `Drawer` child is not built until the drawer is opened, so each test
    // opens it before asserting.
    Future<void> pumpOpenDrawer(
      WidgetTester tester, {
      required double width,
      int selectedIndex = 0,
      int pendingApprovals = 0,
      ValueChanged<int>? onSelect,
    }) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 900)),
            child: Scaffold(
              key: scaffoldKey,
              drawer: Drawer(
                child: AdminSidebar(
                  isDrawer: true,
                  selectedIndex: selectedIndex,
                  pendingApprovals: pendingApprovals,
                  onSelect: onSelect ?? (_) {},
                  onLogout: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Open via the scaffold state rather than tapping the menu button, whose
      // tooltip text varies between Flutter versions.
      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('renders every navigation entry', (WidgetTester tester) async {
      await pumpOpenDrawer(tester, width: 400);

      // The nav list is a lazy `ListView`, so on a short viewport the last
      // entries are built only after scrolling. Scroll to each one rather than
      // assuming it is laid out, which also proves the list is scrollable.
      for (final item in adminNavGroups.expand((g) => g.items)) {
        await tester.scrollUntilVisible(
          find.text(item.label),
          80,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.text(item.label),
          findsOneWidget,
          reason: 'missing nav entry "${item.label}"',
        );
      }
    });

    testWidgets('shows a group heading for each labelled group',
        (WidgetTester tester) async {
      await pumpOpenDrawer(tester, width: 400);

      for (final group in adminNavGroups) {
        if (group.label == null) continue;

        await tester.scrollUntilVisible(
          find.text(group.label!.toUpperCase()),
          80,
          scrollable: find.byType(Scrollable).first,
        );

        // Assert as we go: scrolling to the last group takes the earlier
        // headings off screen, so they cannot all be checked at the end.
        expect(
          find.text(group.label!.toUpperCase()),
          findsOneWidget,
          reason: 'missing group heading "${group.label}"',
        );
      }
    });

    testWidgets('reports the tapped entry index', (WidgetTester tester) async {
      final tapped = <int>[];
      await pumpOpenDrawer(tester, width: 400, onSelect: tapped.add);

      // 'Payouts' is index 9 but sits in the Marketplace group, so this also
      // confirms the visual order and the index are independent.
      await tester.scrollUntilVisible(
        find.text('Payouts'),
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Payouts'));
      await tester.pump();

      expect(tapped, [9]);
    });

    testWidgets('drawer width is clamped to a usable range on a phone',
        (WidgetTester tester) async {
      await pumpOpenDrawer(tester, width: 320);
      final width = tester.getSize(find.byType(AdminSidebar)).width;

      // 86% of a 320px screen, but never so narrow the labels truncate.
      expect(width, greaterThanOrEqualTo(240));
      expect(width, lessThan(320));
    });

    testWidgets('drawer never covers the whole screen',
        (WidgetTester tester) async {
      await pumpOpenDrawer(tester, width: 400);
      final width = tester.getSize(find.byType(AdminSidebar)).width;

      // A full-width drawer leaves no visible content to dismiss against.
      expect(width, lessThan(400));
    });

    testWidgets('shows the pending badge only on Approvals',
        (WidgetTester tester) async {
      await pumpOpenDrawer(tester, width: 400, pendingApprovals: 7);

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('hides the badge when nothing is pending',
        (WidgetTester tester) async {
      await pumpOpenDrawer(tester, width: 400, pendingApprovals: 0);

      // A '0' pill would read as "zero approvals" and add noise.
      expect(find.text('0'), findsNothing);
    });
  });
}
