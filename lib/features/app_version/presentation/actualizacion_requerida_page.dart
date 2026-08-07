import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/app_button.dart';
import '../data/app_version_models.dart';

class ActualizacionRequeridaPage extends StatefulWidget {
  const ActualizacionRequeridaPage({
    super.key,
    required this.status,
    required this.installedVersion,
    required this.onRetry,
  });

  final AppVersionStatus status;
  final InstalledAppVersion installedVersion;
  final Future<void> Function() onRetry;

  @override
  State<ActualizacionRequeridaPage> createState() =>
      _ActualizacionRequeridaPageState();
}

class _ActualizacionRequeridaPageState
    extends State<ActualizacionRequeridaPage> {
  bool _loading = false;
  String? _error;

  Future<void> _download() async {
    final rawUrl = widget.status.urlDescarga.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      setState(() => _error = 'No hay una URL valida de descarga configurada.');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _error = 'No se pudo abrir la URL de descarga.');
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.status.mensaje.trim().isNotEmpty
        ? widget.status.mensaje
        : 'Tu version de CrediNexo esta desactualizada. Para continuar usando la app, descarga e instala la version mas reciente.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        child: Icon(
                          Icons.system_update_alt_rounded,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Actualizacion requerida',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 20),
                      _InfoRow(
                        label: 'Version instalada',
                        value: widget.installedVersion.display,
                      ),
                      _InfoRow(
                        label: 'Version requerida',
                        value: widget.status.versionMinima,
                      ),
                      if (widget.status.versionActual.trim().isNotEmpty)
                        _InfoRow(
                          label: 'Ultima version',
                          value: widget.status.versionActual,
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      AppButton(
                        label: 'Descargar actualizacion',
                        icon: Icons.download_rounded,
                        onPressed: _download,
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Reintentar',
                        icon: Icons.sync_rounded,
                        outlined: true,
                        loading: _loading,
                        onPressed: _retry,
                      ),
                    ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey)),
          Flexible(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
