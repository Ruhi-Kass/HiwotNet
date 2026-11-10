import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_scaffold.dart';
import '../../services/admin_repository.dart';

/// Admin Panel screen 5 — System / Audit Logs.
///
/// Attributable, immutable event trail streamed live from `auditLog`.
/// Logs every critical mutation: registrations, approvals, rejections,
/// role assignments, suspensions, and emergency dispatches.
class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  String _query = '';
  AuditAction? _actionFilter;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      title: 'System / Audit Logs',
      child: StreamBuilder<List<AuditLogEntry>>(
        stream: AdminRepository.instance.streamAuditLog(limit: 100),
        builder: (context, snapshot) {
          final allLogs = snapshot.data ?? AdminDemoData.auditLog;

          final visible = allLogs.where((e) {
            final q = _query.toLowerCase();
            final matchesQuery = q.isEmpty ||
                e.actor.toLowerCase().contains(q) ||
                e.target.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q);
            final matchesAction =
                _actionFilter == null || e.action == _actionFilter;
            return matchesQuery && matchesAction;
          }).toList();

          return LayoutBuilder(builder: (context, c) {
            final stacked = c.maxWidth < 820;
            final table = _LogTableCard(
              entries: visible,
              totalCount: allLogs.length,
              onQueryChanged: (v) => setState(() => _query = v),
            );
            final filters = _FilterCard(
              selected: _actionFilter,
              onChanged: (v) => setState(() => _actionFilter = v),
            );
            return SingleChildScrollView(
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [table, const SizedBox(height: 16), filters],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: table),
                        const SizedBox(width: 16),
                        SizedBox(width: 240, child: filters),
                      ],
                    ),
            );
          });
        },
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final AuditAction? selected;
  final ValueChanged<AuditAction?> onChanged;

  const _FilterCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by action',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 10),
            _FilterChip(
              label: 'All Activity',
              selected: selected == null,
              onTap: () => onChanged(null),
            ),
            for (final a in AuditAction.values)
              _FilterChip(
                label: a.label,
                selected: selected == a,
                onTap: () => onChanged(a),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandRed : AppColors.chipBg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogTableCard extends StatelessWidget {
  final List<AuditLogEntry> entries;
  final int totalCount;
  final ValueChanged<String> onQueryChanged;

  const _LogTableCard({
    required this.entries,
    required this.totalCount,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Audit trail',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$totalCount entries',
                    style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Live Stream Sync',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 240,
                  child: TextField(
                    onChanged: onQueryChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Search actor or target',
                      prefixIcon: Icon(Icons.search, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 36,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                columns: const [
                  DataColumn(label: Text('Timestamp')),
                  DataColumn(label: Text('Action Type')),
                  DataColumn(label: Text('Actor')),
                  DataColumn(label: Text('Event Details')),
                  DataColumn(label: Text('Target Entity')),
                ],
                rows: [
                  for (final e in entries)
                    DataRow(cells: [
                      DataCell(Text(e.timestamp,
                          style: TextStyle(color: AppColors.inkSoft))),
                      DataCell(_buildActionBadge(e.action)),
                      DataCell(Text(e.actor,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(e.description)),
                      DataCell(Text(e.target, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ]),
                ],
              ),
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No audit logs match your search.',
                      style: TextStyle(color: AppColors.inkSoft)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBadge(AuditAction action) {
    Color bg;
    Color fg;
    IconData icon;

    switch (action) {
      case AuditAction.suspension:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        icon = Icons.block_flipped;
        break;
      case AuditAction.roleChange:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        icon = Icons.swap_horiz_rounded;
        break;
      case AuditAction.registration:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        icon = Icons.how_to_reg_outlined;
        break;
      case AuditAction.signIn:
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF9333EA);
        icon = Icons.login_rounded;
        break;
      case AuditAction.dispatch:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFEA580C);
        icon = Icons.local_shipping_outlined;
        break;
      case AuditAction.incident:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.emergency_outlined;
        break;
    }

    final isDark = AppThemeController.isDark;
    final badgeBg = isDark ? fg.withValues(alpha: 0.16) : bg;
    final badgeFg = isDark ? fg.withValues(alpha: 0.95) : fg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(4),
        border: isDark ? Border.all(color: fg.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: badgeFg),
          const SizedBox(width: 5),
          Text(
            action.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: badgeFg,
            ),
          ),
        ],
      ),
    );
  }
}
