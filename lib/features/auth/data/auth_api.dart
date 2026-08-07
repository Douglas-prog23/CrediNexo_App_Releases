import '../../../core/network/api_client.dart';

class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final json = await _client.post('/auth/login', body: {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    return AuthSession.fromJson(json);
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: '${json['access_token'] ?? json['accessToken'] ?? ''}',
      user: AuthUser.fromJson(
          (json['user'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }
}

class AuthUser {
  const AuthUser({
    this.id,
    this.username,
    this.rol,
    this.empresaNombre,
    this.agenciaNombre,
    this.permisos,
  });

  final int? id;
  final String? username;
  final String? rol;
  final String? empresaNombre;
  final String? agenciaNombre;
  final Map<String, dynamic>? permisos;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final empresa = (json['empresa'] as Map?)?.cast<String, dynamic>();
    final agencia = (json['agencia'] as Map?)?.cast<String, dynamic>();
    return AuthUser(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      username: json['username']?.toString(),
      rol: json['rol']?.toString(),
      empresaNombre:
          empresa?['nombre']?.toString() ?? json['empresaNombre']?.toString(),
      agenciaNombre:
          agencia?['nombre']?.toString() ?? json['agenciaNombre']?.toString(),
      permisos: (json['permisos'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'rol': rol,
        'empresaNombre': empresaNombre,
        'agenciaNombre': agenciaNombre,
        'permisos': permisos,
      };

  bool hasPermission(String modulo, String accion) {
    final normalizedRole = (rol ?? '').toLowerCase();
    final modulePermissions = permisos?[modulo];
    if (modulePermissions is Map) {
      final value = modulePermissions[accion];
      if (value is bool) return value;
    }

    // Fallback compatible con roles historicos si el token no trae permisos.
    if (normalizedRole == 'admin' || normalizedRole == 'supervisor') {
      return true;
    }
    if (modulo == 'pagos' &&
        ['cajero', 'cobrador', 'asesor'].contains(normalizedRole) &&
        ['ver', 'crear', 'imprimir'].contains(accion)) {
      return true;
    }
    if (modulo == 'cobranza' &&
        ['cobrador', 'asesor', 'supervisor'].contains(normalizedRole) &&
        accion == 'ver') {
      return true;
    }
    if (modulo == 'prestamos_represtamo' &&
        ['asesor', 'cobrador', 'supervisor'].contains(normalizedRole) &&
        ['ver', 'crear'].contains(accion)) {
      return true;
    }
    if (modulo == 'caja_desembolso' &&
        ['cajero', 'asesor'].contains(normalizedRole) &&
        ['ver', 'crear'].contains(accion)) {
      return true;
    }
    return false;
  }

  bool hasAnyPermission(List<(String, String)> checks) {
    return checks.any((check) => hasPermission(check.$1, check.$2));
  }
}
