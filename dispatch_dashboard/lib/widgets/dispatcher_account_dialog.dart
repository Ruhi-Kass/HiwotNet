import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/image_picker_service.dart';
import '../theme/app_theme.dart';

/// Mini Account Page & Profile Viewer for Dispatchers.
///
/// Strictly view-only for operational credentials:
/// - Dispatchers can view their verified information (Name, Employee ID, Callsign,
///   Sub-city / Command Center, Email, Role, Shift Status).
/// - Dispatchers CANNOT modify their radio callsign, command center / sub-city,
///   employee ID, or full name (managed exclusively by System Administration).
/// - Dispatchers can upload and sync their profile photo from their computer
///   or select an avatar icon.
class DispatcherAccountDialog extends StatefulWidget {
  const DispatcherAccountDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const DispatcherAccountDialog(),
    );
  }

  @override
  State<DispatcherAccountDialog> createState() => _DispatcherAccountDialogState();
}

class _DispatcherAccountDialogState extends State<DispatcherAccountDialog> {
  String? _photoUrl;

  // Preset emergency avatars
  static const List<(String label, String iconName, Color color)> _avatarPresets = [
    ('Command Gold', 'CG', Color(0xFFD97706)),
    ('Rapid Red', 'RR', Color(0xFFFF1E56)),
    ('Triage Green', 'TG', Color(0xFF059669)),
    ('Telemetry Blue', 'TB', Color(0xFF2563EB)),
    ('Station Purple', 'SP', Color(0xFF7C3AED)),
    ('Field Slate', 'FS', Color(0xFF475569)),
  ];

  @override
  void initState() {
    super.initState();
    _photoUrl = AuthService.instance.currentUserPhoto;
  }

