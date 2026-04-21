import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';
import 'package:peraco/features/farmer/products/models/farmer_product.dart';

class FarmerProductsNotifier extends StateNotifier<AsyncValue<List<FarmerProduct>>> {
  final Ref ref;
  FarmerProductsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final _client = SupabaseConfig.client;

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) { state = const AsyncValue.data([]); return; }

      final data = await _client
          .from('productos')
          .select('*, categoria:categorias!categoria_id(nombre)')
          .eq('vendedor_id', userId)
          .order('created_at', ascending: false);

      final products = (data as List).map((e) => FarmerProduct.fromMap(e)).toList();
      state = AsyncValue.data(products);
    } catch (e, st) {
      print('ERROR CARGANDO MIS PRODUCTOS: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createProduct({
    required String nombre,
    String? descripcion,
    required double precio,
    required String unidad,
    required double stock,
    String? categoriaId,
    bool esTemporada = false,
  }) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) return false;

      await _client.from('productos').insert({
        'vendedor_id': userId,
        'nombre': nombre.trim(),
        'descripcion': descripcion?.trim(),
        'precio': precio,
        'unidad': unidad,
        'stock': stock,
        'categoria_id': categoriaId,
        'es_temporada': esTemporada,
        'activo': true,
      });

      await loadProducts();
      return true;
    } catch (e) {
      print('ERROR CREANDO PRODUCTO: $e');
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    required String nombre,
    String? descripcion,
    required double precio,
    required String unidad,
    required double stock,
    String? categoriaId,
    bool esTemporada = false,
    String? imagenUrl,
  }) async {
    try {
      final data = {
        'nombre': nombre.trim(),
        'descripcion': descripcion?.trim(),
        'precio': precio,
        'unidad': unidad,
        'stock': stock,
        'categoria_id': categoriaId,
        'es_temporada': esTemporada,
      };
      if (imagenUrl != null) data['imagen_url'] = imagenUrl;
      await _client.from('productos').update(data).eq('id', id);

      await loadProducts();
      return true;
    } catch (e) {
      print('ERROR ACTUALIZANDO PRODUCTO: $e');
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool activo) async {
    try {
      await _client.from('productos').update({'activo': activo}).eq('id', id);
      await loadProducts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _client.from('productos').delete().eq('id', id);
      await loadProducts();
      return true;
    } catch (e) {
      print('ERROR ELIMINANDO PRODUCTO: $e');
      return false;
    }
  }
}

final farmerProductsProvider = StateNotifierProvider<FarmerProductsNotifier, AsyncValue<List<FarmerProduct>>>((ref) {
  return FarmerProductsNotifier(ref);
});