import 'package:flutter/material.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/app_access/data/app_access_api.dart';
import 'features/app_access/data/app_access_models.dart';
import 'features/app_access/presentation/app_cerrada_page.dart';
import 'features/app_version/data/app_version_api.dart';
import 'features/app_version/data/app_version_models.dart';
import 'features/app_version/domain/version_compare.dart';
import 'features/app_version/presentation/actualizacion_requerida_page.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';

class CredinexoApp extends StatefulWidget {
  const CredinexoApp({super.key});

  @override
  State<CredinexoApp> createState() => _CredinexoAppState();
}

class _CredinexoAppState extends State<CredinexoApp>
    with WidgetsBindingObserver {
  final _storage = SecureStorageService();
  final _appAccessApi = AppAccessApi();
  final _appVersionApi = AppVersionApi();
  bool _loading = true;
  bool _authenticated = false;
  AppStatus? _appStatus;
  AppVersionStatus? _appVersionStatus;
  InstalledAppVersion? _installedVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppVersion();
    }
    if (state == AppLifecycleState.resumed && _authenticated) {
      _checkAppStatus();
    }
  }

  Future<void> _bootstrap() async {
    var hasValidToken = false;
    try {
      debugPrint('[Credinexo] Iniciando validacion de sesion local.');
      await _safeVersionStatus();
      if (_requiresUpdate) {
        debugPrint('[Credinexo] App desactualizada, bloqueando ingreso.');
        hasValidToken = await _storage.hasValidToken();
        return;
      }
      hasValidToken = await _storage.hasValidToken();
      if (!hasValidToken) {
        await _storage.clearSession();
      } else {
        final status = await _safeStatus();
        _appStatus = status;
      }
      debugPrint(
          '[Credinexo] Sesion local ${hasValidToken ? 'valida' : 'no valida'}.');
    } catch (error) {
      debugPrint('[Credinexo] Error validando sesion local: $error');
      try {
        await _storage.clearSession();
      } catch (_) {
        // Si el storage tambien falla, igual salimos del splash.
      }
      hasValidToken = false;
    } finally {
      if (mounted) {
        setState(() {
          _authenticated = hasValidToken;
          _loading = false;
        });
      }
    }
  }

  Future<void> _onLogin(AuthSession session) async {
    await _safeVersionStatus();
    if (_requiresUpdate) {
      if (mounted) setState(() => _authenticated = false);
      return;
    }
    await _storage.saveSession(session);
    final status = await _safeStatus();
    if (!mounted) return;
    setState(() {
      _authenticated = true;
      _appStatus = status;
    });
  }

  Future<void> _logout() async {
    await _storage.clearSession();
    if (!mounted) return;
    setState(() {
      _authenticated = false;
      _appStatus = null;
    });
  }

  Future<void> _checkAppStatus() async {
    final status = await _safeStatus();
    if (!mounted) return;
    setState(() {
      _appStatus = status;
      if (status?.puedeIngresar == false) {
        _authenticated = true;
      }
    });
  }

  Future<void> _checkAppVersion() async {
    await _safeVersionStatus();
    if (mounted) setState(() {});
  }

  Future<void> _safeVersionStatus() async {
    try {
      final installed = await _appVersionApi.installedVersion();
      final status = await _appVersionApi.status();
      if (!mounted) return;
      setState(() {
        _installedVersion = installed;
        _appVersionStatus = status;
      });
    } catch (error) {
      debugPrint('[Credinexo] No se pudo validar version app: $error');
    }
  }

  Future<AppStatus?> _safeStatus() async {
    try {
      return await _appAccessApi.status();
    } catch (error) {
      debugPrint('[Credinexo] No se pudo validar horario app: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Credinexo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _loading
          ? const _SplashView()
          : _requiresUpdate &&
                  _appVersionStatus != null &&
                  _installedVersion != null
              ? ActualizacionRequeridaPage(
                  status: _appVersionStatus!,
                  installedVersion: _installedVersion!,
                  onRetry: _checkAppVersion,
                )
              : _authenticated
                  ? (_appStatus?.puedeIngresar == false
                      ? AppCerradaPage(
                          status: _appStatus!,
                          onRetry: _checkAppStatus,
                          onLogout: _logout,
                        )
                      : HomePage(onLogout: _logout))
                  : LoginPage(onLogin: _onLogin),
    );
  }

  bool get _requiresUpdate {
    final status = _appVersionStatus;
    final installed = _installedVersion;
    if (status == null || installed == null) return false;
    if (!status.actualizacionObligatoria) return false;
    try {
      return isVersionLowerThan(installed.display, status.versionMinima);
    } catch (error) {
      debugPrint('[Credinexo] Version minima invalida: $error');
      return false;
    }
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
