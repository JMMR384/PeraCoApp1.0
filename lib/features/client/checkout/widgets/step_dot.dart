import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';

class StepDot extends StatelessWidget {
  final String label;
  final int step;
  final int current;
  const StepDot({super.key, required this.label, required this.step, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive = current >= step;
    final isCurrent = current == step;
    return Column(children: [
      Container(width: 32, height: 32,
          decoration: BoxDecoration(
              color: isActive ? PeraCoColors.primary : Colors.white, shape: BoxShape.circle,
              border: Border.all(color: isActive ? PeraCoColors.primary : PeraCoColors.divider, width: 2)),
          child: Center(child: isActive && !isCurrent
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text('${step + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : PeraCoColors.textHint)))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10,
          color: isActive ? PeraCoColors.primary : PeraCoColors.textHint,
          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal)),
    ]);
  }
}
