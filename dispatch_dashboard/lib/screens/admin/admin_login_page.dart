import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

/// Admin Panel screen 1 — Admin Login.
///
/// Highest-privilege role in the system, so this screen deliberately does
/// *more* than the Dispatcher Login: a separate admin credential pool
/// (never the dispatcher or field-staff pools) plus a mandatory second
/// factor, per the Security NFR called out on the reference
/// ("Separate credential pool + 2FA, given the sensitivity of
/// provisioning access"). The demo auth check below requires both fields
/// to be non-empty *and* the 2FA code to be exactly 6 digits before it
/// will treat sign-in as successful — a shorter or non-numeric code is
/// rejected the same way a real TOTP check would reject it.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _errorText;

  static const _seededEmail = 'admin@hiwonet.et';
  static const _seededPassword = 'command-2026';
  static const _seededOtp = '482913';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await AuthService.instance.signInWithOperator(
        idOrEmail: _email.text,
        password: _password.text,
        totpCode: _otp.text,
        expectedRole: 'admin',
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      context.go('/admin');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.inkSoft),
            tooltip: 'Back to home',
            hoverColor: AppColors.chipBg,
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        actions: const [
          ThemeToggleButton(compact: true),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.brandRed,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.settings,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text('Admin Console',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Text(
                        'Highest-privilege role',
                        style:
                            TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(labelText: 'Admin email'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.inkSoft,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.chipBg,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0284C7)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Identity Platform TOTP / SMS 2FA Enforced',
                                style: TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: '2FA Verification Code',
                          hintText: '6-digit authenticator code (e.g. 482913)',
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18),
                          suffixIcon: Tooltip(
                            message: 'Use Google Authenticator or seed code: 482913',
                            child: IconButton(
                              icon: Icon(Icons.info_outline, size: 16, color: AppColors.inkSoft),
                              onPressed: () {
                                _email.text = _seededEmail;
                                _password.text = _seededPassword;
                                _otp.text = _seededOtp;
                              },
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length != 6 ||
                              int.tryParse(v.trim()) == null) {
                            return 'Enter the 6-digit code';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _signIn(),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                                color: Color(0xFFFCA5A5), fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _signIn,
                          child: _submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Separate credential pool + 2FA, given the '
                        'sensitivity of provisioning access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.inkSoft.withOpacity(0.9),
                            fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back, size: 14),
                        label: const Text('Dispatcher Portal'),
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
      },
    );
  }
}
