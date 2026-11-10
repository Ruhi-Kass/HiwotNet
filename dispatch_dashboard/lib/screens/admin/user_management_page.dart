import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account_status_pill.dart';
import '../../widgets/admin_scaffold.dart';
import '../../services/admin_repository.dart';

/// Admin Panel screen 3 — User Management & RBAC Provisioning.
///
/// Features:
/// 1. Real-time stream of `registrationRequests` (pending dispatcher applications).
/// 2. Admin Approve / Reject actions routed through Cloud Functions with loading state.
/// 3. Real-time stream of `users` with Suspend / Reinstate actions.
/// 4. Dynamic role breakdown and search/filtering.
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

enum _SortField { name, role, status, lastActive }

class _UserManagementPageState extends State<UserManagementPage> {
  String _query = '';
  AccountRole? _roleFilter;
  _SortField _sortField = _SortField.name;
  bool _sortAscending = true;

  final Set<String> _processingRequestIds = {};
  final Set<String> _processingUserIds = {};

  Future<void> _approveRequest(RegistrationRequest req) async {
    setState(() => _processingRequestIds.add(req.id));
    try {
      await AdminRepository.instance.approveRegistration(
        requestId: req.id,
        role: 'dispatcher',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${req.fullName} approved. Password activation email dispatched.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval error: $e'),
          backgroundColor: AppColors.brandRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingRequestIds.remove(req.id));
    }
  }

  Future<void> _rejectRequest(RegistrationRequest req) async {
    final reasonController =
        TextEditingController(text: 'Credentials could not be verified.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject the application for ${req.fullName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g. Invalid Employee ID',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject Application'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingRequestIds.add(req.id));
    try {
      await AdminRepository.instance.rejectRegistration(
        requestId: req.id,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application for ${req.fullName} was rejected.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejection error: $e'),
          backgroundColor: AppColors.brandRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingRequestIds.remove(req.id));
    }
  }

  Future<void> _toggleStatus(UserAccount user) async {
    final newStatus = user.status == AccountStatus.active ? 'suspended' : 'active';
    setState(() => _processingUserIds.add(user.id));

    try {
      await AdminRepository.instance.setUserStatus(
        uid: user.id,
        status: newStatus,
        reason: 'Administrator toggle on user management console',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.name} is now ${newStatus == 'suspended' ? 'suspended' : 'active'}.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status update error: $e'),
          backgroundColor: AppColors.brandRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingUserIds.remove(user.id));
    }
  }

  void _setSort(_SortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 2,
      title: 'User Management',
      child: StreamBuilder<List<RegistrationRequest>>(
        stream: AdminRepository.instance.streamRegistrationRequests(),
        builder: (context, reqSnapshot) {
          final pendingRequests = (reqSnapshot.data ?? [])
              .where((r) => r.status == 'pending')
              .toList();

          return StreamBuilder<List<UserAccount>>(
            stream: AdminRepository.instance.streamUsers(),
            builder: (context, userSnapshot) {
              final allUsers = userSnapshot.data ?? AdminDemoData.users;

              var filtered = allUsers.where((u) {
                final matchesQuery = _query.isEmpty ||
                    u.name.toLowerCase().contains(_query.toLowerCase());
                final matchesRole = _roleFilter == null || u.role == _roleFilter;
                return matchesQuery && matchesRole;
              }).toList();

              int cmp(UserAccount a, UserAccount b) {
                switch (_sortField) {
                  case _SortField.name:
                    return a.name.compareTo(b.name);
                  case _SortField.role:
                    return a.role.label.compareTo(b.role.label);
                  case _SortField.status:
                    return a.status.index.compareTo(b.status.index);
                  case _SortField.lastActive:
                    return a.lastActiveLabel.compareTo(b.lastActiveLabel);
                }
              }

              filtered.sort(_sortAscending ? cmp : (a, b) => cmp(b, a));

              return LayoutBuilder(builder: (context, c) {
                final stacked = c.maxWidth < 860;

                final mainContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PendingRequestsCard(
                      requests: pendingRequests,
                      processingIds: _processingRequestIds,
                      onApprove: _approveRequest,
                      onReject: _rejectRequest,
                    ),
                    const SizedBox(height: 16),
                    _UsersTableCard(
                      users: filtered,
                      processingUserIds: _processingUserIds,
                      onQueryChanged: (v) => setState(() => _query = v),
                      onToggleStatus: _toggleStatus,
                      sortField: _sortField,
                      sortAscending: _sortAscending,
                      onSort: _setSort,
                      roleFilter: _roleFilter,
                      onRoleFilterChanged: (v) => setState(() => _roleFilter = v),
                    ),
                  ],
                );

                final breakdown = _RoleBreakdownCard(users: allUsers);

                return SingleChildScrollView(
                  child: stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [mainContent, const SizedBox(height: 16), breakdown],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: mainContent),
                            const SizedBox(width: 16),
                            SizedBox(width: 260, child: breakdown),
                          ],
                        ),
                );
              });
            },
          );
        },
      ),
    );
  }
}

