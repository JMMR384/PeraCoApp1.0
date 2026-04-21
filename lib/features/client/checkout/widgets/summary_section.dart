import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';

class SummarySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  const SummarySection({super.key, required this.icon, required this.title, required this.subtitle, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: PeraCoColors.divider)),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: PeraCoColors.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: PeraCoText.bodyBold(context)),
            Text(subtitle, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          ])),
          GestureDetector(onTap: onEdit,
              child: Text('Editar', style: PeraCoText.label(context).copyWith(color: PeraCoColors.primary))),
        ]));
  }
}
