import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';

class HelpSheet extends StatelessWidget {
  const HelpSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const HelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Ayuda', style: PeraCoText.h3(context)),
        const SizedBox(height: 16),
        Expanded(child: ListView(children: const [
          _HelpItem(icon: Icons.email_outlined,        title: 'Correo',                subtitle: 'soporte@peraco.com'),
          _HelpItem(icon: Icons.phone_outlined,        title: 'Telefono',              subtitle: '+57 300 000 0000'),
          _HelpItem(icon: Icons.chat_outlined,         title: 'WhatsApp',              subtitle: '+57 300 000 0000'),
          SizedBox(height: 12),
          _HelpItem(icon: Icons.question_answer_outlined, title: 'Preguntas Frecuentes', subtitle: 'Respuestas rapidas'),
          _HelpItem(icon: Icons.policy_outlined,       title: 'Terminos y Condiciones', subtitle: 'Politicas de uso'),
          _HelpItem(icon: Icons.privacy_tip_outlined,  title: 'Politica de Privacidad', subtitle: 'Proteccion de datos'),
        ])),
        const SizedBox(height: 8),
        Text('PeraCo v1.0.0', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
        Text('Del campo a tu mesa', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _HelpItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, color: PeraCoColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: PeraCoText.bodyBold(context)),
            Text(subtitle, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          ])),
        ]));
  }
}
