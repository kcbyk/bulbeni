import 'package:flutter/material.dart';

class SquircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;

  const SquircleIcon({
    super.key,
    required this.icon,
    this.size = 46,
    this.iconSize = 22,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? const Color(0xFF1C1C1F) : const Color(0xFFEFEFF2));
    final fg = iconColor ?? (isDark ? Colors.white : Colors.black87);
    final border = borderColor ?? (isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE2E2E6));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.35),
        border: Border.all(color: border, width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}
