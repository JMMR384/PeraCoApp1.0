import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/constants/app_constants.dart';

class AppUpdate {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String? changelogEs;
  final bool forceUpdate;

  const AppUpdate({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.changelogEs,
    this.forceUpdate = false,
  });

  factory AppUpdate.fromMap(Map<String, dynamic> m) => AppUpdate(
    version: m['version'] as String,
    buildNumber: m['build_number'] as int,
    downloadUrl: m['download_url'] as String,
    changelogEs: m['changelog_es'] as String?,
    forceUpdate: m['force_update'] as bool? ?? false,
  );
}

/// Retorna [AppUpdate] si hay una versión más reciente disponible, o null si la app está al día.
final appUpdateProvider = FutureProvider<AppUpdate?>((ref) async {
  try {
    final data = await SupabaseConfig.client
        .from('app_versions')
        .select()
        .eq('platform', 'android')
        .eq('activo', true)
        .order('build_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    final latest = AppUpdate.fromMap(data as Map<String, dynamic>);
    if (latest.buildNumber > AppConstants.buildNumber) return latest;
    return null;
  } catch (_) {
    return null;
  }
});
