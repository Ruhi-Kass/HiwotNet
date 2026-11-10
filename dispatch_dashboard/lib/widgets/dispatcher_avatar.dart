import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable circular avatar for Dispatchers with online badge indicator,
/// photo/preset/initial rendering, and error resilience.
class DispatcherAvatar extends StatelessWidget {
  final double radius;
  final String? photoUrl;
  final String name;
  final bool showOnlineDot;
  final VoidCallback? onTap;

  const DispatcherAvatar({
    super.key,
    this.radius = 16,
    this.photoUrl,
    required this.name,
    this.showOnlineDot = true,
    this.onTap,
  });

  Widget _buildCircle() {
    final cleanPhoto = photoUrl?.trim();
    if (cleanPhoto != null && cleanPhoto.isNotEmpty) {
      if (cleanPhoto.startsWith('preset:')) {
        final parts = cleanPhoto.split(':');
        final text = parts.length > 1 ? parts[1] : 'OP';
        final colorValue = parts.length > 2 ? int.tryParse(parts[2]) : null;
        final color = colorValue != null ? Color(colorValue) : AppColors.brandRed;
        return CircleAvatar(
          radius: radius,
          backgroundColor: color,
          child: Text(
            text,
            style: TextStyle(
              fontSize: radius * 0.65,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
      } else if (cleanPhoto.startsWith('data:') || cleanPhoto.length > 100) {
        try {
          final base64String =
              cleanPhoto.contains(',') ? cleanPhoto.split(',').last : cleanPhoto;
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.chipBg,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      } else if (cleanPhoto.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.chipBg,
          backgroundImage: NetworkImage(cleanPhoto),
        );
      }
    }

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'D';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brandRed,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = (radius * 0.60).clamp(7.0, 12.0);

    Widget avatarWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCircle(),
        if (showOnlineDot)
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // Live active green
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius + 4),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
