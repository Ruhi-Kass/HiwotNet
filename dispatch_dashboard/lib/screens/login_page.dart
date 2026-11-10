import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

/// Screen 3 — Dispatcher Login.
///
/// Fix applied here (PR-4): dispatcher accounts sit in a credential pool
/// that is SEPARATE from field-staff (crew) logins — this screen must
/// never authenticate a field-staff credential, and the UI makes that
/// boundary explicit rather than implicit, so a dispatcher doesn't land
/// here by mistake looking for the field app.
///
/// For this demo build there is no real backend, so `_attemptSignIn`
/// checks against a single seeded dispatcher account and otherwise shows
/// an inline error — it never silently "succeeds" so the rest of the
/// flow (especially the registration -> pending-approval path) stays
/// honest end-to-end.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _operatorId = TextEditingController(text: '');
  final _passwordCtl = TextEditingController(text: '');
  bool _obscure = true;
  bool _submitting = false;
  String? _errorText;

  static const _seededOperatorId = 'dispatcher01';
  static const _seededPassword = 'hiwonet-2026';

  @override
  void dispose() {
    _operatorId.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _attemptSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await AuthService.instance.signInWithOperator(
        idOrEmail: _operatorId.text,
        password: _passwordCtl.text,
        expectedRole: 'dispatcher',
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      context.go('/dashboard');
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
        final approvedList = AuthService.instance.approvedDispatchers;
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
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 16),
                      Text('Dispatch HQ',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Text(
                        'Desktop auth screen',
                        style:
                            TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                      ),
                      if (approvedList.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.verified_user_rounded,
                                      color: AppColors.success, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Approved Dispatcher Ready',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              for (final app in approvedList)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _operatorId.text = app.email;
                                      _passwordCtl.text = app.password;
                                      _errorText = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                app.fullName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12),
                                              ),
                                              Text(
                                                '${app.employeeId} • ${app.email}',
                                                style: TextStyle(
                                                    color: AppColors.inkSoft,
                                                    fontSize: 10.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandRed
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Auto-Fill ➔',
                                            style: TextStyle(
                                              color: AppColors.brandRed,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _operatorId,
                        decoration: const InputDecoration(
                          labelText: 'Operator ID, Email, or Callsign',
                          hintText: 'e.g. dispatcher01 or dawit.a@addisababa.gov.et',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordCtl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'e.g. hiwonet-2026 or employee ID',
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
                        onFieldSubmitted: (_) => _attemptSignIn(),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _operatorId.text = _seededOperatorId;
                              _passwordCtl.text = _seededPassword;
                              _errorText = null;
                            });
                          },
                          icon: const Icon(Icons.bolt, size: 14),
                          label: const Text('Fill Demo Credentials',
                              style: TextStyle(fontSize: 11.5)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandRed.withValues(alpha: 0.08),
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
                          onPressed: _submitting ? null : _attemptSignIn,
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
                        'Dispatcher role only — separate credential pool '
                        'from field staff.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.inkSoft.withValues(alpha: 0.9),
                            fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Need an account?',
                              style: TextStyle(
                                  color: AppColors.inkSoft, fontSize: 12.5)),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Request Dispatcher Access'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => context.go('/admin/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.inkSoft,
                          textStyle: const TextStyle(fontSize: 11.5),
                        ),
                        child: const Text('Admin Console →'),
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
