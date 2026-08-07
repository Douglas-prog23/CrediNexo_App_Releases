import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/represtamos_api.dart';
import '../data/represtamos_models.dart';

class ReprestamoFormPage extends StatefulWidget {
  const ReprestamoFormPage({super.key, required this.creditoId});

  final int creditoId;

  @override
  State<ReprestamoFormPage> createState() => _ReprestamoFormPageState();
}

class _ReprestamoFormPageState extends State<ReprestamoFormPage> {
  final _api = ReprestamosApi();
  late Future<ReprestamoContexto> _future;

  bool _initialized = false;
  bool _solicitaAumento = false;
  late final TextEditingController _montoController;
  late final TextEditingController _cuotasController;
  late final TextEditingController _tasaController;
  late final TextEditingController _formaPagoController;
  late final TextEditingController _fechaController;
  late final TextEditingController _comentarioController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _api.contextoCredito(widget.creditoId);
    _montoController = TextEditingController();
    _cuotasController = TextEditingController();
    _tasaController = TextEditingController();
    _formaPagoController = TextEditingController();
    _fechaController = TextEditingController();
    _comentarioController = TextEditingController();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _cuotasController.dispose();
    _tasaController.dispose();
    _formaPagoController.dispose();
    _fechaController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  void _initForm(ReprestamoContexto contexto) {
    if (_initialized) return;
    final defaults = contexto.defaultsNuevoPrestamo;
    _solicitaAumento = defaults.solicitaAumento;
    _montoController.text = defaults.montoNuevoSolicitado.toStringAsFixed(2);
    _cuotasController.text = '${defaults.numeroCuotas}';
    _tasaController.text = defaults.tasaRetorno.toStringAsFixed(2);
    _formaPagoController.text = defaults.formaPago ?? '';
    _fechaController.text = defaults.fechaDesembolso ?? '';
    _initialized = true;
  }

  void _reload() {
    setState(() {
      _initialized = false;
      _future = _api.contextoCredito(widget.creditoId);
    });
  }

