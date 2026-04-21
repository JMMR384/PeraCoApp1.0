import 'package:flutter/material.dart';
import 'package:peraco/core/constants/text_styles.dart';

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: PeraCoText.caption(context).copyWith(fontSize: 10)),
    ]);
  }
}
