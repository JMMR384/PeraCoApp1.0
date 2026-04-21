import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';

class MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const MapButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
        ),
        child: Icon(icon, color: PeraCoColors.primary, size: 22),
      ),
    );
  }
}
