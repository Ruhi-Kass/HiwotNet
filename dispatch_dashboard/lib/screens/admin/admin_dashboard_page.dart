import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_scaffold.dart';
import '../../services/admin_repository.dart';

/// Admin Panel screen 2 — Admin Dashboard.
///
/// System-wide overview + operations console. Fully responsive and scrollable,
/// with live health telemetry, interactive quick actions, and real-time audit activity.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 0,
      title: 'Admin Overview',
      headerActions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, size: 14, color: AppColors.success),
            SizedBox(width: 6),
            Text(
              'System healthy • 99.98% uptime',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
      child: LayoutBuilder(builder: (context, c) {
        final stacked = c.maxWidth < 860;
        final left = const _LeftColumn();
        final right = const _RecentActivityCard();

        return SingleChildScrollView(
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    left,
                    const SizedBox(height: 16),
                    right,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: right),
                  ],
                ),
        );
      }),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<List<UserAccount>>(
          stream: AdminRepository.instance.streamUsers(),
          builder: (context, userSnap) {
            final userCount = userSnap.hasData && userSnap.data!.isNotEmpty
                ? userSnap.data!.length
                : AdminDemoData.totalUsers;

            return StreamBuilder<List<HospitalRecord>>(
              stream: AdminRepository.instance.streamHospitals(),
              builder: (context, hospSnap) {
                final hospCount = hospSnap.hasData && hospSnap.data!.isNotEmpty
                    ? hospSnap.data!.length
                    : AdminDemoData.totalHospitals;

                return StreamBuilder<List<AmbulanceRecord>>(
                  stream: AdminRepository.instance.streamAmbulances(),
                  builder: (context, ambSnap) {
                    final ambCount = ambSnap.hasData && ambSnap.data!.isNotEmpty
                        ? ambSnap.data!.length
                        : AdminDemoData.totalAmbulances;

                    return LayoutBuilder(builder: (context, c) {
                      final isNarrow = c.maxWidth < 540;
                      final cards = [
                        _StatCard(
                          value: '$userCount',
                          label: 'Total Users',
                          icon: Icons.people_alt_outlined,
                          trend: 'Active accounts',
                          color: const Color(0xFF2563EB),
                        ),
                        _StatCard(
                          value: '$hospCount',
                          label: 'Hospitals Registered',
                          icon: Icons.local_hospital_outlined,
                          trend: 'All online',
                          color: const Color(0xFF059669),
                        ),
                        _StatCard(
                          value: '$ambCount',
                          label: 'Active Ambulances',
                          icon: Icons.airport_shuttle_outlined,
                          trend: 'Fleet in service',
                          color: AppColors.brandRed,
                        ),
                      ];

                      if (isNarrow) {
                        return Column(
                          children: [
                            for (final card in cards) ...[
                              card,
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (int i = 0; i < cards.length; i++) ...[
                            Expanded(child: cards[i]),
                            if (i != cards.length - 1) const SizedBox(width: 12),
                          ],
                        ],
                      );
                    });
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on, size: 16, color: AppColors.brandRed),
                    const SizedBox(width: 6),
                    const Text(
                      'Quick actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Role-based Access Control',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.inkSoft.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _QuickAction(
                  icon: Icons.analytics_outlined,
                  label: 'Live Operations Analytics & Trends',
                  subtitle: 'Real-time telemetry, bed utilization, and emergency intake graphs',
                  onTap: () => context.go('/admin/analytics'),
                ),
                _QuickAction(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Manage users & privileges',
                  subtitle: 'Suspend, reinstate or change RBAC roles',
                  onTap: () => context.go('/admin/users'),
                ),
                _QuickAction(
                  icon: Icons.domain_add_outlined,
                  label: 'Manage hospitals & ambulances',
                  subtitle: 'Register hospital bases and assign emergency fleet units',
                  onTap: () => context.go('/admin/registry'),
                ),
                _QuickAction(
                  icon: Icons.shield_outlined,
                  label: 'System & Security audit logs',
                  subtitle: 'Review immutable timestamps and administrative events',
                  onTap: () => context.go('/admin/logs'),
                ),
                _QuickAction(
                  icon: Icons.map_outlined,
                  label: 'Switch to Dispatcher Live Map',
                  subtitle: 'View active emergency units and live routing in progress',
                  onTap: () => context.go('/dashboard'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final String trend;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3.5,
              child: Container(color: color),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(icon, size: 16, color: color),
                      ),
                      const Spacer(),
                      Text(
                        trend,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.inkSoft,
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
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.chipBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: AppColors.inkSoft),
              const SizedBox(width: 6),
              const Text(
                'Recent activity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Divider(height: 20, color: AppColors.border),
          StreamBuilder<List<AuditLogEntry>>(
            stream: AdminRepository.instance.streamAuditLog(limit: 5),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? AdminDemoData.auditLog;
              final displayLogs = logs.take(5).toList();

              if (displayLogs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No recent activity recorded.',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                );
              }

              return Column(
                children: [
                  for (final log in displayLogs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.brandRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${log.actor} — ${log.description}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (log.target.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      log.target,
                                      style: TextStyle(
                                        color: AppColors.inkSoft,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  log.timestamp,
                                  style: TextStyle(
                                    color: AppColors.inkSoft,
                                    fontSize: 11,
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
            },
          ),
        ],
      ),
    );
  }
}
