import 'package:flutter/material.dart';

import '../../core/utils/date_format.dart';
import '../../core/utils/money_format.dart';
import 'calculadora_cuotas_utils.dart';

class CalculadoraCuotasPage extends StatefulWidget {
  const CalculadoraCuotasPage({super.key});

  @override
  State<CalculadoraCuotasPage> createState() => _CalculadoraCuotasPageState();
}

class _CalculadoraCuotasPageState extends State<CalculadoraCuotasPage> {
  final _montoController = TextEditingController();
  final _tasaController = TextEditingController();
  final _cuotasController = TextEditingController();

  String _frecuencia = frecuenciaDiario;
  DateTime _fechaBase = DateTime.now();
  CuotaCalculada? _resultado;
  String? _mensajeValidacion;

  @override
  void initState() {
    super.initState();
    _montoController.addListener(_calcularSilencioso);
    _tasaController.addListener(_calcularSilencioso);
    _cuotasController.addListener(_calcularSilencioso);
  }

  @override
  void dispose() {
    _montoController.dispose();
    _tasaController.dispose();
    _cuotasController.dispose();
    super.dispose();
  }

  void _calcularSilencioso() => _calcular(mostrarErrores: false);

  void _calcular({required bool mostrarErrores}) {
    final monto = parseMontoCalculadora(_montoController.text);
    final tasa = parseMontoCalculadora(_tasaController.text);
    final cuotas = parseCuotasCalculadora(_cuotasController.text);
    final resultado = calcularCuotaEstimada(
      monto: monto,
      tasaRetorno: tasa,
      numeroCuotas: cuotas,
      frecuencia: _frecuencia,
      fechaBase: _fechaBase,
    );

    setState(() {
      _resultado = resultado;
      _mensajeValidacion = mostrarErrores && resultado == null
          ? 'Ingresa monto mayor a 0, tasa mayor o igual a 0 y cuotas mayor a 0.'
          : null;
    });
  }

  void _limpiar() {
    _montoController.removeListener(_calcularSilencioso);
    _tasaController.removeListener(_calcularSilencioso);
    _cuotasController.removeListener(_calcularSilencioso);
    _montoController.clear();
    _tasaController.clear();
    _cuotasController.clear();
    _montoController.addListener(_calcularSilencioso);
    _tasaController.addListener(_calcularSilencioso);
    _cuotasController.addListener(_calcularSilencioso);
    setState(() {
      _frecuencia = frecuenciaDiario;
      _fechaBase = DateTime.now();
      _resultado = null;
      _mensajeValidacion = null;
    });
  }

  Future<void> _seleccionarFecha() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaBase,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() => _fechaBase = selected);
    _calcular(mostrarErrores: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de Cuotas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Simula una cuota estimada sin guardar datos.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF3C4B5F),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MoneyField(
                    controller: _montoController,
                    label: 'Monto solicitado',
                  ),
                  const SizedBox(height: 12),
                  _MoneyField(
                    controller: _tasaController,
                    label: 'Tasa de retorno (%)',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cuotasController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Numero de cuotas',
                      prefixIcon: Icon(Icons.format_list_numbered_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_frecuencia),
                    initialValue: _frecuencia,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia',
                      prefixIcon: Icon(Icons.event_repeat_rounded),
                    ),
                    items: frecuenciasCalculadoraCuotas
                        .map(
                          (frecuencia) => DropdownMenuItem(
                            value: frecuencia,
                            child: Text(frecuencia),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _frecuencia = value);
                      _calcular(mostrarErrores: false);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _seleccionarFecha,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text('Fecha base: ${dateFormat(_fechaBase)}'),
                  ),
                  if (_mensajeValidacion != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _mensajeValidacion!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _calcular(mostrarErrores: true),
                          icon: const Icon(Icons.calculate_rounded),
                          label: const Text('Calcular'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _limpiar,
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ResultadoCard(resultado: _resultado),
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.attach_money_rounded),
      ),
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  const _ResultadoCard({required this.resultado});

  final CuotaCalculada? resultado;

  @override
  Widget build(BuildContext context) {
    final data = resultado;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE7F0FF),
                  child: Icon(Icons.receipt_long_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Resultado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ResultLine(
              label: 'Valor cuota',
              value: data == null ? r'$0.00' : moneyFormat(data.valorCuota),
              destacado: true,
            ),
            _ResultLine(
              label: 'Interes',
              value: data == null ? r'$0.00' : moneyFormat(data.interes),
            ),
            _ResultLine(
              label: 'Total a pagar',
              value: data == null ? r'$0.00' : moneyFormat(data.totalAPagar),
            ),
            _ResultLine(
              label: 'Dias equivalentes',
              value: data == null ? '-' : '${data.diasEquivalentes}',
            ),
            _ResultLine(
              label: 'Fecha vencimiento',
              value: data == null ? '-' : dateFormat(data.fechaVencimiento),
            ),
            if (data?.muestraNotaAsuetos ?? false) ...[
              const SizedBox(height: 10),
              const Text(
                'Fecha estimada. No incluye asuetos oficiales.',
                style: TextStyle(
                  color: Color(0xFF5D6B7C),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.label,
    required this.value,
    this.destacado = false,
  });

  final String label;
  final String value;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final valueStyle = destacado
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF153462),
              fontWeight: FontWeight.w900,
            )
        : const TextStyle(fontWeight: FontWeight.w800);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF5D6B7C)),
            ),
          ),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
