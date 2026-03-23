import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:peraco/core/config/supabase_config.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }
enum UserRole { clienteB2C, clienteB2B, agricultor, comerciante, peragoger, unknown }

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserRole role;
  final String? userName;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.role = UserRole.unknown,
    this.userName,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserRole? role,
    String? userName,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _client = SupabaseConfig.client;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        final profile = await _fetchUserProfile(response.user!.id);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
          role: profile['role'],
          userName: profile['name'],
        );
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Correo o contrasena incorrectos',
      );
      return false;
    } on AuthException catch (e) {
      String msg = 'Correo o contrasena incorrectos';
      if (e.message == 'Email not confirmed') {
        msg = 'Debes confirmar tu correo electronico';
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error de conexion. Verifica tu internet.',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    try {
      final data = await _client
          .from('usuarios')
          .select('nombre, rol')
          .eq('id', userId)
          .single();
      final nombre = data['nombre'] as String?;
      return {
        'name': nombre != null ? _capitalizeNombre(nombre) : null,
        'role': _parseRole(data['rol'] as String?),
      };
    } catch (_) {
      return {'name': null, 'role': UserRole.unknown};
    }
  }

  String _capitalizeNombre(String nombre) {
    return nombre.trim().split(' ').map((palabra) {
      if (palabra.isEmpty) return '';
      return palabra[0].toUpperCase() + palabra.substring(1).toLowerCase();
    }).join(' ');
  }

  UserRole _parseRole(String? rol) {
    switch (rol) {
      case 'cliente_b2c': return UserRole.clienteB2C;
      case 'cliente_b2b': return UserRole.clienteB2B;
      case 'agricultor': return UserRole.agricultor;
      case 'comerciante': return UserRole.comerciante;
      case 'peragoger': return UserRole.peragoger;
      default: return UserRole.unknown;
    }
  }

  Future<bool> signUpClient({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String tipoCliente,
    String? telefono,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final rol = tipoCliente == 'B2B' ? 'cliente_b2b' : 'cliente_b2c';
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        await _client.from('usuarios').insert({
          'id': response.user!.id,
          'email': email.trim(),
          'nombre': _capitalizeNombre(nombre),
          'apellido': _capitalizeNombre(apellido),
          'telefono': telefono?.trim(),
          'rol': rol,
          'created_at': DateTime.now().toIso8601String(),
        });
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
          role: tipoCliente == 'B2B' ? UserRole.clienteB2B : UserRole.clienteB2C,
          userName: _capitalizeNombre(nombre),
        );
        return true;
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'No se pudo crear la cuenta');
      return false;
    } on AuthException catch (e) {
      String msg = 'Error al crear cuenta';
      if (e.message.contains('already')) msg = 'Este correo ya esta registrado';
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Error de conexion.');
      return false;
    }
  }

  Future<bool> signUpFarmer({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String nombreFinca,
    required String ubicacion,
    String? telefono,
    String tipoVendedor = 'productor',
    String? tipoNegocio,
    List<String>? tiposProducto,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        await _client.from('usuarios').insert({
          'id': response.user!.id,
          'email': email.trim(),
          'nombre': _capitalizeNombre(nombre),
          'apellido': _capitalizeNombre(apellido),
          'telefono': telefono?.trim(),
          'rol': tipoVendedor == 'comerciante' ? 'comerciante' : 'agricultor',
          'created_at': DateTime.now().toIso8601String(),
        });
        await _client.from('info_vendedor').insert({
          'usuario_id': response.user!.id,
          'tipo_vendedor': tipoVendedor,
          'nombre_negocio': nombreFinca.trim(),
          'ubicacion': ubicacion.trim(),
          'tipo_negocio': tipoNegocio,
          'tipos_producto': tiposProducto,
        });
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
          role: tipoVendedor == 'comerciante' ? UserRole.comerciante : UserRole.agricultor,
          userName: _capitalizeNombre(nombre),
        );
        return true;
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'No se pudo crear la cuenta');
      return false;
    } on AuthException catch (e) {
      String msg = 'Error al crear cuenta';
      if (e.message.contains('already')) msg = 'Este correo ya esta registrado';
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Error de conexion.');
      return false;
    }
  }

  Future<bool> signUpDriver({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String tipoVehiculo,
    required String placa,
    String? telefono,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        await _client.from('usuarios').insert({
          'id': response.user!.id,
          'email': email.trim(),
          'nombre': _capitalizeNombre(nombre),
          'apellido': _capitalizeNombre(apellido),
          'telefono': telefono?.trim(),
          'rol': 'peragoger',
          'created_at': DateTime.now().toIso8601String(),
        });
        await _client.from('info_peragoger').insert({
          'usuario_id': response.user!.id,
          'tipo_vehiculo': tipoVehiculo,
          'placa': placa.trim().toUpperCase(),
          'estado': 'disponible',
        });
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
          role: UserRole.peragoger,
          userName: _capitalizeNombre(nombre),
        );
        return true;
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'No se pudo crear la cuenta');
      return false;
    } on AuthException catch (e) {
      String msg = 'Error al crear cuenta';
      if (e.message.contains('already')) msg = 'Este correo ya esta registrado';
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Error de conexion.');
      return false;
    }
  }

  Future<void> checkCurrentSession() async {
    final user = SupabaseConfig.currentUser;
    if (user != null) {
      final profile = await _fetchUserProfile(user.id);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        role: profile['role'],
        userName: profile['name'],
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});