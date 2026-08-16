import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
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
  bool _downloading = false;
  double? _downloadProgress;
  String? _statusText;
  String? _error;

  Future<void> _download() async {
    final rawUrl = widget.status.urlDescarga.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      setState(() => _error = 'No hay una URL valida de descarga configurada.');
      return;
    }

    setState(() {
      _downloading = true;
      _downloadProgress = 0;
      _statusText = 'Preparando descarga...';
      _error = null;
    });

    final client = http.Client();
    File? apkFile;

    try {
      final request = http.Request('GET', uri)..followRedirects = true;
      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('El servidor respondio ${response.statusCode}.');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = _buildApkFileName(widget.status.versionActual);
      apkFile = File('${tempDir.path}${Platform.pathSeparator}$fileName');
      final sink = apkFile.openWrite();
      var received = 0;
      final total = response.contentLength ?? 0;

      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (mounted) {
          setState(() {
            _downloadProgress = total > 0 ? received / total : null;
            _statusText = total > 0
                ? 'Descargando... ${(_downloadProgress! * 100).toStringAsFixed(0)}%'
                : 'Descargando...';
          });
        }
      }

      await sink.flush();
      await sink.close();

      if (!await _looksLikeApk(apkFile)) {
        try {
          await apkFile.delete();
        } catch (_) {
          // Si no se puede borrar el archivo temporal, seguimos mostrando el error real.
        }
        throw Exception('El archivo descargado no parece ser un APK valido.');
      }

      if (!mounted) return;
      setState(() {
        _downloadProgress = 1;
        _statusText = 'Descarga completada. Abriendo instalador...';
      });

      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done && mounted) {
        setState(() {
          _error =
              'No se pudo abrir el instalador. Debe permitir instalar aplicaciones desde CrediNexo para continuar.';
          _statusText =
              'Descarga completada, pero Android bloqueo el instalador.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo descargar la actualizacion: $error';
          _statusText = null;
        });
      }
    } finally {
      client.close();
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  Future<void> _openExternalLink() async {
    final uri = Uri.tryParse(widget.status.urlDescarga.trim());
    if (uri == null || !uri.hasScheme) {
      setState(() => _error = 'No hay una URL valida para abrir.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _error = 'No se pudo abrir el enlace externo.');
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
                      if (_statusText != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _statusText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      if (_downloading || _downloadProgress != null) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: _downloadProgress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ],
                      const SizedBox(height: 22),
                      AppButton(
                        label: _downloading
                            ? 'Descargando...'
                            : 'Descargar actualizacion',
                        icon: Icons.download_rounded,
                        loading: _downloading,
                        onPressed: _downloading ? null : _download,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Abrir enlace externo',
                          icon: Icons.open_in_new_rounded,
                          outlined: true,
                          onPressed: _openExternalLink,
                        ),
                      ],
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

String _buildApkFileName(String version) {
  final buffer = StringBuffer();
  for (final codeUnit in version.trim().codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isUpper = codeUnit >= 65 && codeUnit <= 90;
    final isLower = codeUnit >= 97 && codeUnit <= 122;
    final isAllowedSymbol = codeUnit == 46 || codeUnit == 95 || codeUnit == 45;
    if (isDigit || isUpper || isLower || isAllowedSymbol) {
      buffer.writeCharCode(codeUnit);
    } else if (codeUnit == 43) {
      buffer.write('_');
    } else {
      buffer.write('_');
    }
  }
  final safeVersion = buffer.toString();
  return 'credinexo-${safeVersion.isEmpty ? 'update' : safeVersion}.apk';
}

Future<bool> _looksLikeApk(File file) async {
  if (!await file.exists()) return false;
  if (await file.length() < 4) return false;
  final input = await file.open();
  try {
    final bytes = await input.read(2);
    return bytes.length == 2 && bytes[0] == 0x50 && bytes[1] == 0x4b;
  } finally {
    await input.close();
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
