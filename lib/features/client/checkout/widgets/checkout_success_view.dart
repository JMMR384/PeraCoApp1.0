import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/router/app_router.dart';

class CheckoutSuccessView extends StatelessWidget {
  final String orderCode;
  final String? orderId;
  const CheckoutSuccessView({super.key, required this.orderCode, this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: Padding(padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 120, height: 120,
                  decoration: const BoxDecoration(color: PeraCoColors.greenPastel, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, size: 70, color: PeraCoColors.primary)),
              const SizedBox(height: 32),
              Text('Pedido confirmado!', style: PeraCoText.h2(context)),
              const SizedBox(height: 12),
              Text('Tu pedido esta siendo preparado.\nUn PeraGoger lo recogerá pronto.',
                  style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                  child: Text('Pedido #$orderCode', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primaryDark))),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.clientHome),
                      icon: const Icon(Icons.shopping_basket, size: 20),
                      label: const Text('Seguir comprando'),
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 52,
                  child: OutlinedButton.icon(
                      onPressed: orderId != null ? () => context.push('/client/tracking/$orderId') : null,
                      icon: const Icon(Icons.local_shipping_outlined, size: 20),
                      label: const Text('Rastrear pedido'),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            ]))));
  }
}
