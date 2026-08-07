import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/app_access_api.dart';
import '../data/app_access_models.dart';

class AppCerradaPage extends StatefulWidget {
  const AppCerradaPage({
    super.key,
    required this.status,
    required this.onRetry,
    required this.onLogout,
  });

  final AppStatus status;
  final Future<void> Function() onRetry;
  final VoidCallback onLogout;

  @override
  State<AppCerradaPage> createState() => _AppCerradaPageState();
}

class _AppCerradaPageState extends State<AppCerradaPage> {
  final _api = AppAccessApi();
  bool _loading = false;
  String? _message;
  AppAccessRequest? _solicitud;

  @override
  void initState() {
    super.initState();
    _solicitud = widget.status.solicitudAcceso;
    _message = widget.status.mensaje.isNotEmpty
        ? widget.status.mensaje
        : 'La app esta cerrada. Se abrira nuevamente a las 6:00 AM.';
  }

  Future<void> _solicitar() async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => const _MotivoDialog(),
    );
    if (motivo == null || motivo.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final solicitud = await _api.solicitar(motivo: motivo);
      setState(() {
        _solicitud = solicitud;
        _message =
            solicitud.mensaje ?? 'Tu solicitud esta pendiente de autorizacion.';
      });
    } on ApiException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revisarSolicitud() async {
    setState(() => _loading = true);
    try {
      final solicitud = await _api.miSolicitud();
      setState(() {
        _solicitud = solicitud;
        _message = solicitud.mensaje ?? _message;
      });
      if ((solicitud.estado ?? '').toUpperCase() == 'AUTORIZADA') {
        await widget.onRetry();
      }
    } on ApiException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = (_solicitud?.estado ?? '').toUpperCase();
    final isPendiente = estado == 'PENDIENTE';
    final isAutorizada = estado == 'AUTORIZADA';
    final isRechazada = estado == 'RECHAZADA';

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
                      const CircleAvatar(
                        radius: 34,
                        backgroundColor: Color(0xFFFFF2D7),
                        child: Icon(Icons.lock_clock_rounded,
                            color: Color(0xFFB45309), size: 34),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'App cerrada',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _message ??
                            'La app esta cerrada. Se abrira nuevamente a las 6:00 AM.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 18),
                      _InfoRow(label: 'Horario', value: '6:00 AM a 7:00 PM'),
                      _InfoRow(
                          label: 'Hora servidor',
                          value: widget.status.horaActual),
                      _InfoRow(label: 'Zona', value: widget.status.zonaHoraria),
                      if (_solicitud?.estado != null) ...[
                        const SizedBox(height: 10),
                        _StatusBanner(
                          estado: estado,
                          rejected: isRechazada,
                          message: _solicitud?.motivoRespuesta,
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (!isPendiente && !isAutorizada)
                        AppButton(
                          label: 'Solicitar acceso temporal',
                          icon: Icons.send_rounded,
                          loading: _loading,
                          onPressed: _solicitar,
                        ),
                      if (isPendiente)
                        AppButton(
                          label: 'Revisar estado',
                          icon: Icons.refresh_rounded,
                          loading: _loading,
                          onPressed: _revisarSolicitud,
                        ),
                      if (isAutorizada)
                        AppButton(
                          label: 'Entrar a la app',
                          icon: Icons.login_rounded,
                          loading: _loading,
                          onPressed: widget.onRetry,
                        ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Reintentar',
                        icon: Icons.sync_rounded,
                        outlined: true,
                        loading: _loading,
                        onPressed: widget.onRetry,
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Cerrar sesion',
                        icon: Icons.logout_rounded,
                        outlined: true,
                        onPressed: widget.onLogout,
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

class _MotivoDialog extends StatefulWidget {
  const _MotivoDialog();

  @override
  State<_MotivoDialog> createState() => _MotivoDialogState();
}

class _MotivoDialogState extends State<_MotivoDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solicitar acceso temporal'),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Motivo',
          hintText: 'Necesito registrar un cobro realizado tarde.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Enviar'),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner(
      {required this.estado, this.rejected = false, this.message});

  final String estado;
  final bool rejected;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final color = rejected ? const Color(0xFFB42318) : const Color(0xFF153462);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rejected ? const Color(0xFFFFE8E8) : const Color(0xFFE7F0FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message == null || message!.trim().isEmpty
            ? 'Estado: $estado'
            : 'Estado: $estado\n$message',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
