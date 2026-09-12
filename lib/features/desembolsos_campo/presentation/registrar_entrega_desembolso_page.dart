import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/desembolsos_campo_api.dart';
import '../data/desembolsos_campo_models.dart';

class RegistrarEntregaDesembolsoPage extends StatefulWidget {
  const RegistrarEntregaDesembolsoPage({super.key, required this.item});

  final DesembolsoCampoDisponible item;

  @override
  State<RegistrarEntregaDesembolsoPage> createState() =>
      _RegistrarEntregaDesembolsoPageState();
}

class _RegistrarEntregaDesembolsoPageState
    extends State<RegistrarEntregaDesembolsoPage> {
  final _api = DesembolsosCampoApi();
  final _observacionController = TextEditingController();
  late String _fechaEntrega;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fechaEntrega = _todayLocalISO();
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_fechaEntrega) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _fechaEntrega = _toLocalDateInputValue(picked));
    }
  }

  Future<void> _guardar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: const Text(
          'Esta accion solo registra que entregaste el dinero al cliente. Caja debe aplicar el desembolso oficialmente para crear el credito.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await _api.marcarEntregado(
        item: widget.item,
        request: MarcarEntregaDesembolsoRequest(
          fechaEntregaCampo: _fechaEntrega,
          observacionEntregaCampo: _observacionController.text,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : 'No se pudo registrar la entrega.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final duiMasked = item.duiMasked ?? '';
    final telefono = item.telefono ?? '';
    final direccion = item.direccion ?? '';
    final responsable = item.responsableEntregaCampoNombre ?? '';
    final creditoOrigen = item.referenciaCreditoOrigen ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Marcar entrega')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.clienteVisual.isEmpty
                        ? 'Cliente sin nombre'
                        : item.clienteVisual,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  _Info(label: 'Tipo', value: item.tipoLabel),
                  _Info(label: 'Solicitud', value: item.identificadorVisual),
                  _Info(
                      label: 'Codigo cliente', value: item.codigoClienteVisual),
                  if (duiMasked.isNotEmpty)
                    _Info(label: 'DUI', value: duiMasked),
                  if (telefono.isNotEmpty)
                    _Info(label: 'Telefono', value: telefono),
                  if (direccion.isNotEmpty)
                    _Info(label: 'Direccion', value: direccion),
                  if (responsable.isNotEmpty)
                    _Info(label: 'Responsable', value: responsable),
                  if (item.esReprestamo && creditoOrigen.isNotEmpty)
                    _Info(label: 'Credito origen', value: creditoOrigen),
                  const Divider(height: 24),
                  _Info(
                      label: 'Monto a desembolsar',
                      value: moneyFormat(item.montoADesembolsar)),
                  _Info(
                      label: 'Liquido a entregar',
                      value: moneyFormat(item.liquidoAEntregar)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Text(
              'Esta accion solo registra que entregaste el dinero al cliente. Caja debe aplicar el desembolso oficialmente para crear el credito.',
              style: TextStyle(
                  color: Color(0xFF9A3412), fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha entrega'),
            subtitle: Text(_fechaEntrega),
            trailing: IconButton(
              tooltip: 'Seleccionar fecha',
              onPressed: _saving ? null : _pickDate,
              icon: const Icon(Icons.calendar_month_rounded),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _observacionController,
            minLines: 3,
            maxLines: 5,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'Observacion',
              hintText: 'Ejemplo: Entregado en domicilio del cliente',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: _saving ? 'Guardando...' : 'Confirmar entrega',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _saving ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
              child: Text(value.isEmpty ? '-' : value,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

String _todayLocalISO() => _toLocalDateInputValue(DateTime.now());

String _toLocalDateInputValue(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
