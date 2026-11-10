import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'dispatcher_account_dialog.dart';
import 'dispatcher_avatar.dart';

class RailItem {
  final IconData icon;
  final String tooltip;
  final String? badge;
  const RailItem(this.icon, this.tooltip, {this.badge});
}

/// The narrow icon-only navigation rail on the left of the Live Map &
/// Routing console. Per the brief this screen is the dispatcher's primary
/// workstation — the icon rail (rather than a full labelled sidebar) is
/// what keeps the map/table area maximized on a real desktop browser
/// window instead of a phone-width layout.
class IconRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<RailItem> items;

  const IconRail({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_hospital,
                color: Colors.white, size: 18),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < items.length; i++)
            _RailButton(
              item: items[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          if (AuthService.instance.isAdmin) ...[
            Tooltip(
              message: 'Back to Admin Console',
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.go('/admin'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.40)),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFF2563EB), size: 19),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const ThemeToggleButton(compact: true),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ValueListenableBuilder<int>(
              valueListenable: AuthService.instance.profileUpdateNotifier,
              builder: (context, _, __) {
                final name = AuthService.instance.currentUserName;
                final photo = AuthService.instance.currentUserPhoto;
                final callsign = AuthService.instance.currentCallsign;

                return Tooltip(
                  message: 'Dispatcher Profile: $name ($callsign)\nClick to view account and upload photo',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => DispatcherAccountDialog.show(context),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: DispatcherAvatar(
                        radius: 16,
                        photoUrl: photo,
                        name: name,
                        showOnlineDot: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatefulWidget {
  final RailItem item;
  final bool selected;
  final VoidCallback onTap;

  const _RailButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.item.tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 52,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.brandRed.withValues(alpha: 0.12)
                    : (_hovered ? AppColors.chipBg : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: widget.selected
                    ? const Border(
                        left: BorderSide(color: AppColors.brandRed, width: 3),
                      )
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.item.icon,
                    size: 20,
                    color: widget.selected
                        ? AppColors.brandRed
                        : (_hovered ? AppColors.ink : AppColors.inkSoft),
                  ),
                  if (widget.item.badge != null)
                    Positioned(
                      right: -7,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.item.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
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
    );
  }
}
