import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/profile/providers/addresses_provider.dart';
import 'package:peraco/features/profile/widgets/address_form_sheet.dart';

class AddressCard extends ConsumerWidget {
  final Address address;
  const AddressCard({super.key, required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: address.esPrincipal ? PeraCoColors.primary.withValues(alpha: 0.3) : PeraCoColors.divider),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: address.esPrincipal ? PeraCoColors.primary.withValues(alpha: 0.1) : PeraCoColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            address.nombre.toLowerCase().contains('casa') ? Icons.home_outlined
                : address.nombre.toLowerCase().contains('oficina') || address.nombre.toLowerCase().contains('trabajo') ? Icons.work_outlined
                : Icons.location_on_outlined,
            color: address.esPrincipal ? PeraCoColors.primary : PeraCoColors.textSecondary, size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(address.nombre, style: PeraCoText.bodyBold(context)),
            if (address.esPrincipal) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: PeraCoColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('Principal', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(address.direccion, style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (address.ciudad.isNotEmpty)
            Text(address.ciudad, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: PeraCoColors.textHint),
          onSelected: (val) async {
            if (val == 'edit') {
              AddressFormSheet.show(context, address: address);
            } else if (val == 'principal') {
              await ref.read(addressesProvider.notifier).setPrincipal(address.id);
            } else if (val == 'delete') {
              final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar direccion'),
                      content: Text('Eliminar "${address.nombre}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Eliminar', style: TextStyle(color: PeraCoColors.error))),
                      ]));
              if (confirm == true) await ref.read(addressesProvider.notifier).delete(address.id);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editar')])),
            if (!address.esPrincipal)
              const PopupMenuItem(value: 'principal', child: Row(children: [Icon(Icons.star_outline, size: 18), SizedBox(width: 8), Text('Hacer principal')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: PeraCoColors.error), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: PeraCoColors.error))])),
          ],
        ),
      ]),
    );
  }
}
