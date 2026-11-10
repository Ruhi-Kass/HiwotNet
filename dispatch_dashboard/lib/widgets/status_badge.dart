import 'package:flutter/material.dart';
import '../models/fleet_models.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';

/// Small color-coded pill used in the fleet list and incoming-request cards.
/// Centralizing the color/label mapping here means the map markers, the
/// fleet panel, and the request cards can never drift out of sync on what
/// "available" vs "no response" looks like — a real risk when every screen
/// draws its own badge. Built on top of the shared [StatusPill] shape so
/// it stays visually identical to the admin panel's status pills.
class StatusBadge extends StatelessWidget {
  final UnitStatus status;
  const StatusBadge({super.key, required this.status});

  ({Color bg, Color fg, String label}) get _style {
    switch (status) {
      case UnitStatus.available:
        return (bg: AppColors.success, fg: Colors.white, label: 'Available');
      case UnitStatus.enRoute:
        return (bg: AppColors.brandRed, fg: Colors.white, label: 'En Route');
      case UnitStatus.onScene:
        return (bg: const Color(0xFF334155), fg: Colors.white, label: 'On Scene');
      case UnitStatus.noResponse:
        return (bg: AppColors.brandRed, fg: Colors.white, label: 'No Response');
      case UnitStatus.offline:
        return (bg: AppColors.chipBg, fg: AppColors.inkSoft, label: 'Offline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return StatusPill(background: s.bg, foreground: s.fg, label: s.label);
  }
}
