import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';

class PaymentMethodsSheet extends StatelessWidget {
  const PaymentMethodsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const PaymentMethodsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Metodos de Pago', style: PeraCoText.h3(context)),
        const SizedBox(height: 20),
        Expanded(child: ListView(children: [
          _PaymentCard(icon: Icons.payments_outlined, title: 'Efectivo contra entrega',
              subtitle: 'Paga al recibir tu pedido', isActive: true, color: PeraCoColors.primary),
          _PaymentCard(icon: Icons.phone_android, title: 'Nequi',
              subtitle: 'Transferencia instantanea', isActive: false, color: const Color(0xFF00C389)),
          _PaymentCard(icon: Icons.phone_android, title: 'Daviplata',
              subtitle: 'Transferencia instantanea', isActive: false, color: const Color(0xFFED1C24)),
          _PaymentCard(icon: Icons.account_balance, title: 'PSE',
              subtitle: 'Debito directo desde tu banco', isActive: false, color: const Color(0xFF003DA5)),
          _PaymentCard(icon: Icons.credit_card, title: 'Tarjeta de credito/debito',
              subtitle: 'Visa, Mastercard, American Express', isActive: false, color: PeraCoColors.warning),
        ])),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 18, color: PeraCoColors.textHint),
            const SizedBox(width: 10),
            Expanded(child: Text('Las pasarelas de pago digitales estaran disponibles proximamente',
                style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary))),
          ]),
        ),
      ]),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final bool isActive; final Color color;
  const _PaymentCard({required this.icon, required this.title, required this.subtitle, required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? color.withValues(alpha: 0.3) : PeraCoColors.divider)),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: PeraCoText.bodyBold(context)),
          Text(subtitle, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
        ])),
        if (isActive)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('Activo', style: PeraCoText.caption(context).copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10)))
        else
          Text('Pronto', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
      ]),
    );
  }
}
