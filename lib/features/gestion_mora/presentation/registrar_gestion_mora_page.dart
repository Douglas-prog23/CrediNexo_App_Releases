import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/gestion_mora_api.dart';
import '../data/gestion_mora_models.dart';

class RegistrarGestionMoraPage extends StatefulWidget {
  const RegistrarGestionMoraPage({super.key, required this.credito});

  final CreditoMora credito;

  @override
  State<RegistrarGestionMoraPage> createState() =>
      _RegistrarGestionMoraPageState();
}

class _RegistrarGestionMoraPageState extends State<RegistrarGestionMoraPage> {
  final _api = GestionMoraApi();
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  final _montoController = TextEditingController();
  String _tipoGestion = 'LLAMADA';
  String _resultado = 'CONTACTADO';
  String? _fechaCompromiso;
  String? _proximaGestion;
  bool _saving = false;

  static const _tipos = [
    _Option('LLAMADA', 'Llamada'),
    _Option('VISITA', 'Visita'),
    _Option('MENSAJE', 'Mensaje'),
    _Option('WHATSAPP', 'WhatsApp'),
    _Option('OTRO', 'Otro'),
  ];

  static const _resultados = [
    _Option('CONTACTADO', 'Contactado'),
    _Option('NO_CONTACTADO', 'No contactado'),
    _Option('PROMESA_PAGO', 'Promesa de pago'),
    _Option('PAGO_REALIZADO', 'Pago realizado'),
    _Option('REPROGRAMAR', 'Reprogramar'),
    _Option('SIN_RESPUESTA', 'Sin respuesta'),
    _Option('OTRO', 'Otro'),
  ];

  @override
  void dispose() {
    _comentarioController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required String? current,
    required ValueChanged<String?> onChanged,
  }) async {
    final initial = current == null ? DateTime.now() : DateTime.parse(current);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) onChanged(_toLocalDateInputValue(selected));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final montoText = _montoController.text.trim();
      await _api.registrarGestion(
        creditoId: widget.credito.creditoId,
        request: CrearGestionMoraRequest(
          tipoGestion: _tipoGestion,
          resultado: _resultado,
          comentario: _comentarioController.text,
          fechaCompromiso: _fechaCompromiso,
          montoCompromiso:
              montoText.isEmpty ? null : double.tryParse(montoText),
          proximaGestion: _proximaGestion,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gestion registrada correctamente.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.isForbidden) {
        return 'No tiene permiso para registrar gestiones.';
      }
      if (error.isUnauthorized) {
        return 'Sesion expirada o no autorizada. Inicie sesion nuevamente.';
      }
      return error.message;
    }
    return 'Ocurrio un error al registrar la gestion.';
  }

  String? _validateComentario(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingrese un comentario.';
    if (text.length < 3) {
      return 'El comentario debe tener al menos 3 caracteres.';
    }
    return null;
  }

  String? _validateMonto(String? value) {
    final text = value?.trim() ?? '';
    if (_resultado == 'PROMESA_PAGO' && text.isEmpty) {
      return 'Ingrese el monto de compromiso.';
    }
    if (text.isEmpty) return null;
    final amount = double.tryParse(text);
    if (amount == null) return 'Ingrese un monto valido.';
    if (amount < 0) return 'El monto no puede ser negativo.';
    if (_resultado == 'PROMESA_PAGO' && amount <= 0) {
      return 'El monto debe ser mayor a 0.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isPromesa = _resultado == 'PROMESA_PAGO';
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar gestion')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _ResumenCredito(credito: widget.credito),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _tipoGestion,
                      decoration:
                          const InputDecoration(labelText: 'Tipo de gestion'),
                      items: _tipos
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _tipoGestion = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _resultado,
                      decoration: const InputDecoration(labelText: 'Resultado'),
                      items: _resultados
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _resultado = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _comentarioController,
                      minLines: 4,
                      maxLines: 6,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Comentario',
                        alignLabelWithHint: true,
                        hintText: 'Detalle la gestion realizada...',
                      ),
                      validator: _validateComentario,
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label:
                          isPromesa ? 'Fecha compromiso *' : 'Fecha compromiso',
                      value: _fechaCompromiso,
                      enabled: !_saving,
                      errorText: isPromesa && _fechaCompromiso == null
                          ? 'Requerida para promesa de pago'
                          : null,
                      onPick: () => _pickDate(
                        current: _fechaCompromiso,
                        onChanged: (value) =>
                            setState(() => _fechaCompromiso = value),
                      ),
                      onClear: _fechaCompromiso == null || _saving
                          ? null
                          : () => setState(() => _fechaCompromiso = null),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _montoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: !_saving,
                      decoration: InputDecoration(
                        labelText: isPromesa
                            ? 'Monto compromiso *'
                            : 'Monto compromiso',
                        prefixText: r'$ ',
                      ),
                      validator: _validateMonto,
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: 'Proxima gestion',
                      value: _proximaGestion,
                      enabled: !_saving,
                      onPick: () => _pickDate(
                        current: _proximaGestion,
                        onChanged: (value) =>
                            setState(() => _proximaGestion = value),
                      ),
                      onClear: _proximaGestion == null || _saving
                          ? null
                          : () => setState(() => _proximaGestion = null),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Guardar gestion',
                        icon: Icons.save_outlined,
                        loading: _saving,
                        onPressed: _saving
                            ? null
                            : () {
                                if (isPromesa && _fechaCompromiso == null) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'La promesa de pago requiere fecha compromiso.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _guardar();
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenCredito extends StatelessWidget {
  const _ResumenCredito({required this.credito});

  final CreditoMora credito;

  @override
  Widget build(BuildContext context) {
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
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              credito.cliente.isEmpty ? 'Cliente sin nombre' : credito.cliente,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              runSpacing: 8,
              spacing: 12,
              children: [
                _Info(label: 'Dias mora', value: '${credito.diasMora}'),
                _Info(
                  label: 'Cuotas vencidas',
                  value: '${credito.cuotasVencidas}',
                ),
                _Info(
                  label: 'Saldo pendiente',
                  value: moneyFormat(credito.saldoPendiente),
                ),
                if ((credito.telefonoCliente ?? '').isNotEmpty)
                  _Info(label: 'Telefono', value: credito.telefonoCliente!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
    this.onClear,
    this.errorText,
  });

  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, errorText: errorText),
      child: Row(
        children: [
          Expanded(child: Text(value ?? '-')),
          IconButton(
            tooltip: 'Seleccionar fecha',
            onPressed: enabled ? onPick : null,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Limpiar fecha',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
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
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Option {
  const _Option(this.value, this.label);

  final String value;
  final String label;
}

String _toLocalDateInputValue(DateTime date) {
  final year = date.year;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
