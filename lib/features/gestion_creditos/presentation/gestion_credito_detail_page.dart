import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../pagos/data/pagos_models.dart';
import '../../represtamos/data/represtamos_models.dart';
import '../data/gestion_creditos_api.dart';

class GestionCreditoDetailPage extends StatefulWidget {
  const GestionCreditoDetailPage({super.key, required this.credito});

  final CreditoDisponible credito;

  @override
  State<GestionCreditoDetailPage> createState() =>
      _GestionCreditoDetailPageState();
}

class _GestionCreditoDetailPageState extends State<GestionCreditoDetailPage> {
  final _api = GestionCreditosApi();
  final _pagoSimuladoController = TextEditingController();
  late Future<_GestionCreditoDetalle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _pagoSimuladoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pagoSimuladoController.dispose();
    super.dispose();
  }

  Future<_GestionCreditoDetalle> _load() async {
    final detalle = await _api.detalleCredito(widget.credito.id);
    final represtamo = await _api.contextoReprestamo(widget.credito.id);
    return _GestionCreditoDetalle(detalle: detalle, represtamo: represtamo);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.credito.referenciaVisual)),
      body: FutureBuilder<_GestionCreditoDetalle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(
                message: 'Cargando gestion del credito...');
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'No se pudo cargar el detalle del credito.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final data = snapshot.data!;
          final contexto = data.detalle;
          final represtamo = data.represtamo;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(contexto: contexto),
              const SizedBox(height: 12),
              _ResumenCard(contexto: contexto, represtamo: represtamo),
              const SizedBox(height: 12),
              _SimulacionReprestamoCard(
                contexto: contexto,
                represtamo: represtamo,
                pagoController: _pagoSimuladoController,
              ),
              const SizedBox(height: 18),
              Text(
                'Proximas cuotas',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (contexto.cuotasPendientes.isEmpty)
                const _Notice(
                  message: 'No hay cuotas pendientes para este credito.',
                )
              else
                ...contexto.cuotasPendientes
                    .take(8)
                    .map((cuota) => _CuotaTile(cuota: cuota)),
            ],
          );
        },
      ),
    );
  }
}

class _GestionCreditoDetalle {
  const _GestionCreditoDetalle({required this.detalle, this.represtamo});

  final PagoContexto detalle;
  final ReprestamoContexto? represtamo;
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
            Text(
              credito.referenciaVisual,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              credito.cliente.nombreCompleto,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
                  text: credito.estado.isEmpty ? 'Sin estado' : credito.estado,
                ),
                _Chip(
                  text: credito.tipo.isEmpty ? 'Sin frecuencia' : credito.tipo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.contexto, required this.represtamo});

  final PagoContexto contexto;
  final ReprestamoContexto? represtamo;

  @override
  Widget build(BuildContext context) {
    final r = contexto.resumen;
    final credito = contexto.credito;
    final valorFuturo = _valorFuturo(contexto, represtamo);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MetricGrid(
              items: [
                ('Monto credito', moneyFormat(credito.monto)),
                ('Valor futuro', moneyFormat(valorFuturo)),
                ('Saldo pendiente', moneyFormat(r.saldoPendiente)),
                ('Total pagado', moneyFormat(r.totalPagado)),
                ('Cuotas pagadas', '${r.cuotasPagadas}'),
                ('Cuotas pendientes', '${r.cuotasPendientes}'),
                ('Cuotas vencidas', '${r.cuotasVencidas}'),
                ('Dias mora', '${r.diasMora}'),
                (
                  'Fecha desembolso',
                  represtamo?.credito.fechaDesembolsoOrigen == null
                      ? '-'
                      : dateFormat(represtamo!.credito.fechaDesembolsoOrigen!),
                ),
                (
                  'Fecha vencimiento',
                  represtamo?.credito.fechaVencimientoOrigen == null
                      ? '-'
                      : dateFormat(represtamo!.credito.fechaVencimientoOrigen!),
                ),
                ('Estado', credito.estado.isEmpty ? '-' : credito.estado),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulacionReprestamoCard extends StatelessWidget {
  const _SimulacionReprestamoCard({
    required this.contexto,
    required this.represtamo,
    required this.pagoController,
  });

  final PagoContexto contexto;
  final ReprestamoContexto? represtamo;
  final TextEditingController pagoController;

  @override
  Widget build(BuildContext context) {
    final saldoActual = contexto.resumen.saldoPendiente;
    final pagoSimulado = min(_parseAmount(pagoController.text), saldoActual);
    final saldoSimulado = max(saldoActual - pagoSimulado, 0).toDouble();
    final montoNuevoOficial =
        represtamo?.defaultsNuevoPrestamo.montoNuevoSolicitado ?? 0;
    final montoBase =
        montoNuevoOficial > 0 ? montoNuevoOficial : contexto.credito.monto;
    final estimadoEntregar = max(montoBase - saldoSimulado, 0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulacion de re-prestamo',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Simulacion referencial. No crea solicitud ni modifica el credito.',
              style: TextStyle(
                color: Color(0xFF5D6B7C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pagoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Pago simulado',
                prefixIcon: Icon(Icons.payments_rounded),
                helperText: 'Solo calcula visualmente, no registra pago.',
              ),
            ),
            const SizedBox(height: 12),
            _MetricGrid(
              items: [
                (
                  'Valor futuro',
                  moneyFormat(_valorFuturo(contexto, represtamo))
                ),
                ('Saldo pendiente actual', moneyFormat(saldoActual)),
                ('Pago simulado aplicado', moneyFormat(pagoSimulado)),
                ('Saldo despues de pago', moneyFormat(saldoSimulado)),
                ('Monto base nuevo', moneyFormat(montoBase)),
                ('Estimado a entregar', moneyFormat(estimadoEntregar)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              montoNuevoOficial > 0
                  ? 'Estimado usando el monto nuevo sugerido por el contexto oficial de re-prestamo.'
                  : 'Estimado visual: monto del credito menos saldo despues del pago simulado.',
              style: const TextStyle(
                color: Color(0xFF5D6B7C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => SizedBox(
              width: _compactColumnWidth(context),
              child: _Metric(label: item.$1, value: item.$2),
            ),
          )
          .toList(),
    );
  }
}

double _compactColumnWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 520) return (width - 64) / 3;
  return (width - 48) / 2;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(
              fontSize: 12.5,
              height: 1.25,
            ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Color(0xFF5D6B7C),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF172A45),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
          'Vence: ${dateFormat(cuota.fechaPago)} | Estado: ${cuota.estado}',
        ),
        trailing: Text(
          moneyFormat(cuota.total),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
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
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
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

double _valorFuturo(
  PagoContexto contexto,
  ReprestamoContexto? represtamo,
) {
  final fromReprestamo = represtamo?.resumen.valorFuturoPrestamo ?? 0;
  if (fromReprestamo > 0) return fromReprestamo;
  if (contexto.resumen.totalAPagar > 0) return contexto.resumen.totalAPagar;
  return contexto.credito.monto;
}

double _parseAmount(String value) {
  final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return parsed < 0 ? 0 : parsed;
}
