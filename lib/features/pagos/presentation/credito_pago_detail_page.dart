import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';
import '../../auth/data/auth_api.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/pagos_api.dart';
import '../data/pagos_models.dart';
import 'comprobante_preview_page.dart';
import 'pago_form_page.dart';

class CreditoPagoDetailPage extends StatefulWidget {
  const CreditoPagoDetailPage({super.key, required this.credito});

  final CreditoDisponible credito;

  @override
  State<CreditoPagoDetailPage> createState() => _CreditoPagoDetailPageState();
}

class _CreditoPagoDetailPageState extends State<CreditoPagoDetailPage> {
  final _api = PagosApi();
  final _storage = SecureStorageService();
  late Future<PagoContexto> _future;
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _future = _api.contextoCredito(widget.credito.id);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _storage.readUser();
    if (mounted) setState(() => _user = user);
  }

  void _reload() {
    setState(() => _future = _api.contextoCredito(widget.credito.id));
  }

  Future<void> _openPago(PagoContexto contexto) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PagoFormPage(contexto: contexto)),
    );
    _reload();
  }

  Future<void> _openComprobante(PagoHistorial pago) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComprobantePreviewPage(
          pagoId: pago.id,
          reimpresionAutorizada: true,
        ),
      ),
    );
    _reload();
  }

  Future<void> _solicitarReimpresion(PagoHistorial pago) async {
    final motivoController = TextEditingController(text: 'No salio el ticket');
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar reimpresion'),
        content: TextField(
          controller: motivoController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Ej. No salio el ticket',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(motivoController.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    motivoController.dispose();
    if (motivo == null) return;
    try {
      await _api.solicitarReimpresion(pago.id, motivo: motivo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada para autorizacion.')),
      );
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.credito.referenciaVisual)),
      body: FutureBuilder<PagoContexto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(
                message: 'Cargando detalle del credito...');
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'No se pudo cargar el detalle.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final contexto = snapshot.data!;
          final bloqueado = contexto.resumen.planPendienteDesembolso != null ||
              contexto.cuotasPendientes.isEmpty;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(contexto: contexto),
              const SizedBox(height: 12),
              _ResumenCard(contexto: contexto),
              if (contexto.resumen.planPendienteDesembolso != null) ...[
                const SizedBox(height: 12),
                _Notice(message: contexto.resumen.planPendienteDesembolso!),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: bloqueado ? 'Pago no disponible' : 'Registrar pago',
                icon: Icons.payments_rounded,
                onPressed: bloqueado ? null : () => _openPago(contexto),
              ),
              const SizedBox(height: 18),
              Text('Proximas cuotas',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (contexto.cuotasPendientes.isEmpty)
                const _Notice(
                    message: 'No hay cuotas pendientes para este credito.')
              else
                ...contexto.cuotasPendientes
                    .take(5)
                    .map((cuota) => _CuotaTile(cuota: cuota)),
              const SizedBox(height: 18),
              Text('Ultimos pagos',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (contexto.pagos.isEmpty)
                const _Notice(
                    message: 'Este credito aun no tiene pagos registrados.')
              else
                ...contexto.pagos.take(5).map(
                      (pago) => _PagoTile(
                        pago: pago,
                        canRequest: pago.reimpresion.puedeSolicitar &&
                            (_user?.hasPermission('pagos', 'ver') ?? false),
                        canPrint: pago.reimpresion.puedeImprimir,
                        onRequest: () => _solicitarReimpresion(pago),
                        onPrint: () => _openComprobante(pago),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.contexto});

  final PagoContexto contexto;

  @override
  Widget build(BuildContext context) {
    final credito = contexto.credito;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(credito.referenciaVisual,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(credito.cliente.nombreCompleto,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Codigo cliente: ${credito.codigoClienteVisual}'),
            if ((credito.carteraNombre ?? '').isNotEmpty)
              Text('Cartera: ${credito.carteraNombre}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                    text:
                        credito.estado.isEmpty ? 'Sin estado' : credito.estado),
                _Chip(
                    text:
                        credito.tipo.isEmpty ? 'Sin frecuencia' : credito.tipo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.contexto});

  final PagoContexto contexto;

  @override
  Widget build(BuildContext context) {
    final r = contexto.resumen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _Metric(
                        label: 'Monto',
                        value: moneyFormat(contexto.credito.monto))),
                const SizedBox(width: 10),
                Expanded(
                    child: _Metric(
                        label: 'Saldo pendiente',
                        value: moneyFormat(r.saldoPendiente))),
                const SizedBox(width: 10),
                Expanded(
                    child: _Metric(
                        label: 'Total pagado',
                        value: moneyFormat(r.totalPagado))),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                    child: _Metric(
                        label: 'Cuotas pagadas', value: '${r.cuotasPagadas}')),
                const SizedBox(width: 10),
                Expanded(
                    child: _Metric(
                        label: 'Cuotas pendientes',
                        value: '${r.cuotasPendientes}')),
                const SizedBox(width: 10),
                Expanded(
                    child: _Metric(
                        label: 'Cuotas vencidas',
                        value: '${r.cuotasVencidas}')),
                const SizedBox(width: 10),
                Expanded(
                    child: _Metric(label: 'Dias mora', value: '${r.diasMora}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 3),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _CuotaTile extends StatelessWidget {
  const _CuotaTile({required this.cuota});

  final CuotaPendientePago cuota;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Cuota ${cuota.numero} - ${moneyFormat(cuota.saldoCuota)}'),
        subtitle: Text(
            'Vence: ${dateFormat(cuota.fechaPago)} | Estado: ${cuota.estado}'),
        trailing: Text(moneyFormat(cuota.total),
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _PagoTile extends StatelessWidget {
  const _PagoTile({
    required this.pago,
    required this.canRequest,
    required this.canPrint,
    required this.onRequest,
    required this.onPrint,
  });

  final PagoHistorial pago;
  final bool canRequest;
  final bool canPrint;
  final VoidCallback onRequest;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Pago #${pago.id} - ${moneyFormat(pago.monto)}'),
        subtitle: Text(
            '${dateFormat(pago.fechaPago)} | ${pago.medioPago ?? 'Sin medio'}'),
        trailing: _ReimpresionAction(
          estado: pago.reimpresion,
          canRequest: canRequest,
          canPrint: canPrint,
          onRequest: onRequest,
          onPrint: onPrint,
        ),
      ),
    );
  }
}

class _ReimpresionAction extends StatelessWidget {
  const _ReimpresionAction({
    required this.estado,
    required this.canRequest,
    required this.canPrint,
    required this.onRequest,
    required this.onPrint,
  });

  final ReimpresionEstado estado;
  final bool canRequest;
  final bool canPrint;
  final VoidCallback onRequest;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    if (canPrint) {
      return IconButton(
        tooltip: 'Imprimir comprobante',
        icon: const Icon(Icons.print_rounded),
        onPressed: onPrint,
      );
    }
    if (canRequest) {
      return TextButton(
        onPressed: onRequest,
        child: const Text('Solicitar'),
      );
    }
    final label = switch (estado.estado.toUpperCase()) {
      'PENDIENTE' => 'Pendiente',
      'RECHAZADA' => 'Rechazada',
      'USADA' => 'Usada',
      _ => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: estado.mensaje,
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message),
    );
  }
}
