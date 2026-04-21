import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/crops/data/crops_data.dart';

class CropDetailSheet extends StatelessWidget {
  final CropInfo crop;
  const CropDetailSheet({super.key, required this.crop});

  static void show(BuildContext context, CropInfo crop) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => CropDetailSheet(crop: crop),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            Container(width: 64, height: 64,
                decoration: BoxDecoration(color: crop.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(crop.emoji, style: const TextStyle(fontSize: 34)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(crop.nombre, style: PeraCoText.h2(context)),
              const SizedBox(height: 4),
              Text(crop.clima, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
              Text(crop.altitud, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 20),

          // Ficha técnica
          _Section(title: 'Ficha tecnica', color: crop.color, children: [
            _InfoRow(icon: Icons.calendar_month_outlined, label: 'Siembra', value: crop.siembraLabel),
            _InfoRow(icon: Icons.agriculture_outlined, label: 'Cosecha', value: crop.cosechaLabel),
            _InfoRow(icon: Icons.schedule, label: 'Dias a cosecha', value: crop.diasLabel),
            _InfoRow(icon: Icons.water_drop_outlined, label: 'Agua', value: crop.agua),
            _InfoRow(icon: Icons.grass, label: 'Suelo', value: crop.suelo),
          ]),
          const SizedBox(height: 16),

          // Consejos
          _Section(title: 'Consejos de cultivo', color: crop.color, children: [
            ...crop.consejos.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 22, height: 22, margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(color: crop.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: crop.color)))),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: PeraCoText.body(context).copyWith(height: 1.45))),
              ]),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;
  const _Section({required this.title, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: PeraCoText.bodyBold(context).copyWith(color: color)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: PeraCoColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(label, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary))),
          Expanded(child: Text(value, style: PeraCoText.bodyBold(context).copyWith(fontSize: 13))),
        ]));
  }
}
