import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/profile/providers/addresses_provider.dart';
import 'package:peraco/features/profile/widgets/address_card.dart';
import 'package:peraco/features/profile/widgets/address_form_sheet.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Mis Direcciones', style: PeraCoText.h3(context))),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: PeraCoColors.error),
          const SizedBox(height: 12),
          Text('Error al cargar', style: PeraCoText.body(context)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => ref.read(addressesProvider.notifier).load(), child: const Text('Reintentar')),
        ])),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.location_off_outlined, size: 72, color: PeraCoColors.primaryLight.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('Sin direcciones', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Agrega tu primera direccion de entrega', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textHint)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  onPressed: () => AddressFormSheet.show(context),
                  icon: const Icon(Icons.add_location_alt, size: 20),
                  label: const Text('Agregar direccion')),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(addressesProvider.notifier).load(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
              itemCount: addresses.length,
              itemBuilder: (ctx, i) => AddressCard(address: addresses[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddressFormSheet.show(context),
        backgroundColor: PeraCoColors.primary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: Text('Agregar', style: PeraCoText.button(context).copyWith(color: Colors.white)),
      ),
    );
  }
}
