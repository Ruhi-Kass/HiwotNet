import 'package:flutter/material.dart';

/// The generic colored pill shape shared by every status indicator in the
/// app — fleet unit status (`StatusBadge`), account status, hospital
/// status, ambulance status. Centralizing the shape/typography here is
/// what keeps the dispatcher console and the admin panel looking like one
/// product instead of two differently-styled apps bolted together.
class StatusPill extends StatelessWidget {
  final Color background;
  final Color foreground;
  final String label;

  const StatusPill({
    super.key,
    required this.background,
    required this.foreground,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = foreground == Colors.white ? background : foreground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
