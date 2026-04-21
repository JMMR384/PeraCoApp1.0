import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class Address {
  final String id;
  final String nombre;
  final String direccion;
  final String ciudad;
  final bool esPrincipal;

  Address({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    this.esPrincipal = false,
  });

  factory Address.fromMap(Map<String, dynamic> map) => Address(
        id: map['id'] as String,
        nombre: map['nombre'] as String? ?? 'Sin nombre',
        direccion: map['direccion'] as String? ?? '',
        ciudad: map['ciudad'] as String? ?? '',
        esPrincipal: map['es_principal'] as bool? ?? false,
      );
}

class AddressesNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  final Ref ref;
  AddressesNotifier(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) { state = const AsyncValue.data([]); return; }
      final data = await SupabaseConfig.client
          .from('direcciones')
          .select()
          .eq('usuario_id', userId)
          .order('es_principal', ascending: false);
      state = AsyncValue.data((data as List).map((e) => Address.fromMap(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> add({required String nombre, required String direccion, required String ciudad, bool esPrincipal = false}) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) return false;
      if (esPrincipal) {
        await SupabaseConfig.client.from('direcciones').update({'es_principal': false}).eq('usuario_id', userId);
      }
      await SupabaseConfig.client.from('direcciones').insert({
        'usuario_id': userId, 'nombre': nombre.trim(),
        'direccion': direccion.trim(), 'ciudad': ciudad.trim(), 'es_principal': esPrincipal,
      });
      await load();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> update({required String id, required String nombre, required String direccion, required String ciudad, bool esPrincipal = false}) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      if (esPrincipal && userId != null) {
        await SupabaseConfig.client.from('direcciones').update({'es_principal': false}).eq('usuario_id', userId);
      }
      await SupabaseConfig.client.from('direcciones').update({
        'nombre': nombre.trim(), 'direccion': direccion.trim(),
        'ciudad': ciudad.trim(), 'es_principal': esPrincipal,
      }).eq('id', id);
      await load();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(String id) async {
    try {
      await SupabaseConfig.client.from('direcciones').delete().eq('id', id);
      await load();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> setPrincipal(String id) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      await SupabaseConfig.client.from('direcciones').update({'es_principal': false}).eq('usuario_id', userId!);
      await SupabaseConfig.client.from('direcciones').update({'es_principal': true}).eq('id', id);
      await load();
      return true;
    } catch (_) { return false; }
  }
}

final addressesProvider = StateNotifierProvider<AddressesNotifier, AsyncValue<List<Address>>>((ref) {
  return AddressesNotifier(ref);
});
