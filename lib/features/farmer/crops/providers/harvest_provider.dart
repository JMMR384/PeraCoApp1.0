import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

enum HarvestStatus { planificado, enCrecimiento, cosechado, perdido }

extension HarvestStatusX on HarvestStatus {
  String get label {
    switch (this) {
      case HarvestStatus.planificado: return 'Planificado';
      case HarvestStatus.enCrecimiento: return 'En crecimiento';
      case HarvestStatus.cosechado: return 'Cosechado';
      case HarvestStatus.perdido: return 'Perdido';
    }
  }

  String get dbValue {
    switch (this) {
      case HarvestStatus.planificado: return 'planificado';
      case HarvestStatus.enCrecimiento: return 'en_crecimiento';
      case HarvestStatus.cosechado: return 'cosechado';
      case HarvestStatus.perdido: return 'perdido';
    }
  }

  static HarvestStatus fromDb(String v) {
    switch (v) {
      case 'en_crecimiento': return HarvestStatus.enCrecimiento;
      case 'cosechado': return HarvestStatus.cosechado;
      case 'perdido': return HarvestStatus.perdido;
      default: return HarvestStatus.planificado;
    }
  }
}

class Harvest {
  final String id;
  final String cultivoNombre;
  final DateTime? fechaSiembra;
  final DateTime fechaCosechaEstimada;
  final double? cantidadEstimada;
  final String unidad;
  final String? notas;
  final HarvestStatus estado;

  const Harvest({
    required this.id,
    required this.cultivoNombre,
    this.fechaSiembra,
    required this.fechaCosechaEstimada,
    this.cantidadEstimada,
    required this.unidad,
    this.notas,
    required this.estado,
  });

  factory Harvest.fromMap(Map<String, dynamic> m) => Harvest(
    id: m['id'] as String,
    cultivoNombre: m['cultivo_nombre'] as String,
    fechaSiembra: m['fecha_siembra'] != null ? DateTime.parse(m['fecha_siembra'] as String) : null,
    fechaCosechaEstimada: DateTime.parse(m['fecha_cosecha_estimada'] as String),
    cantidadEstimada: m['cantidad_estimada'] != null ? (m['cantidad_estimada'] as num).toDouble() : null,
    unidad: m['unidad'] as String? ?? 'kg',
    notas: m['notas'] as String?,
    estado: HarvestStatusX.fromDb(m['estado'] as String? ?? 'planificado'),
  );

  int get diasRestantes => fechaCosechaEstimada.difference(DateTime.now()).inDays;
  bool get isVencido => diasRestantes < 0 && estado == HarvestStatus.planificado;
}

class HarvestNotifier extends StateNotifier<AsyncValue<List<Harvest>>> {
  final Ref ref;
  HarvestNotifier(this.ref) : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) { state = const AsyncValue.data([]); return; }
      final data = await SupabaseConfig.client
          .from('cosechas_programadas')
          .select()
          .eq('agricultor_id', userId)
          .order('fecha_cosecha_estimada');
      state = AsyncValue.data((data as List).map((e) => Harvest.fromMap(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> add({
    required String cultivoNombre,
    DateTime? fechaSiembra,
    required DateTime fechaCosechaEstimada,
    double? cantidadEstimada,
    String unidad = 'kg',
    String? notas,
  }) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) return false;
      await SupabaseConfig.client.from('cosechas_programadas').insert({
        'agricultor_id': userId,
        'cultivo_nombre': cultivoNombre,
        'fecha_siembra': fechaSiembra?.toIso8601String().substring(0, 10),
        'fecha_cosecha_estimada': fechaCosechaEstimada.toIso8601String().substring(0, 10),
        'cantidad_estimada': cantidadEstimada,
        'unidad': unidad,
        'notas': notas?.trim(),
        'estado': 'planificado',
      });
      await load();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateStatus(String id, HarvestStatus status) async {
    try {
      await SupabaseConfig.client.from('cosechas_programadas')
          .update({'estado': status.dbValue}).eq('id', id);
      await load();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> delete(String id) async {
    try {
      await SupabaseConfig.client.from('cosechas_programadas').delete().eq('id', id);
      await load();
      return true;
    } catch (_) { return false; }
  }
}

final harvestProvider = StateNotifierProvider<HarvestNotifier, AsyncValue<List<Harvest>>>((ref) {
  return HarvestNotifier(ref);
});
