import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/farmer/crops/data/crops_data.dart';

final cultivosProvider = FutureProvider<List<CropInfo>>((ref) async {
  try {
    final data = await SupabaseConfig.client
        .from('cultivos')
        .select()
        .order('nombre');
    return (data as List)
        .map((e) => CropInfo.fromMap(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return cropsData;
  }
});
