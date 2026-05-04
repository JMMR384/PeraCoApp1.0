class FarmerProduct {
  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String unidad;
  final double stock;
  final String? imagenUrl;
  final String? categoriaId;
  final String? categoriaNombre;
  final bool esTemporada;
  final bool activo;
  final String? cosechaId;

  FarmerProduct({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.unidad,
    required this.stock,
    this.imagenUrl,
    this.categoriaId,
    this.categoriaNombre,
    this.esTemporada = false,
    this.activo = true,
    this.cosechaId,
  });

  factory FarmerProduct.fromMap(Map<String, dynamic> map) {
    final cat = map['categoria'] as Map<String, dynamic>?;
    return FarmerProduct(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      precio: (map['precio'] as num).toDouble(),
      unidad: map['unidad'] as String,
      stock: (map['stock'] as num).toDouble(),
      imagenUrl: map['imagen_url'] as String?,
      categoriaId: map['categoria_id'] as String?,
      categoriaNombre: cat?['nombre'] as String?,
      esTemporada: map['es_temporada'] as bool? ?? false,
      activo: map['activo'] as bool? ?? true,
      cosechaId: map['cosecha_id'] as String?,
    );
  }

  String get displayPrice =>
      'COP ${precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
