import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/network_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_bar.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _workflowKey = GlobalKey();
  final GlobalKey _securityKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  static Color get vintageWhite => AppColors.canvas;
  static Color get vintageCardBorder => AppColors.border;
  static Color get vintageInkTitle => AppColors.ink;
  static Color get vintageInkBody => AppColors.inkSoft;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          extendBodyBehindAppBar: true,
      appBar: BrandBar(
        isRedGlass: true,
        tagline: '',
        onBrandTap: _scrollToTop,
        actions: [
          HeaderHoverButton(
            isRedGlass: true,
            label: 'Features',
            icon: Icons.auto_awesome_rounded,
            onPressed: () => _scrollTo(_featuresKey),
          ),
          HeaderHoverButton(
            isRedGlass: true,
            label: 'Architecture',
            icon: Icons.hub_outlined,
            onPressed: () => _scrollTo(_workflowKey),
          ),
          HeaderHoverButton(
            isRedGlass: true,
            label: 'Security',
            icon: Icons.security_rounded,
            onPressed: () => _scrollTo(_securityKey),
          ),
          HeaderHoverButton(
            isRedGlass: true,
            label: 'Contact',
            icon: Icons.phone_in_talk_rounded,
            onPressed: () => _scrollTo(_contactKey),
          ),
          const SizedBox(width: 4),
          HeaderHoverButton(
            isRedGlass: true,
            label: 'Admin',
            icon: Icons.admin_panel_settings_outlined,
            onPressed: () => context.go('/admin/login'),
          ),
          const SizedBox(width: 6),
          HeaderHoverButton(
            isRedGlass: true,
            isPrimary: true,
            label: 'Portal Sign In',
            icon: Icons.login_rounded,
            onPressed: () => context.go('/login'),
          ),
        ],
        navItems: [
          BrandBarAction(
            label: 'Features',
            icon: Icons.auto_awesome_rounded,
            onPressed: () => _scrollTo(_featuresKey),
          ),
          BrandBarAction(
            label: 'Architecture',
            icon: Icons.hub_outlined,
            onPressed: () => _scrollTo(_workflowKey),
          ),
          BrandBarAction(
            label: 'Security',
            icon: Icons.security_rounded,
            onPressed: () => _scrollTo(_securityKey),
          ),
          BrandBarAction(
            label: 'Contact',
            icon: Icons.phone_in_talk_rounded,
            onPressed: () => _scrollTo(_contactKey),
          ),
          BrandBarAction(
            label: 'Admin',
            icon: Icons.admin_panel_settings_outlined,
            onPressed: () => context.go('/admin/login'),
          ),
          BrandBarAction(
            label: 'Portal Sign In',
            icon: Icons.login_rounded,
            isPrimary: true,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            MaxWidthCenter(
              maxWidth: 1040,
              child: Padding(
                padding: const EdgeInsets.only(top: 104, bottom: 56, left: 24, right: 24),
                child: Column(
                  children: [
                        LayoutBuilder(builder: (context, c) {
                          final isSmall = c.maxWidth < 640;
                          final isTablet = c.maxWidth < 900;
                          final isDesktop = c.maxWidth >= 780;
                          final titleSize = isSmall ? 28.0 : (isTablet ? 36.0 : 44.0);
                          final alignment = isDesktop
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center;
                          final textAlign =
                              isDesktop ? TextAlign.start : TextAlign.center;
                          final wrapAlign =
                              isDesktop ? WrapAlignment.start : WrapAlignment.center;

                          return SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: alignment,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 580),
                                  child: Text(
                                    'Coordinate every ambulance,\ncity-wide, in real time.',
                                    textAlign: textAlign,
                                    style: TextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w900,
                                      color: vintageInkTitle,
                                      height: 1.15,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 540),
                                  child: Text(
                                    'The unified digital dispatch console for Addis Ababa’s emergency medical network — real-time GPS telemetry, intelligent triage routing, and live hospital capacity sync.',
                                    textAlign: textAlign,
                                    style: TextStyle(
                                      color: vintageInkBody,
                                      fontSize: isSmall ? 14 : 16,
                                      height: 1.55,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Responsive Action Buttons
                                Wrap(
                                  alignment: wrapAlign,
                                  spacing: 14,
                                  runSpacing: 12,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF1E56),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 26, vertical: 16),
                                        elevation: 6,
                                        shadowColor: const Color(0xFFFF1E56)
                                            .withValues(alpha: 0.4),
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => context.go('/register'),
                                      icon: const Icon(Icons.flash_on, size: 18),
                                      label:
                                          const Text('Request Dispatcher Access'),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: vintageInkTitle,
                                        side: BorderSide(
                                            color: vintageCardBorder,
                                            width: 1.5),
                                        backgroundColor: AppColors.surface,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 16),
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => context.go('/login'),
                                      icon: const Icon(Icons.login, size: 18),
                                      label: const Text('Portal Sign In'),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: vintageInkBody,
                                        side: BorderSide(
                                            color: vintageCardBorder),
                                        backgroundColor: AppColors.chipBg,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 16),
                                        textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => context.go('/admin/login'),
                                      icon: const Icon(
                                          Icons.admin_panel_settings_outlined,
                                          size: 17),
                                      label: const Text('Admin Console'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 72),

                        // End-to-End System Pipeline & Architecture
                        _SystemWorkflowSection(key: _workflowKey),

                        const SizedBox(height: 56),
                        _StatsRow(),
                        const SizedBox(height: 56),

                        // Features Grid
                        _FeatureGrid(key: _featuresKey),

                        const SizedBox(height: 56),

                        // Role Gateway Cards & Security Portals
                        _RoleGatewaysRow(key: _securityKey),

                        const SizedBox(height: 48),
                        Divider(color: vintageCardBorder),
                        const SizedBox(height: 20),
                        Text(
                          'Access is strictly restricted to authorized medical dispatch personnel. All operational activities are recorded in an immutable audit ledger per Ethiopian MOH standards.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Modern Red Emergency Footer with 907 Hotline & Command HQ
                _RedFooter(
                  key: _contactKey,
                  onScrollToTop: _scrollToTop,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// System Architecture & End-to-End Dispatch Pipeline Section
/// Designed for institutional clarity and academic senior capstone defense.
class _SystemWorkflowSection extends StatelessWidget {
  const _SystemWorkflowSection({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        step: '01',
        title: 'Incident Ingestion & Triage',
        description:
            'Emergency calls are parsed and scored into P1 (life-threatening) or P2 (urgent) priorities with automated caller geolocation capture.',
        icon: Icons.phone_in_talk_rounded,
        tag: 'Call Intake',
        color: const Color(0xFFFF1E56),
      ),
      (
        step: '02',
        title: 'Algorithmic Unit Routing',
        description:
            'Spatial proximity engine calculates nearest available ambulances, optimal road corridors, and live travel ETAs across sectors.',
        icon: Icons.alt_route_rounded,
        tag: 'Spatial Routing',
        color: const Color(0xFFD97706),
      ),
      (
        step: '03',
        title: 'Atomic Dispatch Locking',
        description:
            'ACID transactional guarantees prevent race conditions, locking unit assignment so no ambulance can ever be double-dispatched.',
        icon: Icons.lock_clock_rounded,
        tag: 'ACID Concurrency',
        color: const Color(0xFF2563EB),
      ),
      (
        step: '04',
        title: 'Live Telemetry & Bed Sync',
        description:
            'Sub-second GPS streaming tracks units en route while synchronizing receiving emergency room and ICU capacities in real time.',
        icon: Icons.local_hospital_rounded,
        tag: 'Facility Handshake',
        color: const Color(0xFF059669),
      ),
    ];

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final cardBg = isDark ? const Color(0xFF121722) : Colors.white;
        final cardBorder = isDark ? const Color(0xFF283446) : const Color(0xFFE2E8F0);
        final chipBg = isDark ? const Color(0xFF1A2232) : const Color(0xFFF8FAFC);
        final inkTitle = isDark ? Colors.white : const Color(0xFF0F172A);
        final inkBody = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 780;
            final isTablet = constraints.maxWidth >= 780 && constraints.maxWidth < 1000;
            final itemWidth = isNarrow
                ? constraints.maxWidth
                : (isTablet
                    ? (constraints.maxWidth - 20) / 2
                    : (constraints.maxWidth - 48) / 4);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SYSTEM ARCHITECTURE',
                    style: TextStyle(
                      color: Color(0xFFFF1E56),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'End-to-End Emergency Response Pipeline',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: inkTitle,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'How HIWONET coordinates caller intake, fleet dispatching, and hospital reception with zero data loss and sub-second latency.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: inkBody,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4 Step Cards
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final s in steps)
                        Container(
                          width: itemWidth,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: s.color.withValues(alpha: isDark ? 0.20 : 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: s.color.withValues(alpha: isDark ? 0.40 : 0.25),
                                      ),
                                    ),
                                    child: Icon(s.icon, color: s.color, size: 20),
                                  ),
                                  Text(
                                    s.step,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: inkBody,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                s.tag.toUpperCase(),
                                style: TextStyle(
                                  color: s.color,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: inkTitle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: inkBody,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Three Direct Access Role Gateways at the bottom of the landing page
class _RoleGatewaysRow extends StatelessWidget {
  const _RoleGatewaysRow({super.key});

  @override
  Widget build(BuildContext context) {
    final gateways = [
      (
        'Dispatcher Workstation',
        'Incoming emergency queues, GIS live map & vehicle routing',
        Icons.headset_mic_outlined,
        '/login',
        'Launch Station →',
        const Color(0xFFFF1E56),
      ),
      (
        'Admin Console',
        'User RBAC provisioning, hospital registry & audit events',
        Icons.admin_panel_settings_outlined,
        '/admin/login',
        'Enter Admin →',
        const Color(0xFF2563EB),
      ),
      (
        'New Operator Signup',
        'Provision authorized dispatcher credentials for review',
        Icons.person_add_alt_1_outlined,
        '/register',
        'Submit Request →',
        const Color(0xFF059669),
      ),
    ];

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final cardBg = isDark ? const Color(0xFF121722) : Colors.white;
        final cardBorder = isDark ? const Color(0xFF283446) : const Color(0xFFE2E8F0);
        final inkTitle = isDark ? Colors.white : const Color(0xFF0F172A);
        final inkBody = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

        return LayoutBuilder(builder: (context, c) {
          final isNarrow = c.maxWidth < 840;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYSTEM ACCESS PORTALS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: inkBody,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final g in gateways)
                    InkWell(
                      onTap: () => context.go(g.$4),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: isNarrow ? c.maxWidth : (c.maxWidth - 32) / 3,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: g.$6.withValues(alpha: isDark ? 0.20 : 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(g.$3, color: g.$6, size: 20),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              g.$1,
                              style: TextStyle(
                                color: inkTitle,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              g.$2,
                              style: TextStyle(
                                color: inkBody,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              g.$5,
                              style: TextStyle(
                                color: g.$6,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        });
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final cardBg = isDark ? const Color(0xFF121722) : Colors.white;
        final cardBorder = isDark ? const Color(0xFF283446) : const Color(0xFFE2E8F0);
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subtitleColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

        final stats = [
          (
            '${NetworkStats.totalAmbulances}',
            'Ambulances in Fleet',
            '100% GPS Live',
            Icons.emergency_outlined,
            const Color(0xFFFF1E56),
          ),
          (
            '${NetworkStats.totalHospitals}',
            'Partner Hospitals',
            'Real-time Bed Feeds',
            Icons.local_hospital_outlined,
            const Color(0xFF2563EB),
          ),
          (
            NetworkStats.avgResponseTime,
            'Avg City-Wide ETA',
            '-1.2m vs 2025 Target',
            Icons.speed,
            const Color(0xFF10B981),
          ),
        ];

        return LayoutBuilder(builder: (context, c) {
          final isNarrow = c.maxWidth < 780;

          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final s in stats)
                Container(
                  width: isNarrow ? c.maxWidth : (c.maxWidth - 32) / 3,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: s.$5.withValues(alpha: isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: s.$5.withValues(alpha: isDark ? 0.40 : 0.25)),
                        ),
                        child: Icon(s.$4, color: s.$5, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  s.$1,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: titleColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  s.$3,
                                  style: TextStyle(
                                    color: s.$5,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s.$2,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        });
      },
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final features = const [
      (
        Icons.gps_fixed,
        'Real-Time Vehicle Tracking',
        'Continuous GPS tracking of all active ambulances and hospital-bound units with automated speed and delay alerts.',
        'Telemetry',
        Color(0xFFFF1E56),
        '/dashboard',
        'Open Live Map →',
      ),
      (
        Icons.bolt,
        'Intelligent Triage Engine',
        'Auto-prioritize high-severity P1 calls based on caller diagnostics and automatically pinpoint the nearest unit.',
        'Auto-Routing',
        Color(0xFFD97706),
        '/dashboard',
        'View Dispatch Queue →',
      ),
      (
        Icons.local_hospital_outlined,
        'Unified Hospital Feeds',
        'Live ICU bed availability, oxygen inventory, and trauma readiness fed directly from registered regional facilities.',
        'FHIR Sync',
        Color(0xFF2563EB),
        '/admin/registry',
        'Inspect Capacity →',
      ),
    ];

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final cardBg = isDark ? const Color(0xFF121722) : Colors.white;
        final cardBorder = isDark ? const Color(0xFF283446) : const Color(0xFFE2E8F0);
        final inkTitle = isDark ? Colors.white : const Color(0xFF0F172A);
        final inkBody = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 780;
            final cards = [
              for (final f in features)
                SizedBox(
                  width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: f.$5.withValues(alpha: isDark ? 0.20 : 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: f.$5.withValues(alpha: isDark ? 0.40 : 0.25)),
                              ),
                              child: Icon(f.$1, color: f.$5, size: 22),
                            ),
                            const Spacer(),
                            Text(
                              f.$4.toUpperCase(),
                              style: TextStyle(
                                color: inkBody,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          f.$2,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: inkTitle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          f.$3,
                          style: TextStyle(
                            color: inkBody,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        InkWell(
                          onTap: () => context.go(f.$6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                f.$7,
                                style: TextStyle(
                                  color: f.$5,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ];
            return Wrap(spacing: 16, runSpacing: 16, children: cards);
          },
        );
      },
    );
  }
}

/// Comprehensive, modern Red Footer with 907 Hotline, HQ contacts, portals & capstone specs.
class _RedFooter extends StatelessWidget {
  final VoidCallback onScrollToTop;

  const _RedFooter({super.key, required this.onScrollToTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF1E56), // deep emergency crimson
            Color(0xFFCC1443), // rich emergency ruby
            Color(0xFFA00D33), // dark garnet
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFF3366).withValues(alpha: 0.45),
            width: 2.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA00D33).withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emergency 907 Hotline Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            child: MaxWidthCenter(
              maxWidth: 1040,
              child: LayoutBuilder(builder: (context, c) {
                final isNarrow = c.maxWidth < 700;
                return isNarrow
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '24/7 ADDIS ABABA EMERGENCY CALL CENTER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const _HotlinePill(),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '24/7 ADDIS ABABA EMERGENCY CALL CENTER — IMMEDIATE RESPONSE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const _HotlinePill(),
                        ],
                      );
              }),
            ),
          ),

          // Main 4-Column Footer Content
          MaxWidthCenter(
            maxWidth: 1040,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: LayoutBuilder(builder: (context, c) {
                final isNarrow = c.maxWidth < 640;
                final isTablet = c.maxWidth >= 640 && c.maxWidth < 960;
                final colWidth = isNarrow
                    ? c.maxWidth
                    : (isTablet
                        ? (c.maxWidth - 24) / 2
                        : (c.maxWidth - 48) / 3);

                return Column(
                  children: [
                    Wrap(
                      spacing: 24,
                      runSpacing: 32,
                      children: [
                        // Col 1: Brand & Mission
                        SizedBox(
                          width: colWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.20),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.local_hospital_rounded,
                                      color: Color(0xFFFF1E56),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'HIWONET',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    '-RESPONSE',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Unified emergency medical dispatch, spatial ambulance tracking, and real-time hospital bed synchronization for Addis Ababa, Ethiopia.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12.5,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'MOH-EMS Protocol Compliant',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.90),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Col 2: Emergency & Command Contact
                        SizedBox(
                          width: colWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EMERGENCY CONTACT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const _FooterContactItem(
                                icon: Icons.phone_in_talk_rounded,
                                label: 'Toll-Free Dispatch Hotline',
                                value: '907 (Priority Triage)',
                                isHighlight: true,
                              ),
                              const SizedBox(height: 10),
                              const _FooterContactItem(
                                icon: Icons.headset_mic_rounded,
                                label: 'Operations Desk',
                                value: '+251 11 551 2244',
                              ),
                              const SizedBox(height: 10),
                              const _FooterContactItem(
                                icon: Icons.location_on_rounded,
                                label: 'Central Command HQ',
                                value: 'Churchill Ave, Addis Ababa',
                              ),
                              const SizedBox(height: 10),
                              const _FooterContactItem(
                                icon: Icons.email_rounded,
                                label: 'Operations Support',
                                value: 'dispatch@hiwonet.et',
                              ),
                            ],
                          ),
                        ),

                        // Col 3: Portal Consoles
                        SizedBox(
                          width: colWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SYSTEM ACCESS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _FooterLink(
                                label: 'Live Dispatcher Map',
                                route: '/dashboard',
                                icon: Icons.map_rounded,
                              ),
                              _FooterLink(
                                label: 'Dispatcher Station Login',
                                route: '/login',
                                icon: Icons.login_rounded,
                              ),
                              _FooterLink(
                                label: 'Request Dispatcher Access',
                                route: '/register',
                                icon: Icons.person_add_alt_1_rounded,
                              ),
                              _FooterLink(
                                label: 'Admin Command Center',
                                route: '/admin/login',
                                icon: Icons.admin_panel_settings_rounded,
                              ),
                              _FooterLink(
                                label: 'Hospital & Bed Registry',
                                route: '/admin/registry',
                                icon: Icons.local_hospital_rounded,
                              ),
                              _FooterLink(
                                label: 'Immutable Audit Trail',
                                route: '/admin/logs',
                                icon: Icons.receipt_long_rounded,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.18),
                      height: 1,
                    ),
                    const SizedBox(height: 24),

                    // Bottom Row: Copyright + Back to top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '© 2026 HIWONET-RESPONSE. Addis Ababa Emergency Medical Services Platform. All rights reserved.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onScrollToTop,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Back to Top',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Highlighted Hotline button for dial 907
class _HotlinePill extends StatelessWidget {
  const _HotlinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.phone_in_talk_rounded, color: Color(0xFFFF1E56), size: 16),
          SizedBox(width: 8),
          Text(
            'DIAL 907',
            style: TextStyle(
              color: Color(0xFFFF1E56),
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  const _FooterContactItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight ? const Color(0xFFFDE047) : Colors.white.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  color: isHighlight ? Colors.white : Colors.white.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final String route;
  final IconData icon;

  const _FooterLink({
    required this.label,
    required this.route,
    required this.icon,
  });

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go(widget.route),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: _hovered ? FontWeight.w700 : FontWeight.w500,
                  decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

