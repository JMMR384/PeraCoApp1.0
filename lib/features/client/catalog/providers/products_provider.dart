import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';

class Product {
  final String id;
  final String vendedorId;
  final String categoriaId;
  final String nombre;
  final String descripcion;
  final double precio;
  final String unidad;
  final double stock;
  final String? imagenUrl;
  final bool esTemporada;
  final String? temporadaInicio;
  final String? temporadaFin;
  final String? nombreVendedor;
  final String? nombreNegocio;

  Product({
    required this.id,
    required this.vendedorId,
    required this.categoriaId,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.unidad,
    required this.stock,
    this.imagenUrl,
    this.esTemporada = false,
    this.temporadaInicio,
    this.temporadaFin,
    this.nombreVendedor,
    this.nombreNegocio,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    final vendedor = map['vendedor'] as Map<String, dynamic>?;
    final nombreNegocio = map['_nombre_negocio'] as String?;

    return Product(
      id: map['id'] as String,
      vendedorId: map['vendedor_id'] as String,
      categoriaId: map['categoria_id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      precio: (map['precio'] as num).toDouble(),
      unidad: map['unidad'] as String,
      stock: (map['stock'] as num).toDouble(),
      imagenUrl: map['imagen_url'] as String?,
      esTemporada: map['es_temporada'] as bool? ?? false,
      temporadaInicio: map['temporada_inicio'] as String?,
      temporadaFin: map['temporada_fin'] as String?,
      nombreVendedor: vendedor?['nombre'] as String?,
      nombreNegocio: nombreNegocio,
    );
  }

  String get displayFarm => nombreNegocio ?? 'Vendedor $nombreVendedor';
  String get displayPrice => 'COP ${precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  String get displayUnit => '/$unidad';
  String get displaySeason => esTemporada ? '$temporadaInicio - $temporadaFin' : '';
}

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductsNotifier() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final _client = SupabaseConfig.client;

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final data = await _client
          .from('productos')
          .select('*, vendedor:usuarios!vendedor_id(nombre)')
          .eq('activo', true)
          .order('created_at', ascending: false);

      // Traer nombres de negocio
      final vendedorIds = (data as List).map((e) => e['vendedor_id'] as String).toSet().toList();
      final infoData = await _client
          .from('info_vendedor')
          .select('usuario_id, nombre_negocio')
          .inFilter('usuario_id', vendedorIds);

      final Map<String, String> negocioMap = {};
      for (final info in infoData) {
        negocioMap[info['usuario_id'] as String] = info['nombre_negocio'] as String? ?? '';
      }

      final products = data.map((e) {
        e['_nombre_negocio'] = negocioMap[e['vendedor_id']] ?? '';
        return Product.fromMap(e);
      }).toList();

      print('PRODUCTOS CARGADOS: ${products.length}');
      state = AsyncValue.data(products);
    } catch (e, st) {
      print('ERROR CARGANDO PRODUCTOS: $e');
      state = AsyncValue.error(e, st);
    }
  }

  List<Product> filterByCategory(List<Product> products, String category) {
    if (category == 'Todos') return products;
    return products;
  }

  List<Product> searchProducts(List<Product> products, String query) {
    if (query.isEmpty) return products;
    final q = query.toLowerCase();
    return products.where((p) => p.nombre.toLowerCase().contains(q) || p.descripcion.toLowerCase().contains(q)).toList();
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier();
});

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await SupabaseConfig.client.from('categorias').select().eq('activa', true);
  return List<Map<String, dynamic>>.from(data);
});