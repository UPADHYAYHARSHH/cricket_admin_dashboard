import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_admin_panel/admin/presentation/screens/login/login_screen.dart';

/// Widths the layout has to survive: a small phone, a common phone, a tablet
/// and a desktop window.
const widths = <double>[320, 360, 390, 430, 700, 834, 1000, 1440];

/// A pump helper that resizes the real surface.
///
/// A `MediaQueryData(size:)` override would not work here: the form derives
/// its layout from `AdminBreakpoints`, which reads the window size.
Future<void> pumpLogin(WidgetTester tester, double width, {double height = 800}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  return tester.pumpWidget(const MaterialApp(home: LoginScreen()));
}

/// The submit button.
///
/// `FilledButton.icon` builds a private subclass, so `find.byType(FilledButton)`
/// does not match it. Matching on the base type does.
final submitButton =
    find.byWidgetPredicate((widget) => widget is FilledButton);

void main() {
  group('layout', () {
    for (final width in widths) {
      testWidgets('renders the form without overflow at ${width}px',
          (WidgetTester tester) async {
        await pumpLogin(tester, width);

        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Sign in'), findsWidgets);

        // A RenderFlex overflow reports itself as a caught exception, so this
        // is the guard against the old fixed 400px card overflowing a 360dp
        // phone.
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('stays clear of the soft keyboard', (WidgetTester tester) async {
      // The old centred column had no scroll view, so a 300px keyboard covered
      // the submit button outright.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(tester.takeException(), isNull);
      // The button is still in the tree and can be scrolled to.
      expect(submitButton, findsOneWidget);
    });

    testWidgets('shows the split brand panel on a desktop window',
        (WidgetTester tester) async {
      await pumpLogin(tester, 1440);

      expect(find.byIcon(Icons.sports_cricket_rounded), findsOneWidget);
      expect(find.text('TurfPro'), findsOneWidget);
      expect(find.text('Admin console'), findsOneWidget);
    });

    testWidgets('still shows a brand header on a phone',
        (WidgetTester tester) async {
      await pumpLogin(tester, 360);

      // The form is full width alone, so the header has to carry the identity.
      expect(find.text('TurfPro'), findsOneWidget);
      expect(find.text('Admin console'), findsOneWidget);
    });
  });

  group('fields', () {
    testWidgets('are labelled and typed for their content',
        (WidgetTester tester) async {
      await pumpLogin(tester, 390);

      // `TextFormField` does not expose these, but the `TextField` it builds
      // does.
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.length, 2);

      final email = fields.elementAt(0);
      expect(email.keyboardType, TextInputType.emailAddress);
      expect(email.textInputAction, TextInputAction.next);
      expect(email.decoration?.labelText, 'Email');

      final password = fields.elementAt(1);
      expect(password.obscureText, isTrue);
      expect(password.textInputAction, TextInputAction.done);
      expect(password.decoration?.labelText, 'Password');
    });

    testWidgets('password stays obscured', (WidgetTester tester) async {
      await pumpLogin(tester, 390);

      // No reveal affordance is offered: this screen is a placeholder, and
      // adding one would imply a protection it does not provide.
      expect(find.byIcon(Icons.visibility_rounded), findsNothing);
      expect(find.byIcon(Icons.visibility_off_rounded), findsNothing);
    });
  });

  group('behaviour is unchanged', () {
    testWidgets('rejects wrong credentials with the original message',
        (WidgetTester tester) async {
      await pumpLogin(tester, 390);

      await tester.enterText(find.byType(TextFormField).at(0), 'wrong@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'nope');
      await tester.tap(submitButton);
      await tester.pump();
      // The implementation has a deliberate one second delay.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(
        find.text('Invalid credentials. Use admin@admin.com / admin123'),
        findsOneWidget,
      );
    });

    testWidgets('blocks a second submit while the first is in flight',
        (WidgetTester tester) async {
      await pumpLogin(tester, 390);

      await tester.enterText(find.byType(TextFormField).at(0), 'wrong@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'nope');
      await tester.tap(submitButton);
      await tester.pump();

      final disabled = tester.widget<FilledButton>(submitButton);
      expect(disabled.onPressed, isNull);
      expect(find.textContaining('Signing in'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('disposes its controllers without throwing',
        (WidgetTester tester) async {
      await pumpLogin(tester, 390);

      // Replacing the screen unmounts it, which runs dispose on the
      // controllers. The previous version leaked them.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