class _PendingRequestsCard extends StatelessWidget {
  final List<RegistrationRequest> requests;
  final Set<String> processingIds;
  final ValueChanged<RegistrationRequest> onApprove;
  final ValueChanged<RegistrationRequest> onReject;

  const _PendingRequestsCard({
    required this.requests,
    required this.processingIds,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions_rounded,
                    color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pending Dispatcher Registrations',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${requests.length} awaiting review',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'No pending requests. New submissions from /register will appear here in real-time.',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 36,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('Applicant')),
                  DataColumn(label: Text('Employee ID')),
                  DataColumn(label: Text('Center / Callsign')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  for (final req in requests)
                    DataRow(cells: [
                      DataCell(Text(req.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(req.employeeId)),
                      DataCell(Text('${req.dispatchCenter} (${req.radioCallsign})')),
                      DataCell(Text(req.email,
                          style: TextStyle(color: AppColors.inkSoft))),
                      DataCell(
                        processingIds.contains(req.id)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => onApprove(req),
                                    child: const Text('Approve',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.brandRed,
                                      side: const BorderSide(
                                          color: AppColors.brandRed),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => onReject(req),
                                    child: const Text('Reject',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                      ),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTableCard extends StatelessWidget {
  final List<UserAccount> users;
  final Set<String> processingUserIds;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<UserAccount> onToggleStatus;
  final _SortField sortField;
  final bool sortAscending;
  final ValueChanged<_SortField> onSort;
  final AccountRole? roleFilter;
  final ValueChanged<AccountRole?> onRoleFilterChanged;

  const _UsersTableCard({
    required this.users,
    required this.processingUserIds,
    required this.onQueryChanged,
    required this.onToggleStatus,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    this.roleFilter,
    required this.onRoleFilterChanged,
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
                const Text('Staff & Operator Accounts',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${users.length} registered',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: onQueryChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Search name or ID',
                      prefixIcon: Icon(Icons.search, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<AccountRole?>(
                  value: roleFilter,
                  hint: const Text('All Roles', style: TextStyle(fontSize: 13)),
                  items: [
                    const DropdownMenuItem<AccountRole?>(
                      value: null,
                      child: Text('All Roles'),
                    ),
                    ...AccountRole.values.map(
                      (r) => DropdownMenuItem<AccountRole?>(
                        value: r,
                        child: Text(r.label),
                      ),
                    ),
                  ],
                  onChanged: onRoleFilterChanged,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 40,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                sortColumnIndex: _SortField.values.indexOf(sortField),
                sortAscending: sortAscending,
                columns: [
                  DataColumn(
                    label: const Text('Name'),
                    onSort: (_, __) => onSort(_SortField.name),
                  ),
                  DataColumn(
                    label: const Text('Role'),
                    onSort: (_, __) => onSort(_SortField.role),
                  ),
                  DataColumn(
                    label: const Text('Status'),
                    onSort: (_, __) => onSort(_SortField.status),
                  ),
                  DataColumn(
                    label: const Text('Last Active'),
                    onSort: (_, __) => onSort(_SortField.lastActive),
                  ),
                  const DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (final u in users)
                    DataRow(cells: [
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(u.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (u.employeeId.isNotEmpty || u.radioCallsign.isNotEmpty)
                            Text(
                              [
                                if (u.employeeId.isNotEmpty) u.employeeId,
                                if (u.radioCallsign.isNotEmpty) u.radioCallsign,
                              ].join(' • '),
                              style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                            ),
                        ],
                      )),
                      DataCell(Text(u.role.label)),
                      DataCell(AccountStatusPill(status: u.status)),
                      DataCell(Text(u.lastActiveLabel,
                          style: TextStyle(color: AppColors.inkSoft))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (u.role == AccountRole.dispatcher)
                              IconButton(
                                icon: const Icon(Icons.desktop_windows_outlined, size: 16),
                                tooltip: 'Access Dispatcher Workstation & Account',
                                onPressed: () => context.go('/dashboard'),
                              ),
                            processingUserIds.contains(u.id)
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : TextButton(
                                    onPressed: () => onToggleStatus(u),
                                    child: Text(
                                      u.status == AccountStatus.active
                                          ? 'Suspend'
                                          : 'Reinstate',
                                      style: TextStyle(
                                        color: u.status == AccountStatus.active
                                            ? AppColors.brandRed
                                            : AppColors.success,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ]),
                ],
              ),
            ),
            if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No accounts match current criteria.',
                      style: TextStyle(color: AppColors.inkSoft)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleBreakdownCard extends StatelessWidget {
  final List<UserAccount> users;
  const _RoleBreakdownCard({required this.users});

  @override
  Widget build(BuildContext context) {
    final Map<AccountRole, int> breakdown = {};
    for (final r in AccountRole.values) {
      breakdown[r] = users.where((u) => u.role == r).length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role breakdown',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in breakdown.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key.label,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              ),
            Divider(color: AppColors.border),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                Text(
                  '${users.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
