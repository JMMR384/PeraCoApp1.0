import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String _appVersion = '1.0.0';
  static const String _clientId   = 'peraco-mobile';

  static String get url      => dotenv.env['SUPABASE_URL']      ?? 'http://localhost:54321';
  static String get anonKey  => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      headers: {
        'X-App-Version': _appVersion,
        'X-Platform':    Platform.operatingSystem,   // android | ios | windows | macos | linux
        'X-Client-Id':   _clientId,
        // Evita el interstitial de ngrok en desarrollo
        'ngrok-skip-browser-warning': 'true',
      },
      // supabase_flutter renueva el JWT automáticamente antes de que expire.
      // authFlowType por defecto es PKCE (más seguro que implicit).
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client       => Supabase.instance.client;
  static User?           get currentUser => client.auth.currentUser;
  static bool            get isAuthenticated => currentUser != null;
}
