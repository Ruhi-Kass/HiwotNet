import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';

/// Active/Suspended pill for the User Management table, built on the same
/// [StatusPill] shape the dispatcher console's fleet badges use.
class AccountStatusPill extends StatelessWidget {
  final AccountStatus status;
  const AccountStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == AccountStatus.active;
    return StatusPill(
      background: active ? AppColors.success : AppColors.brandRed,
      foreground: Colors.white,
      label: active ? 'Active' : 'Suspended',
    );
  }
}

/// Generic small pill for hospital / ambulance "Active" / "In Service"
/// style statuses on the Registry screen.
class SimpleStatusPill extends StatelessWidget {
  final String label;
  final bool positive;
  const SimpleStatusPill({super.key, required this.label, this.positive = true});

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      background: positive ? AppColors.success : AppColors.chipBg,
      foreground: positive ? Colors.white : AppColors.inkSoft,
      label: label,
    );
  }
}