  void _uploadPhoto() {
    ImagePickerService.pickImage((base64DataUrl) {
      if (mounted) {
        setState(() {
          _photoUrl = base64DataUrl;
        });
        AuthService.instance.updateCurrentUserProfile(photoUrl: base64DataUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated and synced successfully!'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _selectPreset(String text, Color color) {
    final presetKey = 'preset:$text:${color.toARGB32()}';
    setState(() {
      _photoUrl = presetKey;
    });
    AuthService.instance.updateCurrentUserProfile(photoUrl: presetKey);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avatar icon updated and synced!'),
        backgroundColor: Color(0xFF059669),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removePhoto() {
    setState(() {
      _photoUrl = '';
    });
    AuthService.instance.updateCurrentUserProfile(photoUrl: '');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile photo removed.'),
        backgroundColor: Color(0xFF64748B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAvatarWidget(String name) {
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      if (_photoUrl!.startsWith('preset:')) {
        final parts = _photoUrl!.split(':');
        final text = parts.length > 1 ? parts[1] : 'OP';
        final colorValue = parts.length > 2 ? int.tryParse(parts[2]) : null;
        final color = colorValue != null ? Color(colorValue) : AppColors.brandRed;
        return CircleAvatar(
          radius: 44,
          backgroundColor: color,
          child: Text(
            text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        );
      } else if (_photoUrl!.startsWith('data:') || _photoUrl!.length > 100) {
        try {
          final base64String = _photoUrl!.contains(',') ? _photoUrl!.split(',').last : _photoUrl!;
          return CircleAvatar(
            radius: 44,
            backgroundImage: MemoryImage(base64Decode(base64String)),
          );
        } catch (_) {}
      } else if (_photoUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: 44,
          backgroundImage: NetworkImage(_photoUrl!),
        );
      }
    }

    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';
    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.brandRed,
      child: Text(
        initial,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  Widget _buildCredentialCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData badgeIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 12, color: badgeColor),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.currentUserName;
    final empId = AuthService.instance.currentEmployeeId;
    final callsign = AuthService.instance.currentCallsign;
    final center = AuthService.instance.currentDispatchCenter;
    final email = AuthService.instance.currentEmail ?? 'dispatcher@hiwonet.et';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.badge_rounded, color: AppColors.brandRed, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispatcher Personnel Profile',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Addis Ababa Emergency Command Console',
                            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: AppColors.inkSoft),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close Profile',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Administrative Notice Banner
                if (AuthService.instance.isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'System Administrator Mode: You are accessing dispatcher personnel accounts as a System Administrator.',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.arrow_back_rounded, size: 14),
                          label: const Text('Back to Admin Console', style: TextStyle(fontSize: 11.5)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/admin');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Personnel credentials, callsigns, and command center locations are centrally assigned by Administration and view-only.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.ink,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Photo and Upload Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          _buildAvatarWidget(name),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Photo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload your official badge photo or choose an avatar icon.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _uploadPhoto,
                                  icon: const Icon(Icons.upload_file_rounded, size: 15),
                                  label: const Text('Upload Photo', style: TextStyle(fontSize: 12)),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                                if (_photoUrl != null && _photoUrl!.isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: _removePhoto,
                                    icon: const Icon(Icons.delete_outline, size: 14),
                                    label: const Text('Remove', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      foregroundColor: AppColors.brandRed,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Avatar Presets Row
                Text(
                  'Quick Avatar Icons',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final p in _avatarPresets)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => _selectPreset(p.$2, p.$3),
                            borderRadius: BorderRadius.circular(20),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: p.$3,
                              child: Text(
                                p.$2,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Read-Only Official Credentials
                Row(
                  children: [
                    Text(
                      'Official Personnel Credentials',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.lock_rounded, size: 13, color: AppColors.inkSoft),
                  ],
                ),
                const SizedBox(height: 10),

                // Full Name
                _buildCredentialCard(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  label: 'Dispatcher Full Name',
                  value: name,
                  badgeText: 'Locked',
                  badgeColor: const Color(0xFF64748B),
                  badgeIcon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 8),

                // Radio Callsign & Command Center / Sub-city
                _buildCredentialCard(
                  context: context,
                  icon: Icons.headset_mic_outlined,
                  label: 'Assigned Radio Callsign',
                  value: callsign,
                  badgeText: 'Callsign Fixed',
                  badgeColor: const Color(0xFFDC2626),
                  badgeIcon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 8),

                _buildCredentialCard(
                  context: context,
                  icon: Icons.location_city_outlined,
                  label: 'Assigned Command Center / Sub-city',
                  value: center,
                  badgeText: 'Station Fixed',
                  badgeColor: const Color(0xFF2563EB),
                  badgeIcon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 8),

                // Employee ID
                _buildCredentialCard(
                  context: context,
                  icon: Icons.badge_outlined,
                  label: 'Official Employee ID',
                  value: empId,
                  badgeText: 'Verified',
                  badgeColor: const Color(0xFF059669),
                  badgeIcon: Icons.verified_rounded,
                ),
                const SizedBox(height: 8),

                // Work Email
                _buildCredentialCard(
                  context: context,
                  icon: Icons.alternate_email_rounded,
                  label: 'Work Email Address',
                  value: email,
                  badgeText: 'Verified',
                  badgeColor: const Color(0xFF64748B),
                  badgeIcon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 8),

                // Operational Role & Active Shift
                _buildCredentialCard(
                  context: context,
                  icon: Icons.shield_outlined,
                  label: 'Operating Role & Shift',
                  value: 'Authorized Emergency Dispatcher',
                  badgeText: 'Active Shift',
                  badgeColor: const Color(0xFF059669),
                  badgeIcon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(height: 22),

                // Bottom Buttons
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF1E56)),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('End Shift & Log Out'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Sign Out'),
                            content: const Text('Are you sure you want to end your dispatcher shift?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF1E56)),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          Navigator.of(context).pop();
                          await AuthService.instance.signOut();
                          if (context.mounted) context.go('/login');
                        }
                      },
                    ),
                    const Spacer(),
                    if (AuthService.instance.isAdmin) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back_rounded, size: 15),
                        label: const Text('Back to Admin Console'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/admin');
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
