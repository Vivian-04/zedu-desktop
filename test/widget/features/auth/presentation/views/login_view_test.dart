import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Fake notifier that avoids GetIt/locator setup while remaining type-compatible
// with authNotifierProvider (which is NotifierProvider<AuthNotifier, AuthState>).
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({
    AuthState initial = const AuthState(status: AuthStatus.unauthenticated),
    void Function(String email, String password)? onLogin,
  }) : _initial = initial,
       _onLogin = onLogin;

  final AuthState _initial;
  final void Function(String email, String password)? _onLogin;

  @override
  AuthState build() => _initial;

  @override
  Future<void> login({required String email, required String password}) async {
    _onLogin?.call(email, password);
  }

  @override
  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

Widget buildLoginViewUnderTest({FakeAuthNotifier? notifier}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier ?? FakeAuthNotifier()),
    ],
    child: const MaterialApp(home: LoginView()),
  );
}

void main() {
  group('LoginView', () {
    testWidgets('renders form fields and login button when unauthenticated', (
      tester,
    ) async {
      await tester.pumpWidget(buildLoginViewUnderTest());
      await tester.pump();

      expect(find.text('Login to Zedu'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets(
      'aligns remember me checkbox with the form and keeps it tappable',
      (tester) async {
        // The desktop login form and the mobile-width login form.
        const surfaceSizes = [Size(1440, 1024), Size(800, 600)];
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final size in surfaceSizes) {
          await tester.binding.setSurfaceSize(size);

          await tester.pumpWidget(buildLoginViewUnderTest());
          await tester.pump();

          final checkbox = find.byType(Checkbox);
          final emailField = find.byType(TextFormField).first;
          final rememberMeText = find.text('Remember me');
          final forgotPassword = find.text('Forgot Password?');

          // The checkbox paints its 18px visual square centered inside its
          // tap-target box. Before the fix the box was the default 48x48, so
          // the square started 15px to the right of the form's left edge.
          // Assert the square itself (not just the box) aligns with the form.
          final checkboxBox = tester.getRect(checkbox);
          final paintedSquareLeft =
              checkboxBox.left + (checkboxBox.width - Checkbox.width) / 2;
          expect(
            paintedSquareLeft - tester.getRect(emailField).left,
            inInclusiveRange(0.0, 2.0),
            reason:
                'checkbox square should align with the form left edge '
                'at surface size $size',
          );

          // The label stays vertically centered with the checkbox.
          expect(
            tester.getCenter(checkbox).dy,
            closeTo(tester.getCenter(rememberMeText).dy, 1.0),
          );

          // "Forgot Password?" remains aligned to the form's right edge.
          expect(
            tester.getRect(forgotPassword).right,
            closeTo(tester.getRect(emailField).right, 1.0),
          );

          // The checkbox retains its existing functionality: tapping it
          // toggles its value. (State is preserved between surface sizes,
          // so compare against whatever the current value is.)
          final wasChecked = tester.widget<Checkbox>(checkbox).value ?? false;
          await tester.tap(checkbox);
          await tester.pump();

          expect(tester.widget<Checkbox>(checkbox).value, !wasChecked);
        }
      },
    );

    testWidgets('shows loading spinner when auth status is unknown', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildLoginViewUnderTest(
          notifier: FakeAuthNotifier(
            initial: const AuthState(status: AuthStatus.unknown),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Login to Zedu'), findsNothing);
    });

    testWidgets('shows validation errors when submitting empty form', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildLoginViewUnderTest());
      await tester.pump();

      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('calls login with correct credentials when form is valid', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? capturedEmail;
      String? capturedPassword;

      await tester.pumpWidget(
        buildLoginViewUnderTest(
          notifier: FakeAuthNotifier(
            onLogin: (email, password) {
              capturedEmail = email;
              capturedPassword = password;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Secret123');

      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(capturedEmail, 'user@example.com');
      expect(capturedPassword, 'Secret123');
    });
  });
}
