import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Action item model used to render both desktop header buttons and
/// high-contrast responsive mobile menu items with guaranteed legibility.
class BrandBarAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const BrandBarAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });
}

/// Top bar with the HIWONET-RESPONSE wordmark, shared by the Landing,
/// Registration and (optionally) Login screens. Sized compact (50px) and
/// styled with a slightly transparent frosted glass effect.
class BrandBar extends StatelessWidget implements PreferredSizeWidget {
  final String tagline;
  final List<Widget> actions;
  final List<BrandBarAction>? navItems;
  final Color? backgroundColor;
  final bool showBackButton;
  final String backRoute;
  final bool? isLight;
  final bool isRedGlass;
  final VoidCallback? onBrandTap;

  const BrandBar({
    super.key,
    this.tagline = 'Command Center Portal',
    this.actions = const [],
    this.navItems,
    this.backgroundColor,
    this.showBackButton = false,
    this.backRoute = '/',
    this.isLight,
    this.isRedGlass = false,
    this.onBrandTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, _, __) {
        final effectiveLight = isLight ?? !AppThemeController.isDark;
        return LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          final showTagline = constraints.maxWidth >= 1200;
          final showMobileMenu = !isWide;

      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: preferredSize.height,
            decoration: BoxDecoration(
              color: isRedGlass
                  ? null
                  : (effectiveLight
                      ? (backgroundColor ?? Colors.white.withValues(alpha: 0.88))
                      : null),
              gradient: isRedGlass
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFF1E56).withValues(alpha: 0.94),
                        const Color(0xFFE81B4E).withValues(alpha: 0.90),
                        const Color(0xFFCC1443).withValues(alpha: 0.95),
                      ],
                    )
                  : (effectiveLight
                      ? null
                      : LinearGradient(
                          colors: [
                            const Color(0xFF0B0F1A).withValues(alpha: 0.85),
                            const Color(0xFF121722).withValues(alpha: 0.80),
                          ],
                        )),
              border: Border(
                top: BorderSide(
                  color: isRedGlass
                      ? Colors.white.withValues(alpha: 0.32)
                      : (effectiveLight
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.12)),
                  width: 0.8,
                ),
                bottom: BorderSide(
                  color: isRedGlass
                      ? Colors.white.withValues(alpha: 0.20)
                      : (effectiveLight
                          ? const Color(0xFFE2E8F0)
                          : Colors.white.withValues(alpha: 0.08)),
                  width: 1.0,
                ),
              ),
              boxShadow: isRedGlass
                  ? [
                      BoxShadow(
                        color: const Color(0xFFA00D33).withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showBackButton) ...[
                  _HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Go back',
                    isLight: effectiveLight,
                    isRedGlass: isRedGlass,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go(backRoute);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                // Logo mark + brand text wrapped in clickable region
                InkWell(
                  onTap: onBrandTap ?? () => context.go('/'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo mark — matching uploaded emblem
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
                          alignment: Alignment.center,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB91C1C),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'HIWONET',
                          style: TextStyle(
                            color: isRedGlass
                                ? Colors.white
                                : (effectiveLight ? const Color(0xFF0F172A) : Colors.white),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                        if (constraints.maxWidth >= 520) ...[
                          Text(
                            '-RESPONSE',
                            style: TextStyle(
                              color: isRedGlass
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : (effectiveLight
                                      ? const Color(0xFF64748B)
                                      : Colors.white.withValues(alpha: 0.50)),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (showTagline && tagline.isNotEmpty) ...[
                  const SizedBox(width: 14),
                  Container(
                    height: 16,
                    width: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isRedGlass
                            ? [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0.0),
                              ]
                            : (effectiveLight
                                ? [
                                    const Color(0xFFCBD5E1).withValues(alpha: 0.0),
                                    const Color(0xFFCBD5E1),
                                    const Color(0xFFCBD5E1).withValues(alpha: 0.0),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.25),
                                    Colors.white.withValues(alpha: 0.0),
                                  ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    tagline,
                    style: TextStyle(
                      color: isRedGlass
                          ? Colors.white.withValues(alpha: 0.85)
                          : (effectiveLight
                              ? const Color(0xFF64748B)
                              : Colors.white.withValues(alpha: 0.55)),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // Actions container wrapped in Expanded + ScrollView so RenderFlex can NEVER overflow
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.hardEdge,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showMobileMenu) ...[
                            // On screens < 1040px, show the compact glass Menu button
                            Container(
                              decoration: BoxDecoration(
                                color: isRedGlass
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : (effectiveLight
                                        ? const Color(0xFFF1F5F9)
                                        : Colors.white.withValues(alpha: 0.08)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isRedGlass
                                      ? Colors.white.withValues(alpha: 0.35)
                                      : (effectiveLight ? const Color(0xFFCBD5E1) : Colors.white24),
                                ),
                              ),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  final nav = Navigator.maybeOf(context);
                                  if (nav != null) {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      backgroundColor: AppColors.surface,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                                      ),
                                      builder: (ctx) => SafeArea(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                                          ),
                                          child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Center(
                                                child: Container(
                                                  width: 44,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFCBD5E1),
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFB91C1C),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(Icons.local_hospital_rounded,
                                                        color: Colors.white, size: 18),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Text(
                                                    'Portal Navigation',
                                                    style: TextStyle(
                                                      color: Color(0xFF0F172A),
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 17,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  const ThemeToggleButton(compact: true),
                                                  const SizedBox(width: 6),
                                                  IconButton(
                                                    icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                                                    onPressed: () => Navigator.of(ctx).pop(),
                                                  ),
                                                ],
                                              ),
                                              const Divider(color: Color(0xFFE2E8F0), height: 24),
                                              if (navItems != null && navItems!.isNotEmpty) ...[
                                                for (final item in navItems!)
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    child: Material(
                                                      color: item.isPrimary ? const Color(0xFFB91C1C) : const Color(0xFFF8FAFC),
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: InkWell(
                                                        borderRadius: BorderRadius.circular(10),
                                                        onTap: () {
                                                          Navigator.of(ctx).pop();
                                                          item.onPressed();
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(
                                                              color: item.isPrimary
                                                                  ? const Color(0xFFB91C1C)
                                                                  : const Color(0xFFE2E8F0),
                                                              width: 1.2,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              if (item.icon != null) ...[
                                                                Icon(
                                                                  item.icon,
                                                                  size: 20,
                                                                  color: item.isPrimary ? Colors.white : const Color(0xFFB91C1C),
                                                                ),
                                                                const SizedBox(width: 12),
                                                              ],
                                                              Expanded(
                                                                child: Text(
                                                                  item.label,
                                                                  style: TextStyle(
                                                                    color: item.isPrimary ? Colors.white : const Color(0xFF0F172A),
                                                                    fontSize: 14.5,
                                                                    fontWeight: FontWeight.w700,
                                                                  ),
                                                                ),
                                                              ),
                                                              Icon(
                                                                Icons.arrow_forward_ios_rounded,
                                                                size: 14,
                                                                color: item.isPrimary
                                                                    ? Colors.white.withValues(alpha: 0.85)
                                                                    : const Color(0xFF94A3B8),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ] else ...[
                                                for (final a in actions)
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      child: a,
                                                    ),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                  }
                                },
                                icon: Icon(
                                  Icons.menu_rounded,
                                  color: isRedGlass
                                      ? Colors.white
                                      : (effectiveLight ? const Color(0xFF0F172A) : Colors.white),
                                  size: 18,
                                ),
                                label: Text(
                                  'Menu',
                                  style: TextStyle(
                                    color: isRedGlass
                                        ? Colors.white
                                        : (effectiveLight ? const Color(0xFF0F172A) : Colors.white),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            if (actions.isNotEmpty) ...[
                              for (final a in actions)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: a,
                                ),
                            ] else if (navItems != null && navItems!.isNotEmpty) ...[
                              for (final item in navItems!)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: HeaderHoverButton(
                                    isRedGlass: isRedGlass,
                                    label: item.label,
                                    icon: item.icon,
                                    isPrimary: item.isPrimary,
                                    onPressed: item.onPressed,
                                    isLight: effectiveLight,
                                  ),
                                ),
                            ],
                          ],
                          const SizedBox(width: 8),
                          const ThemeToggleButton(compact: true, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
      },
    );
  }
}

/// A header button with smooth hover background and border color shifts.
class HeaderHoverButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;
  final bool? isLight;
  final bool isRedGlass;

  const HeaderHoverButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.icon,
    this.isLight,
    this.isRedGlass = false,
  });

  @override
  State<HeaderHoverButton> createState() => _HeaderHoverButtonState();
}

class _HeaderHoverButtonState extends State<HeaderHoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveLight = widget.isLight ?? !AppThemeController.isDark;

    final baseColor = widget.isRedGlass
        ? (widget.isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.12))
        : (widget.isPrimary ? AppColors.brandRed : Colors.transparent);

    final hoverColor = widget.isRedGlass
        ? (widget.isPrimary
            ? const Color(0xFFFFF1F2)
            : Colors.white.withValues(alpha: 0.24))
        : (widget.isPrimary
            ? const Color(0xFFFF3B3B)
            : (effectiveLight
                ? const Color(0xFFF1F5F9)
                : Colors.white.withValues(alpha: 0.12)));

    final textColor = widget.isRedGlass
        ? (widget.isPrimary
            ? const Color(0xFFFF1E56)
            : Colors.white)
        : (widget.isPrimary
            ? Colors.white
            : (effectiveLight
                ? (_isHovered ? const Color(0xFF0F172A) : const Color(0xFF334155))
                : (_isHovered ? Colors.white : Colors.white.withValues(alpha: 0.82))));

    final borderColor = widget.isRedGlass
        ? (widget.isPrimary
            ? Colors.white
            : (_isHovered
                ? Colors.white.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.22)))
        : (widget.isPrimary
            ? (_isHovered ? const Color(0xFFFF5E5E) : AppColors.brandRed)
            : (effectiveLight
                ? (_isHovered ? const Color(0xFFCBD5E1) : Colors.transparent)
                : (_isHovered ? Colors.white.withValues(alpha: 0.28) : Colors.transparent)));

    final boxShadow = widget.isRedGlass
        ? (widget.isPrimary
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : (_isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null))
        : (widget.isPrimary && _isHovered
            ? [
                BoxShadow(
                  color: AppColors.brandRed.withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isPrimary ? 16 : 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : baseColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: boxShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: textColor),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: widget.isPrimary ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool? isLight;
  final bool isRedGlass;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isLight,
    this.isRedGlass = false,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveLight = widget.isLight ?? !AppThemeController.isDark;

    final bgColor = widget.isRedGlass
        ? (_hovered
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15))
        : (effectiveLight
            ? (_hovered ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC))
            : (_hovered
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.05)));

    final borderColor = widget.isRedGlass
        ? (_hovered
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.3))
        : (effectiveLight
            ? (_hovered ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0))
            : (_hovered
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1)));

    final fgColor = widget.isRedGlass
        ? Colors.white
        : (effectiveLight
            ? (_hovered ? const Color(0xFF0F172A) : const Color(0xFF475569))
            : (_hovered ? Colors.white : Colors.white70));

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: fgColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clamps page content to a sane reading/working width and centers it,
/// since this is a real desktop browser window (Portability NFR) rather
/// than a fixed-size app frame — content must reflow, not assume 1536px.
class MaxWidthCenter extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  const MaxWidthCenter({super.key, required this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
