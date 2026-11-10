import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'icon_rail.dart';

/// Shared chrome for the four authenticated Admin Panel screens
/// (Dashboard, User Management, Hospital & Ambulance Registry,
/// System / Audit Logs).
///
/// Reuses the same [IconRail] widget the dispatcher's Live Map screen
/// uses — "sized and navigated the same way as the Dispatcher console"
/// per the brief — but here every rail item routes to a real screen
/// instead of the dispatcher build's three placeholder icons.
class AdminScaffold extends StatelessWidget {
  final int selectedIndex;
  final String title;
  final List<Widget> headerActions;
  final Widget child;

  const AdminScaffold({
    super.key,
    required this.selectedIndex,
    required this.title,
    required this.child,
    this.headerActions = const [],
  });

  static const _routes = <String>[
    '/admin',
    '/admin/analytics',
    '/admin/users',
    '/admin/registry',
    '/admin/logs',
  ];

  static const _items = <RailItem>[
    RailItem(Icons.dashboard_outlined, 'Admin Dashboard'),
    RailItem(Icons.analytics_outlined, 'Live Analytics & Trends'),
    RailItem(Icons.people_outline, 'User & Staff Management'),
    RailItem(Icons.local_hospital_outlined, 'Hospital & Fleet Registry'),
    RailItem(Icons.fact_check_outlined, 'System / Audit Logs'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Row(
        children: [
          IconRail(
            selectedIndex: selectedIndex,
            items: _items,
            onSelect: (i) {
              if (i != selectedIndex) context.go(_routes[i]);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF991B1B), // Command Deep Crimson Red
                        Color(0xFFDC2626), // Emergency Vivid Red
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF7F1D1D), width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: LayoutBuilder(builder: (context, c) {
                    final isNarrow = c.maxWidth < 880;

                    final leftTitle = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedIndex != 0) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                            tooltip: 'Back to Admin Overview',
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () => context.go('/admin'),
                          ),
                          const SizedBox(width: 4),
                        ],
                        const Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    );

                    final rightActions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Administrator Identity Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_outlined, size: 13, color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'System Administrator',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.30),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                                ),
                                child: const Text(
                                  'COMMAND',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const ThemeToggleButton(compact: true, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            backgroundColor: Colors.black.withValues(alpha: 0.20),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Row(
                                  children: [
                                    Icon(Icons.logout_rounded, color: Color(0xFFFF1E56), size: 22),
                                    SizedBox(width: 8),
                                    Text('Confirm Admin Sign Out'),
                                  ],
                                ),
                                content: const Text(
                                  'Are you sure you want to sign out of the Administrator console?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF1E56),
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Log Out'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await AuthService.instance.signOut();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Admin signed out successfully.'),
                                    backgroundColor: Color(0xFF1E293B),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                context.go('/admin/login');
                              }
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
                          label: const Text(
                            'Log Out',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: leftTitle),
                              const SizedBox(width: 8),
                              rightActions,
                            ],
                          ),
                          if (headerActions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: headerActions),
                            ),
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        leftTitle,
                        const SizedBox(width: 14),
                        if (headerActions.isNotEmpty)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: headerActions),
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 12),
                        rightActions,
                      ],
                    );
                  }),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
