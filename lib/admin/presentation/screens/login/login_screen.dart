import 'package:flutter/material.dart';
import 'package:cricket_admin_panel/common/constants/app_colors.dart';
import 'package:cricket_admin_panel/common/responsive/admin_breakpoints.dart';
import '../layout/main_layout_screen.dart';

/// Administrator sign-in.
///
/// The credential check, the navigation on success and the failure message are
/// unchanged from the previous implementation. What changed is presentation:
/// the form is constrained rather than a fixed 400px box (which overflowed a
/// 360dp phone), it scrolls clear of the soft keyboard, the two text
/// controllers are now disposed, and the card is built from the shared
/// breakpoints and theme like the rest of the app.
///
/// Note: this screen compares two hardcoded strings. It is a placeholder, not
/// an authentication boundary.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    // The previous version never disposed these, so the controllers and their
    // native text input attachments outlived the screen.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (_emailController.text == 'admin@admin.com' &&
        _passwordController.text == 'admin123') {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid credentials. Use admin@admin.com / admin123',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = AdminBreakpoints.of(context);

    // The split layout needs real horizontal room. Below the expanded
    // breakpoint the form goes full width under a compact brand header.
    final useSplit = size.isExpanded;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (useSplit) const Expanded(flex: 5, child: _BrandPanel()),
            Expanded(
              // When the brand panel is present the form gets the smaller
              // share; alone it takes the full width.
              flex: useSplit ? 4 : 8,
              child: _LoginForm(
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _isLoading,
                onSubmit: _login,
                showCompactHeader: !useSplit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand panel shown beside the form on wide layouts.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF07301F), Color(0xFF0B8457)]
              : const [AppColors.primaryDarkGreen, Color(0xFF12A065)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(size: 56),
              const SizedBox(height: 22),
              Text(
                'TurfPro',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Admin console',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 44,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Manage grounds, owners, payouts and the configuration '
                'your booking apps read.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The credential form.
///
/// Wrapped in a scroll view and offset by [MediaQuery.viewInsetsOf] so the
/// submit button stays reachable above the soft keyboard, which the previous
/// fixed-height centred column did not allow for.
class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
    required this.showCompactHeader,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  /// True when there is no brand panel beside the form and the header has to
  /// carry the identity on its own.
  final bool showCompactHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            // Lift the card above the keyboard rather than letting it sit
            // underneath.
            bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Previously a hardcoded `width: 400`, which overflowed a 360dp
              // phone by 40px.
              minHeight: constraints.maxHeight - 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showCompactHeader) ...[
                        const Center(child: _BrandMark(size: 52)),
                        const SizedBox(height: 16),
                        Text(
                          'TurfPro',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDarkGreen,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Admin console',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ] else ...[
                        Text(
                          'Sign in',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your administrator credentials to continue.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 26),
                      ],

                      // Autofocus so the keyboard opens straight away on a
                      // phone instead of needing a tap first.
                      TextFormField(
                        controller: emailController,
                        autofocus: !showCompactHeader ? false : true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        style: theme.textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        // Submit from the keyboard, so the button is not the
                        // only way forward.
                        onFieldSubmitted: (_) => onSubmit(),
                        style: theme.textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 26),

                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: isLoading ? null : onSubmit,
                          icon: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded, size: 19),
                          label: Text(isLoading ? 'Signing in…' : 'Sign in'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryDarkGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The app mark: a cricket glyph in a rounded brand-coloured square.
///
/// Matches the sidebar header so the identity reads the same before and after
/// signing in.
class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGreen,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(
        Icons.sports_cricket_rounded,
        color: Colors.white,
        size: size * 0.56,
      ),
    );
  }
}
