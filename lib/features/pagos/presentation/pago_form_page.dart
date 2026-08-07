import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/pagos_api.dart';
import '../data/pagos_models.dart';
import 'comprobante_printing.dart';

class PagoFormPage extends StatefulWidget {
  const PagoFormPage({super.key, required this.contexto});

  final PagoContexto contexto;

  @override
  State<PagoFormPage> createState() => _PagoFormPageState();
}

class _PagoFormPageState extends State<PagoFormPage> {
  final _api = PagosApi();
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _montoRecibidoController = TextEditingController();
  final _observacionController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _fechaTransferenciaController =
      TextEditingController(text: todayLocalIso());

  String _medioPago = 'EFECTIVO';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final sugerido = widget.contexto.cuotasPendientes.isNotEmpty
        ? widget.contexto.cuotasPendientes.first.saldoCuota
        : widget.contexto.resumen.saldoPendiente;
    _montoController.text = sugerido > 0 ? sugerido.toStringAsFixed(2) : '';
    _montoRecibidoController.text = _montoController.text;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _montoRecibidoController.dispose();
    _observacionController.dispose();
    _referenciaController.dispose();
    _fechaTransferenciaController.dispose();
    super.dispose();
  }

  double get _monto =>
      double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;
  double get _recibido =>
      double.tryParse(_montoRecibidoController.text.replaceAll(',', '.')) ?? 0;
  double get _vuelto => _medioPago == 'EFECTIVO'
      ? (_recibido - _monto).clamp(0, double.infinity).toDouble()
      : 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final pago = await _api.registrarPago(
        creditoId: widget.contexto.credito.id,
        monto: _monto,
        medioPago: _medioPago,
        montoRecibido: _medioPago == 'EFECTIVO' ? _recibido : null,
        vuelto: _medioPago == 'EFECTIVO' ? _vuelto : null,
        observacion: _observacionController.text,
        numeroReferencia:
            _medioPago == 'TRANSFERENCIA' ? _referenciaController.text : null,
        fechaTransferencia: _medioPago == 'TRANSFERENCIA'
            ? _fechaTransferenciaController.text
            : null,
      );
      if (!mounted) return;
      await _showPagoRegistradoDialog(pago);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(
          () => _error = 'No se pudo registrar el pago. Intente nuevamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showPagoRegistradoDialog(PagoRegistrado pago) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var printing = false;
        String? printError;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> printTicket() async {
              setDialogState(() {
                printing = true;
                printError = null;
              });
              try {
                final comprobante = await _api.renderComprobante(pago.id);
                await printComprobanteRender(comprobante, pagoId: pago.id);
              } on ApiException catch (error) {
                printError = error.message;
              } catch (_) {
                printError =
                    'No se pudo imprimir el comprobante. Intente nuevamente.';
              } finally {
                if (context.mounted) {
                  setDialogState(() => printing = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Pago registrado correctamente.'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comprobante #${pago.id} listo para imprimir.'),
                  if (printError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      printError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      printing ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Finalizar'),
                ),
                FilledButton.icon(
                  onPressed: printing ? null : printTicket,
                  icon: printing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_rounded),
                  label: const Text('Imprimir comprobante'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final credito = widget.contexto.credito;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(credito.referenciaVisual,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(credito.cliente.nombreCompleto),
                    const SizedBox(height: 8),
                    Text(
                        'Saldo pendiente: ${moneyFormat(widget.contexto.resumen.saldoPendiente)}'),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Text(_error!, style: TextStyle(color: Colors.red.shade800)),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto a pagar'),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final amount =
                    double.tryParse((value ?? '').replaceAll(',', '.')) ?? 0;
                if (amount <= 0) {
                  return 'Ingrese un monto mayor a 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _medioPago,
              decoration: const InputDecoration(labelText: 'Medio de pago'),
              items: const [
                DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                DropdownMenuItem(
                    value: 'TRANSFERENCIA', child: Text('Transferencia')),
              ],
              onChanged: (value) =>
                  setState(() => _medioPago = value ?? 'EFECTIVO'),
            ),
            const SizedBox(height: 12),
            if (_medioPago == 'EFECTIVO') ...[
              TextFormField(
                controller: _montoRecibidoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto recibido'),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final received =
                      double.tryParse((value ?? '').replaceAll(',', '.')) ?? 0;
                  if (received < _monto) {
                    return 'El recibido debe ser mayor o igual al pago.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _ReadOnlyValue(label: 'Vuelto', value: moneyFormat(_vuelto)),
            ] else ...[
              TextFormField(
                controller: _referenciaController,
                decoration: const InputDecoration(
                    labelText: 'Referencia de transferencia'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaTransferenciaController,
                decoration: const InputDecoration(
                    labelText: 'Fecha de transferencia',
                    hintText: 'YYYY-MM-DD'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observacion'),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Guardar pago',
              icon: Icons.save_rounded,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
