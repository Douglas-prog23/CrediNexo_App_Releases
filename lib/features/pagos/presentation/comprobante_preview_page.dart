import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/pagos_api.dart';
import '../data/pagos_models.dart';
import 'comprobante_printing.dart';

class ComprobantePreviewPage extends StatefulWidget {
  const ComprobantePreviewPage({
    super.key,
    required this.pagoId,
    this.reimpresionAutorizada = false,
  });

  final int pagoId;
  final bool reimpresionAutorizada;

  @override
  State<ComprobantePreviewPage> createState() => _ComprobantePreviewPageState();
}

class _ComprobantePreviewPageState extends State<ComprobantePreviewPage> {
  final _api = PagosApi();
  static const _loadTimeout = Duration(seconds: 12);
  late Future<ComprobanteRender> _future;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ComprobanteRender> _load() async {
    if (widget.reimpresionAutorizada) {
      return _api
          .renderComprobanteReimpresion(widget.pagoId)
          .timeout(_loadTimeout);
    }

    Object? renderError;
    try {
      final render =
          await _api.renderComprobante(widget.pagoId).timeout(_loadTimeout);
      if ((render.html ?? '').trim().isNotEmpty || render.snapshot != null) {
        return render;
      }
    } catch (error) {
      renderError = error;
    }

    try {
      return await _api
          .comprobanteSnapshot(widget.pagoId)
          .timeout(_loadTimeout);
    } catch (_) {
      if (renderError is ApiException) throw renderError;
      throw const ApiException(
        'No se pudo preparar el comprobante. Intente nuevamente.',
      );
    }
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _print(ComprobanteRender comprobante) async {
    setState(() => _printing = true);
    try {
      await printComprobanteRender(comprobante, pagoId: widget.pagoId);
      if (widget.reimpresionAutorizada) {
        await _api.marcarReimpresionUsada(widget.pagoId);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No se pudo imprimir el comprobante. Intente de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comprobante #${widget.pagoId}')),
      body: FutureBuilder<ComprobanteRender>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Preparando comprobante...');
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'No se pudo cargar el comprobante.';
            return ErrorView(message: message, onRetry: _reload);
          }
          final comprobante = snapshot.data!;
          if (widget.reimpresionAutorizada) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reimpresion autorizada',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'El comprobante #${widget.pagoId} fue autorizado por administracion. Puedes enviarlo a impresora desde este boton.',
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(comprobante.usandoPlantilla
                              ? 'Plantilla'
                              : 'Snapshot'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Imprimir comprobante',
                  icon: Icons.print_rounded,
                  loading: _printing,
                  onPressed: () => _print(comprobante),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Volver',
                  outlined: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Vista previa',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                          if (comprobante.usandoPlantilla)
                            const Chip(label: Text('Plantilla'))
                          else
                            const Chip(label: Text('Snapshot')),
                        ],
                      ),
                      const Divider(height: 24),
                      if ((comprobante.html ?? '').trim().isNotEmpty)
                        _HtmlPdfPreview(
                          comprobante: comprobante,
                          buildPdfBytes: buildComprobantePdfBytes,
                        )
                      else
                        _SnapshotPreview(snapshot: comprobante.snapshot),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Imprimir comprobante',
                icon: Icons.print_rounded,
                loading: _printing,
                onPressed: () => _print(comprobante),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Volver',
                outlined: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HtmlPdfPreview extends StatefulWidget {
  const _HtmlPdfPreview({
    required this.comprobante,
    required this.buildPdfBytes,
  });

  final ComprobanteRender comprobante;
  final Future<Uint8List> Function(ComprobanteRender, PdfPageFormat)
      buildPdfBytes;

  @override
  State<_HtmlPdfPreview> createState() => _HtmlPdfPreviewState();
}

class _HtmlPdfPreviewState extends State<_HtmlPdfPreview> {
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = widget.buildPdfBytes(widget.comprobante, ticket58PageFormat);
  }

  void _retry() {
    setState(() {
      _pdfFuture = widget.buildPdfBytes(widget.comprobante, ticket58PageFormat);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _pdfFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: LoadingView(message: 'Generando vista previa...'),
          );
        }
        if (snapshot.hasError) {
          return ErrorView(
            message:
                'No se pudo generar la vista previa. Puede intentar recargar.',
            onRetry: _retry,
          );
        }
        final bytes = snapshot.data!;
        return SizedBox(
          height: 560,
          child: PdfPreview(
            initialPageFormat: ticket58PageFormat,
            pageFormats: const {'Ticket 58mm': ticket58PageFormat},
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: false,
            allowSharing: false,
            build: (_) async => bytes,
          ),
        );
      },
    );
  }
}

class _SnapshotPreview extends StatelessWidget {
  const _SnapshotPreview({required this.snapshot});

  final Map<String, dynamic>? snapshot;

  @override
  Widget build(BuildContext context) {
    final rows = _snapshotRows(snapshot);
    if (rows.isEmpty) return const Text('Comprobante sin datos de snapshot.');
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(row.$1,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  Expanded(child: Text(row.$2)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

List<(String, String)> _snapshotRows(Map<String, dynamic>? snapshot) {
  if (snapshot == null) return const [];
  final pago = snapshot['pago'] is Map<String, dynamic>
      ? snapshot['pago'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final cliente = snapshot['cliente'] is Map<String, dynamic>
      ? snapshot['cliente'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final credito = snapshot['credito'] is Map<String, dynamic>
      ? snapshot['credito'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final aplicacion = snapshot['aplicacion'] is Map<String, dynamic>
      ? snapshot['aplicacion'] as Map<String, dynamic>
      : const <String, dynamic>{};

  return [
    ('Recibo', '${pago['numeroRecibo'] ?? pago['id'] ?? '-'}'),
    (
      'Fecha',
      dateFormat('${pago['fechaPago'] ?? pago['fechaRegistro'] ?? ''}')
    ),
    ('Cliente', '${cliente['codigo'] ?? ''} ${cliente['nombre'] ?? ''}'.trim()),
    ('Credito', '${credito['numero'] ?? credito['id'] ?? '-'}'),
    ('Monto pagado', moneyFormat(_asDouble(pago['monto']))),
    ('Medio de pago', '${pago['medioPago'] ?? '-'}'),
    ('Saldo antes', moneyFormat(_asDouble(credito['saldoAntes']))),
    ('Saldo despues', moneyFormat(_asDouble(credito['saldoDespues']))),
    (
      'Cuotas pagadas',
      '${aplicacion['cuotasPagadasTexto'] ?? aplicacion['cuotasPagadasDecimal'] ?? '-'}'
    ),
    ('Cuotas pendientes', '${aplicacion['cuotasPendientes'] ?? '-'}'),
  ];
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
