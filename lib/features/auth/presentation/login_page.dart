import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/auth_api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final Future<void> Function(AuthSession) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authApi = AuthApi();
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _authApi.login(
          username: _username.text.trim(), password: _password.text);
      if (session.accessToken.isEmpty) {
        throw const ApiException('El servidor no devolvio token de acceso.');
      }
      await widget.onLogin(session);
    } on ApiException catch (e) {
      setState(() =>
          _error = e.isUnauthorized ? 'Credenciales invalidas.' : e.message);
    } catch (_) {
      setState(() =>
          _error = 'No hay conexion con el servidor. Intente nuevamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // colocar logo
                        const SizedBox(height: 24),
                        Image.asset('assets/images/logo.png',
                            width: 120, height: 120, fit: BoxFit.contain),
                        const SizedBox(height: 18),
                        Text(
                          'Credinexo',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Acceso movil para pagos de campo',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline)),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Ingrese usuario'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Contrasena',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined)),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ingrese contrasena'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(message: _error!)
                        ],
                        const SizedBox(height: 22),
                        AppButton(
                            label: 'Iniciar sesion',
                            onPressed: _submit,
                            loading: _loading),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
            color: Color(0xFFB42318), fontWeight: FontWeight.w700),
      ),
    );
  }
}