  double _number(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  int _int(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  bool _isDateInputValue(String value) {
    final parts = value.split('-');
    if (parts.length != 3 ||
        parts[0].length != 4 ||
        parts[1].length != 2 ||
        parts[2].length != 2) {
      return false;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;
    final parsed = DateTime.tryParse(value);
    return parsed != null &&
        parsed.year == year &&
        parsed.month == month &&
        parsed.day == day;
  }

  _Estimado _estimado(ReprestamoContexto contexto) {
    final monto = _number(_montoController);
    final cuotas = _int(_cuotasController);
    final tasa = _number(_tasaController);
    final saldo = contexto.resumen.saldoRefinanciar;
    final valorFuturo = monto + (monto * tasa / 100);
    return _Estimado(
      liquido: monto - saldo,
      valorFuturo: valorFuturo,
      nuevaCuota: cuotas > 0 ? valorFuturo / cuotas : 0,
      fechaVencimiento: contexto.defaultsNuevoPrestamo.fechaVencimiento ?? '-',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit(ReprestamoContexto contexto) async {
    if (_saving) return;

    final monto = _number(_montoController);
    final numeroCuotas = _int(_cuotasController);
    final tasaRetorno = _number(_tasaController);
    final formaPago = _formaPagoController.text.trim();
    final fechaDesembolso = _fechaController.text.trim();
    final saldoRefinanciar = contexto.resumen.saldoRefinanciar;

    if (numeroCuotas <= 0) {
      _showMessage('Numero de cuotas debe ser mayor a 0.');
      return;
    }
    if (tasaRetorno < 0) {
      _showMessage('Tasa retorno debe ser mayor o igual a 0.');
      return;
    }
    if (formaPago.isEmpty) {
      _showMessage('Forma de pago es obligatoria.');
      return;
    }
    if (!_isDateInputValue(fechaDesembolso)) {
      _showMessage('Fecha de desembolso invalida.');
      return;
    }
    if (_solicitaAumento && monto <= saldoRefinanciar) {
      _showMessage(
        'Para solicitar aumento, el monto nuevo debe ser mayor al saldo a refinanciar.',
      );
      return;
    }
    if (monto - saldoRefinanciar < 0) {
      _showMessage('Liquido a entregar no puede ser negativo.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.crearSolicitudMobile(
        CrearSolicitudReprestamoMobileRequest(
          creditoOrigenId: contexto.credito.creditoOrigenId,
          solicitaAumento: _solicitaAumento,
          montoNuevoSolicitado: monto,
          numeroCuotas: numeroCuotas,
          tasaRetorno: tasaRetorno,
          formaPago: formaPago,
          fechaDesembolso: fechaDesembolso,
          comentario: _comentarioController.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Ocurrio un error al crear la solicitud.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final actual =
        DateTime.tryParse(_fechaController.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    final value =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() => _fechaController.text = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud de re-prestamo'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<ReprestamoContexto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(
                message: 'Cargando contexto del credito...');
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'No se pudo cargar el contexto del re-prestamo.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final contexto = snapshot.data!;
          _initForm(contexto);
          final estimado = _estimado(contexto);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                title: 'Credito origen',
                children: [
                  _InfoRow('Cliente', contexto.credito.nombreCliente ?? '-'),
                  _InfoRow(
                      'Codigo cliente', contexto.credito.codigoClienteVisual),
                  _InfoRow('Referencia', contexto.credito.referenciaVisual),
                  _InfoRow('Monto original',
                      moneyFormat(contexto.credito.montoOtorgadoPrestamo)),
                  _InfoRow(
                      'Estado', contexto.credito.estadoCreditoOrigen ?? '-'),
                  _InfoRow(
                      'Forma pago', contexto.credito.formaPagoOrigen ?? '-'),
                  _InfoRow('Cartera', contexto.credito.carteraNombre ?? '-'),
                  _InfoRow('Gestor', contexto.credito.gestorNombre ?? '-'),
                ],
              ),
              _SectionCard(
                title: 'Condicion de re-prestamo',
                trailing: const _DisponibleBadge(),
                children: [
                  _InfoRow('Total pagado',
                      moneyFormat(contexto.elegibilidad.totalPagado)),
                  _InfoRow('Interes total',
                      moneyFormat(contexto.elegibilidad.interesTotal)),
                  _InfoRow('Capital requerido',
                      moneyFormat(contexto.elegibilidad.capitalRequerido)),
                  _InfoRow('Minimo requerido',
                      moneyFormat(contexto.elegibilidad.montoMinimoRequerido)),
                  _InfoRow(
                    'Cuotas',
                    '${contexto.resumen.cuotasPagadas} pagadas / ${contexto.resumen.cuotasPendientes} pendientes',
                  ),
                  _InfoRow('Dias mora', '${contexto.resumen.diasMora}'),
                ],
              ),
              _SectionCard(
                title: 'Nuevo prestamo',
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _solicitaAumento,
                    title: const Text('Solicita aumento'),
                    subtitle: const Text(
                        'Activa esta opcion para editar el monto solicitado.'),
                    onChanged: (value) =>
                        setState(() => _solicitaAumento = value),
                  ),
                  _TextField(
                    controller: _montoController,
                    label: 'Monto nuevo solicitado',
                    keyboardType: TextInputType.number,
                    readOnly: !_solicitaAumento,
                    onChanged: (_) => setState(() {}),
                  ),
                  _TextField(
                    controller: _cuotasController,
                    label: 'Numero de cuotas',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  _TextField(
                    controller: _tasaController,
                    label: 'Tasa retorno',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  _TextField(
                    controller: _formaPagoController,
                    label: 'Forma de pago',
                    onChanged: (_) => setState(() {}),
                  ),
                  _TextField(
                    controller: _fechaController,
                    label: 'Fecha posible desembolso',
                    readOnly: true,
                    suffixIcon: Icons.calendar_month_rounded,
                    onTap: _seleccionarFecha,
                  ),
                  _TextField(
                    controller: _comentarioController,
                    label: 'Comentario opcional',
                    maxLines: 3,
                  ),
                ],
              ),
              _SectionCard(
                title: 'Resumen estimado',
                children: [
                  _InfoRow('Saldo a refinanciar',
                      moneyFormat(contexto.resumen.saldoRefinanciar)),
                  _InfoRow('Liquido a entregar', moneyFormat(estimado.liquido)),
                  _InfoRow(
                      'Nueva cuota estimada', moneyFormat(estimado.nuevaCuota)),
                  _InfoRow('Valor futuro estimado',
                      moneyFormat(estimado.valorFuturo)),
                  _InfoRow(
                      'Fecha vencimiento estimada', estimado.fechaVencimiento),
                  const SizedBox(height: 8),
                  const Text(
                    'Estimacion preliminar. La solicitud final sera validada por el sistema.',
                    style: TextStyle(
                        color: Colors.blueGrey, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              AppButton(
                label: 'Solicitar re-prestamo',
                icon: Icons.send_rounded,
                loading: _saving,
                onPressed: () => _submit(contexto),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Estimado {
  const _Estimado({
    required this.liquido,
    required this.valorFuturo,
    required this.nuevaCuota,
    required this.fechaVencimiento,
  });

  final double liquido;
  final double valorFuturo;
  final double nuevaCuota;
  final String fechaVencimiento;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.blueGrey, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.readOnly = false,
    this.maxLines = 1,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool readOnly;
  final int maxLines;
  final IconData? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
        ),
      ),
    );
  }
}

class _DisponibleBadge extends StatelessWidget {
  const _DisponibleBadge();

  @override
  Widget build(BuildContext context) {
    final color = Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Disponible',
        style:
            TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}
