
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/auth_providers.dart';

// ═════════════════════════════════════════════════════════════════════════════
// COLORS
// ═════════════════════════════════════════════════════════════════════════════

class _AuthColors {
  _AuthColors._();

  static const Color deepNavy = Color(0xFF030E1C);
  static const Color blue = Color(0xFF2563EB);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color cyan = Color(0xFF93C5FD);
}

// ═════════════════════════════════════════════════════════════════════════════
// TOAST TYPE
// ═════════════════════════════════════════════════════════════════════════════

enum _ToastType { error, warning, success }

// ═════════════════════════════════════════════════════════════════════════════
// FORGOT PASSWORD STEP
// ═════════════════════════════════════════════════════════════════════════════

enum _ForgotPasswordStep {
  identifier,
  otp,
  newPassword,
}

// ═════════════════════════════════════════════════════════════════════════════
// ROUTE WRAPPERS
// ═════════════════════════════════════════════════════════════════════════════

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const AuthPage(initialTab: 0);
}

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) => const AuthPage(initialTab: 1);
}

// ═════════════════════════════════════════════════════════════════════════════
// AUTH PAGE
// ═════════════════════════════════════════════════════════════════════════════

class AuthPage extends StatefulWidget {
  final int initialTab;

  const AuthPage({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // ───────────────────────────────────────────────────────────────────────────
  // LOGIN
  // ───────────────────────────────────────────────────────────────────────────

  final _loginKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();

  bool _loginObscure = true;

  // ───────────────────────────────────────────────────────────────────────────
  // SIGNUP
  // ───────────────────────────────────────────────────────────────────────────

  final _signupKey = GlobalKey<FormState>();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPass = TextEditingController();
  final _signupConfirm = TextEditingController();

  bool _signupObscure = true;
  bool _confirmObscure = true;

  // ───────────────────────────────────────────────────────────────────────────
  // FORGOT PASSWORD
  // ───────────────────────────────────────────────────────────────────────────

  bool _isForgotPassword = false;

  _ForgotPasswordStep _forgotPasswordStep =
      _ForgotPasswordStep.identifier;

  final _forgotIdentifierKey = GlobalKey<FormState>();
  final _forgotOtpKey = GlobalKey<FormState>();
  final _forgotPasswordKey = GlobalKey<FormState>();

  final _forgotIdentifier = TextEditingController();
  final _forgotOtp = TextEditingController();
  final _forgotNewPassword = TextEditingController();
  final _forgotConfirmPassword = TextEditingController();

  bool _forgotNewPasswordObscure = true;
  bool _forgotConfirmPasswordObscure = true;

  // ───────────────────────────────────────────────────────────────────────────
  // TOAST
  // ───────────────────────────────────────────────────────────────────────────

  OverlayEntry? _activeToast;

  @override
  void initState() {
    super.initState();

    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    _tabs.addListener(() {
      if (_tabs.indexIsChanging && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();

    _loginEmail.dispose();
    _loginPass.dispose();

    _signupName.dispose();
    _signupEmail.dispose();
    _signupPass.dispose();
    _signupConfirm.dispose();

    _forgotIdentifier.dispose();
    _forgotOtp.dispose();
    _forgotNewPassword.dispose();
    _forgotConfirmPassword.dispose();

    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final ok = await auth.login(
      username: _loginEmail.text.trim(),
      password: _loginPass.text,
    );

    if (!mounted) return;

    if (ok) {
      _snack(
        'Welcome back!',
        type: _ToastType.success,
      );

      await Future.delayed(
        const Duration(milliseconds: 600),
      );

      if (mounted) {
        context.go('/home');
      }
    } else {
      _snack(
        _friendlyLoginError(auth.errorMessage),
        type: _ToastType.error,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNUP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _signup() async {
    if (!_signupKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final ok = await auth.signup(
      name: _signupName.text.trim(),
      email: _signupEmail.text.trim(),
      password: _signupPass.text,
      confirmPassword: _signupConfirm.text,
    );

    if (!mounted) return;

    if (ok) {
      _snack(
        'Account created! Welcome aboard 🎉',
        type: _ToastType.success,
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (mounted) {
        context.go('/home');
      }
    } else {
      _snack(
        _friendlySignupError(auth.errorMessage),
        type: _ToastType.error,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD
  // ═══════════════════════════════════════════════════════════════════════════

  void _openForgotPassword() {
    setState(() {
      _isForgotPassword = true;
      _forgotPasswordStep = _ForgotPasswordStep.identifier;

      _forgotIdentifier.clear();
      _forgotOtp.clear();
      _forgotNewPassword.clear();
      _forgotConfirmPassword.clear();

      _forgotNewPasswordObscure = true;
      _forgotConfirmPasswordObscure = true;
    });
  }

  void _backToLogin() {
    setState(() {
      _isForgotPassword = false;
      _forgotPasswordStep = _ForgotPasswordStep.identifier;

      _forgotIdentifier.clear();
      _forgotOtp.clear();
      _forgotNewPassword.clear();
      _forgotConfirmPassword.clear();
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REQUEST OTP
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _requestPasswordReset() async {
    if (!_forgotIdentifierKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final ok = await auth.requestPasswordReset(
      identifier: _forgotIdentifier.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        _forgotPasswordStep = _ForgotPasswordStep.otp;
      });

      _snack(
        'A verification code has been sent to your registered email.',
        type: _ToastType.success,
      );
    } else {
      _snack(
        _friendlyForgotPasswordError(auth.errorMessage),
        type: _ToastType.error,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // VERIFY OTP
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _verifyResetOtp() async {
    if (!_forgotOtpKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final ok = await auth.verifyPasswordResetOtp(
      identifier: _forgotIdentifier.text.trim(),
      otp: _forgotOtp.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        _forgotPasswordStep = _ForgotPasswordStep.newPassword;
      });
    } else {
      _snack(
        _friendlyOtpError(auth.errorMessage),
        type: _ToastType.error,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RESET PASSWORD
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _resetPassword() async {
    if (!_forgotPasswordKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final ok = await auth.resetPassword(
    
      newPassword: _forgotNewPassword.text,
      confirmPassword: _forgotConfirmPassword.text,
    );

    if (!mounted) return;

    if (ok) {
      _snack(
        'Password updated successfully. Please log in.',
        type: _ToastType.success,
      );

      await Future.delayed(
        const Duration(milliseconds: 900),
      );

      if (!mounted) return;

      _backToLogin();
    } else {
      _snack(
        _friendlyResetPasswordError(auth.errorMessage),
        type: _ToastType.error,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR MESSAGES
  // ═══════════════════════════════════════════════════════════════════════════

  String _friendlyLoginError(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Login failed. Please try again.';
    }

    final msg = raw.toLowerCase().trim();

    if (msg.contains('password') &&
        (msg.contains('incorrect') ||
            msg.contains('wrong') ||
            msg.contains('invalid') ||
            msg.contains('mismatch'))) {
      return 'Incorrect username or password';
    }

    if (msg.contains('invalid credential') ||
        msg.contains('invalid credentials') ||
        msg.contains('unauthorized') ||
        msg.contains('authentication failed')) {
      return 'Incorrect username or password.';
    }

    if ((msg.contains('user') ||
            msg.contains('username') ||
            msg.contains('account')) &&
        (msg.contains('not found') ||
            msg.contains('does not exist') ||
            msg.contains('no account') ||
            msg.contains('doesn\'t exist') ||
            msg.contains('unknown'))) {
      return 'No account found with that username. Please check or sign up.';
    }

    if (msg.contains('too many') ||
        msg.contains('rate limit') ||
        msg.contains('attempts')) {
      return 'Too many failed attempts. Please wait a moment and try again.';
    }

    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('socket')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (msg.contains('server') ||
        msg.contains('500') ||
        msg.contains('internal server')) {
      return 'Server error. Please try again in a moment.';
    }

    return raw;
  }

  String _friendlySignupError(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Signup failed. Please try again.';
    }

    final msg = raw.toLowerCase();

    if (msg.contains('email') &&
        (msg.contains('taken') ||
            msg.contains('exist') ||
            msg.contains('already'))) {
      return 'That email is already registered. Try logging in instead.';
    }

    if (msg.contains('username') &&
        (msg.contains('taken') ||
            msg.contains('exist') ||
            msg.contains('already'))) {
      return 'That username is already taken. Please choose another.';
    }

    if (msg.contains('password') && msg.contains('weak')) {
      return 'Password is too weak. Use at least 8 characters with letters and numbers.';
    }

    if (msg.contains('password') && msg.contains('match')) {
      return 'Passwords do not match. Please re-enter them.';
    }

    if (msg.contains('email') && msg.contains('invalid')) {
      return 'Please enter a valid email address.';
    }

    if (msg.contains('name') && msg.contains('required')) {
      return 'Full name is required.';
    }

    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (msg.contains('server') ||
        msg.contains('500') ||
        msg.contains('internal')) {
      return 'Server error. Please try again in a moment.';
    }

    return raw;
  }

  String _friendlyForgotPasswordError(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Unable to start password recovery. Please try again.';
    }

    final msg = raw.toLowerCase();

    if (msg.contains('not found') ||
        msg.contains('does not exist') ||
        msg.contains('no account') ||
        msg.contains('unknown user')) {
      return 'No account was found with that username or email.';
    }

    if (msg.contains('email') && msg.contains('not')) {
      return 'This account does not have a registered email address.';
    }

    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (msg.contains('server') ||
        msg.contains('500') ||
        msg.contains('internal')) {
      return 'Server error. Please try again in a moment.';
    }

    return raw;
  }

  String _friendlyOtpError(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Invalid verification code. Please try again.';
    }

    final msg = raw.toLowerCase();

    if (msg.contains('expired')) {
      return 'This verification code has expired. Please request a new one.';
    }

    if (msg.contains('invalid') ||
        msg.contains('incorrect') ||
        msg.contains('wrong')) {
      return 'Incorrect verification code. Please try again.';
    }

    return raw;
  }

  String _friendlyResetPasswordError(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Unable to reset your password. Please try again.';
    }

    final msg = raw.toLowerCase();

    if (msg.contains('password') && msg.contains('match')) {
      return 'Passwords do not match.';
    }

    if (msg.contains('weak')) {
      return 'Password is too weak. Use at least 8 characters with letters and numbers.';
    }

    if (msg.contains('expired')) {
      return 'Your verification code has expired. Please start again.';
    }

    return raw;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOAST
  // ═══════════════════════════════════════════════════════════════════════════

  void _snack(
    String msg, {
    _ToastType type = _ToastType.error,
  }) {
    if (_activeToast != null) {
      try {
        _activeToast!.remove();
      } catch (_) {}

      _activeToast = null;
    }

    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 24,
        left: 24,
        right: 24,
        child: Center(
          child: _AuthToast(
            message: msg,
            type: type,
            onDismiss: () {
              if (entry.mounted) {
                entry.remove();
              }

              if (_activeToast == entry) {
                _activeToast = null;
              }
            },
          ),
        ),
      ),
    );

    _activeToast = entry;

    overlay.insert(entry);

    final duration = type == _ToastType.success
        ? const Duration(milliseconds: 2500)
        : const Duration(seconds: 4);

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }

      if (_activeToast == entry) {
        _activeToast = null;
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: _AuthColors.deepNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _HeroPanel(),
          if (isDesktop) _desktopAuth() else _mobileAuth(),
          const _AuthTopBar(),
        ],
      ),
    );
  }

  Widget _desktopAuth() {
    return Positioned(
      right: 150,
      top: 0,
      bottom: 0,
      child: Center(
        child: SizedBox(
          width: 420,
          height: 600,
          child: _authGlassCard(),
        ),
      ),
    );
  }

  Widget _mobileAuth() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: _authGlassCard(mobile: true),
    );
  }

  Widget _authGlassCard({
    bool mobile = false,
  }) {
    const radius = 24.0;

    return RepaintBoundary(
      child: _LiquidGlassCard(
        radius: radius,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 22 : 28,
            mobile ? 22 : 28,
            mobile ? 22 : 28,
            mobile ? 20 : 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isForgotPassword
                  ? const SizedBox.shrink()
                  : _tabSelector(),

              if (!_isForgotPassword)
                const SizedBox(height: 4),

              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _isForgotPassword
                    ? _forgotPasswordForm()
                    : _tabs.index == 0
                        ? _loginForm()
                        : _signupForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _tabSelector() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: TabBar(
        controller: _tabs,
        onTap: (_) {
          setState(() {});
        },
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563EB),
              Color(0xFF3B82F6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _AuthColors.electricBlue.withOpacity(0.35),
              blurRadius: 16,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.40),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN FORM
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _loginForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 4),
      child: Form(
        key: _loginKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Sign in to your account',
              style: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 23,
              ),
            ),

            const SizedBox(height: 29),

            _field(
              ctrl: _loginEmail,
              label: 'Username',
              icon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your username';
                }

                if (v.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 19),

            _field(
              ctrl: _loginPass,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: _loginObscure,
              suffix: _eyeIcon(
                show: _loginObscure,
                onTap: () {
                  setState(() {
                    _loginObscure = !_loginObscure;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please enter your password';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            Consumer<AuthProvider>(
              builder: (_, auth, __) => _submitBtn(
                label: 'Login',
                loading: auth.isLoading,
                onTap: _login,
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: _PointerCursorWidget(
                child: TextButton(
                  onPressed: () {
                    _tabs.animateTo(1);
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: Text(
                    "Don't have an account?  Sign up →",
                    style: TextStyle(
                      color: _AuthColors.cyan.withOpacity(0.90),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 2),

            Center(
              child: _PointerCursorWidget(
                child: TextButton(
                  onPressed: _openForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.48),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNUP FORM
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _signupForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 4),
      child: Form(
        key: _signupKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create your account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Create an account to start tracking your bets.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            _field(
              ctrl: _signupName,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your full name';
                }

                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }

                if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(v.trim())) {
                  return 'Name can only contain letters';
                }

                return null;
              },
            ),

            const SizedBox(height: 10),

            _field(
              ctrl: _signupEmail,
              label: 'Email',
              icon: Icons.email_outlined,
              type: TextInputType.emailAddress,
              validator: _validateEmail,
            ),

            const SizedBox(height: 10),

            _field(
              ctrl: _signupPass,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: _signupObscure,
              suffix: _eyeIcon(
                show: _signupObscure,
                onTap: () {
                  setState(() {
                    _signupObscure = !_signupObscure;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please enter a password';
                }

                if (v.length < 8) {
                  return 'Password must be at least 8 characters';
                }

                if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
                  return 'Password must include at least one letter';
                }

                if (!RegExp(r'\d').hasMatch(v)) {
                  return 'Password must include at least one number';
                }

                return null;
              },
            ),

            const SizedBox(height: 10),

            _field(
              ctrl: _signupConfirm,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscure: _confirmObscure,
              suffix: _eyeIcon(
                show: _confirmObscure,
                onTap: () {
                  setState(() {
                    _confirmObscure = !_confirmObscure;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }

                if (v != _signupPass.text) {
                  return 'Passwords do not match';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            Consumer<AuthProvider>(
              builder: (_, auth, __) => _submitBtn(
                label: 'Create Account',
                loading: auth.isLoading,
                onTap: _signup,
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: _PointerCursorWidget(
                child: TextButton(
                  onPressed: () {
                    _tabs.animateTo(0);
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: Text(
                    'Already have an account?  Login →',
                    style: TextStyle(
                      color: _AuthColors.cyan.withOpacity(0.90),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD ROUTER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _forgotPasswordForm() {
    switch (_forgotPasswordStep) {
      case _ForgotPasswordStep.identifier:
        return _forgotIdentifierForm();

      case _ForgotPasswordStep.otp:
        return _forgotOtpForm();

      case _ForgotPasswordStep.newPassword:
        return _forgotNewPasswordForm();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD — IDENTIFIER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _forgotIdentifierForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 4),
      child: Form(
        key: _forgotIdentifierKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Forgot password?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Enter your username or email and we\'ll send you a verification code.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            _field(
              ctrl: _forgotIdentifier,
              label: 'Username or Email',
              icon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your username or email';
                }

                if (v.trim().length < 3) {
                  return 'Please enter a valid username or email';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            Consumer<AuthProvider>(
              builder: (_, auth, __) => _submitBtn(
                label: 'Send Verification Code',
                loading: auth.isPasswordResetLoading,
                onTap: _requestPasswordReset,
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: _PointerCursorWidget(
                child: TextButton.icon(
                  onPressed: _backToLogin,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 15,
                  ),
                  label: const Text('Back to Login'),
                  style: TextButton.styleFrom(
                    foregroundColor: _AuthColors.cyan,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD — OTP
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _forgotOtpForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 4),
      child: Form(
        key: _forgotOtpKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verify your account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Enter the verification code sent to your registered email address.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            _field(
              ctrl: _forgotOtp,
              label: 'Verification Code',
              icon: Icons.verified_user_outlined,
              type: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter the verification code';
                }

                if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                  return 'Enter the 6-digit verification code';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            Consumer<AuthProvider>(
              builder: (_, auth, __) => _submitBtn(
                label: 'Verify Code',
                loading: auth.isPasswordResetLoading,
                onTap: _verifyResetOtp,
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: _PointerCursorWidget(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _forgotPasswordStep =
                          _ForgotPasswordStep.identifier;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: Text(
                    'Use a different username or email',
                    style: TextStyle(
                      color: _AuthColors.cyan.withOpacity(0.90),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: _PointerCursorWidget(
                child: TextButton(
                  onPressed: _backToLogin,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD — NEW PASSWORD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _forgotNewPasswordForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 4),
      child: Form(
        key: _forgotPasswordKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create new password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Choose a new password for your account.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            _field(
              ctrl: _forgotNewPassword,
              label: 'New Password',
              icon: Icons.lock_outline,
              obscure: _forgotNewPasswordObscure,
              suffix: _eyeIcon(
                show: _forgotNewPasswordObscure,
                onTap: () {
                  setState(() {
                    _forgotNewPasswordObscure =
                        !_forgotNewPasswordObscure;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please enter a new password';
                }

                if (v.length < 8) {
                  return 'Password must be at least 8 characters';
                }

                if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
                  return 'Password must include at least one letter';
                }

                if (!RegExp(r'\d').hasMatch(v)) {
                  return 'Password must include at least one number';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            _field(
              ctrl: _forgotConfirmPassword,
              label: 'Confirm New Password',
              icon: Icons.lock_outline,
              obscure: _forgotConfirmPasswordObscure,
              suffix: _eyeIcon(
                show: _forgotConfirmPasswordObscure,
                onTap: () {
                  setState(() {
                    _forgotConfirmPasswordObscure =
                        !_forgotConfirmPasswordObscure;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }

                if (v != _forgotNewPassword.text) {
                  return 'Passwords do not match';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            Consumer<AuthProvider>(
              builder: (_, auth, __) => _submitBtn(
                label: 'Reset Password',
                loading: auth.isPasswordResetLoading,
                onTap: _resetPassword,
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: _PointerCursorWidget(
                child: TextButton(
                  onPressed: _backToLogin,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: _AuthColors.cyan.withOpacity(0.90),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIELD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? type,
    Widget? suffix,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13.5,
      ),
      cursorColor: _AuthColors.cyan,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          color: _AuthColors.cyan,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.40),
          size: 18,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: _AuthColors.cyan,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.red.withOpacity(0.65),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        errorStyle: const TextStyle(
          fontSize: 10.5,
          height: 1.1,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSWORD EYE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _eyeIcon({
    required bool show,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 18,
      icon: Icon(
        show
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: Colors.white.withOpacity(0.40),
        size: 18,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBMIT BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _submitBtn({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF1D4ED8),
              Color(0xFF3B82F6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.40),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF93C5FD).withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Please enter your email address';
    }

    if (!v.contains('@')) {
      return 'Enter a valid email address (missing @)';
    }

    if (!RegExp(
      r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// AUTH TOP BAR
// ═════════════════════════════════════════════════════════════════════════════

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          const _AuthWindowButtons(),
        ],
      ),
    );
  }
}

class _AuthWindowButtons extends StatelessWidget {
  const _AuthWindowButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AuthWindowButton(
          icon: Icons.remove,
          onPressed: () => windowManager.minimize(),
        ),
        _AuthWindowButton(
          icon: Icons.crop_square,
          iconSize: 13,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        _AuthWindowButton(
          icon: Icons.close,
          hoverColor: Colors.redAccent,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _AuthWindowButton extends StatefulWidget {
  const _AuthWindowButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.iconSize = 16,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;
  final double iconSize;

  @override
  State<_AuthWindowButton> createState() => _AuthWindowButtonState();
}

class _AuthWindowButtonState extends State<_AuthWindowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovering
        ? (widget.hoverColor ?? Colors.white.withOpacity(0.08))
        : Colors.transparent;

    final iconColor = _hovering && widget.hoverColor != null
        ? Colors.white
        : Colors.white.withOpacity(0.55);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          color: bg,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// POINTER CURSOR WIDGET
// ═════════════════════════════════════════════════════════════════════════════

class _PointerCursorWidget extends StatelessWidget {
  final Widget child;

  const _PointerCursorWidget({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LIQUID GLASS CARD
// ═════════════════════════════════════════════════════════════════════════════

class _LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const _LiquidGlassCard({
    required this.child,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 32,
                    sigmaY: 32,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          const Color(0xFF0A1628).withOpacity(0.60),
                          const Color(0xFF060F1E).withOpacity(0.75),
                        ],
                        stops: const [
                          0.0,
                          0.40,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withOpacity(0.14),
                      Colors.transparent,
                    ],
                    stops: const [
                      0.0,
                      0.55,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.10),
                      Colors.transparent,
                    ],
                    stops: const [
                      0.0,
                      0.60,
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _LiquidBorderPainter(
                  radius: radius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LIQUID BORDER PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _LiquidBorderPainter extends CustomPainter {
  final double radius;

  const _LiquidBorderPainter({
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          6,
        )
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF60A5FA).withOpacity(0.30),
            const Color(0xFF3B82F6).withOpacity(0.15),
            Colors.transparent,
          ],
          stops: const [
            0.0,
            0.50,
            1.0,
          ],
        ).createShader(rect),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.25),
            const Color(0xFF93C5FD).withOpacity(0.35),
            const Color(0xFF3B82F6).withOpacity(0.18),
            Colors.white.withOpacity(0.06),
          ],
          stops: const [
            0.0,
            0.20,
            0.45,
            0.72,
            1.0,
          ],
        ).createShader(rect),
    );

    final glintPath = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(
        Offset(size.width, radius),
        radius: Radius.circular(radius),
      );

    canvas.drawPath(
      glintPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.65),
            Colors.white.withOpacity(0.45),
            Colors.transparent,
          ],
          stops: const [
            0.0,
            0.30,
            0.65,
            1.0,
          ],
        ).createShader(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            2,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(
    _LiquidBorderPainter old,
  ) {
    return old.radius != radius;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO PANEL
// ═════════════════════════════════════════════════════════════════════════════

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/hero.png',
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.10),
                Colors.transparent,
                Colors.black.withOpacity(0.30),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF020B18).withOpacity(0.78),
                const Color(0xFF03152B).withOpacity(0.55),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [
                0.0,
                0.28,
                0.50,
                1.0,
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.30),
                Colors.transparent,
              ],
              stops: const [
                0.0,
                0.40,
              ],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x28615CFF),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.04),
                const Color(0xFF020D1D).withOpacity(0.25),
              ],
              stops: const [
                0.0,
                0.55,
                0.78,
                1.0,
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 56,
              right: 500,
              top: 40,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _brand(),
                const Spacer(),
                _heroContent(),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _brand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF60A5FA),
                Color(0xFF2563EB),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF60A5FA).withOpacity(0.38),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_cricket,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bet Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'LIVE SPORTS INTELLIGENCE',
              style: TextStyle(
                color: const Color(0xFF60A5FA).withOpacity(0.85),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF071A31).withOpacity(0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFF60A5FA).withOpacity(0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF60A5FA),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withOpacity(0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE SPORTS TERMINAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'Track Every',
          style: TextStyle(
            color: Colors.white,
            fontSize: 68,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -3.0,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 28,
                offset: Offset(0, 6),
              ),
              Shadow(
                color: Colors.black54,
                blurRadius: 6,
              ),
            ],
          ),
        ),

        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF93C5FD),
              Color(0xFF60A5FA),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Bet. Live.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 68,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -3.0,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Real-time odds, match updates, and\nportfolio tracking — all in one place.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 17,
            height: 1.7,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 12,
              ),
            ],
          ),
        ),

        const SizedBox(height: 44),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stat('10K+', 'Active users'),
            _divider(),
            _stat('50+', 'Sports markets'),
            _divider(),
            _stat('LIVE', 'Score feeds'),
          ],
        ),
      ],
    );
  }

  Widget _stat(
    String value,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      color: Colors.white.withOpacity(0.10),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// AUTH TOAST
// ═════════════════════════════════════════════════════════════════════════════

class _AuthToast extends StatefulWidget {
  final String message;
  final _ToastType type;
  final VoidCallback onDismiss;

  const _AuthToast({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AuthToast> createState() => _AuthToastState();
}

class _AuthToastState extends State<_AuthToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  Color get _accent {
    switch (widget.type) {
      case _ToastType.success:
        return const Color(0xFF22C55E);
      case _ToastType.warning:
        return const Color(0xFFF59E0B);
      case _ToastType.error:
        return const Color(0xFFEF4444);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case _ToastType.success:
        return Icons.check_circle_outline_rounded;
      case _ToastType.warning:
        return Icons.warning_amber_rounded;
      case _ToastType.error:
        return Icons.error_outline_rounded;
    }
  }

  String get _title {
    switch (widget.type) {
      case _ToastType.success:
        return 'Success';
      case _ToastType.warning:
        return 'Warning';
      case _ToastType.error:
        return 'Error';
    }
  }

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!_ctrl.isCompleted) return;

    await _ctrl.reverse();

    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080F1E).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _accent.withOpacity(0.30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: _accent.withOpacity(0.08),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accent.withOpacity(0.25),
                          ),
                        ),
                        child: Icon(
                          _icon,
                          color: _accent,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _title,
                              style: TextStyle(
                                color: _accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              widget.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _close,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withOpacity(0.40),
                              size: 18,
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
        ),
      ),
    );
  }
}

