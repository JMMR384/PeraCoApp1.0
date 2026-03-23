import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/theme/app_theme.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/core/constants/app_constants.dart';

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

class PeraCoApp extends StatelessWidget {
  const PeraCoApp({super.key});

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