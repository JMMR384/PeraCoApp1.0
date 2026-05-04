import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/theme/app_theme.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/core/constants/app_constants.dart';
import 'package:peraco/shared/providers/app_update_provider.dart';
import 'package:peraco/shared/widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await dotenv.load(fileName: '.env');
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: PeraCoApp(),
    ),
  );
}

class PeraCoApp extends ConsumerStatefulWidget {
  const PeraCoApp({super.key});

  @override
  ConsumerState<PeraCoApp> createState() => _PeraCoAppState();
}

class _PeraCoAppState extends ConsumerState<PeraCoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    try {
      final update = await ref.read(appUpdateProvider.future);
      if (update == null) return;
      final navContext = appRouter.navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      await showDialog<void>(
        context: navContext,
        barrierDismissible: !update.forceUpdate,
        builder: (_) => UpdateDialog(update: update),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: PeraCoTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
