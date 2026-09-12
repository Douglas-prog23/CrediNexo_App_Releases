class CreditoReprestamoDisponible {
  const CreditoReprestamoDisponible({
    required this.creditoId,
    required this.referenciaCredito,
    required this.numeroPrestamo,
    required this.codigoCliente,
    required this.cliente,
    required this.clienteNombreCompleto,
    required this.dui,
    required this.monto,
    required this.tipo,
    required this.saldoCapital,
    required this.totalPagado,
    required this.interesTotal,
    required this.capitalRequerido,
    required this.montoMinimoRequerido,
    required this.cuotasPagadas,
    required this.cuotasPendientes,
    required this.diasMora,
    required this.porcentaje,
    required this.cuotaPrestamo,
    required this.valorFuturoPrestamo,
    required this.carteraNombre,
    required this.gestorNombre,
    required this.aplicaReprestamo,
    required this.aplicaAutomaticamente,
    required this.habilitadoReprestamoEspecial,
    required this.habilitadoReprestamoMotivo,
    required this.habilitadoReprestamoFecha,
    required this.habilitadoReprestamoPorNombre,
    required this.motivoNoAplica,
  });

  final int creditoId;
  final String? referenciaCredito;
  final String? numeroPrestamo;
  final String? codigoCliente;
  final String cliente;
  final String clienteNombreCompleto;
  final String? dui;
  final double monto;
  final String? tipo;
  final double saldoCapital;
  final double totalPagado;
  final double interesTotal;
  final double capitalRequerido;
  final double montoMinimoRequerido;
  final int cuotasPagadas;
  final int cuotasPendientes;
  final int diasMora;
  final double porcentaje;
  final double cuotaPrestamo;
  final double valorFuturoPrestamo;
  final String? carteraNombre;
  final String? gestorNombre;
  final bool aplicaReprestamo;
  final bool aplicaAutomaticamente;
  final bool habilitadoReprestamoEspecial;
  final String? habilitadoReprestamoMotivo;
  final String? habilitadoReprestamoFecha;
  final String? habilitadoReprestamoPorNombre;
  final String? motivoNoAplica;

  bool get seleccionable => aplicaReprestamo || habilitadoReprestamoEspecial;

  bool get esHabilitadoEspecial =>
      habilitadoReprestamoEspecial && !aplicaAutomaticamente;

  String get clienteVisual {
    final completo = clienteNombreCompleto.trim();
    if (completo.isNotEmpty) return completo;
    final actual = cliente.trim();
    return actual.isNotEmpty ? actual : 'Cliente sin nombre';
  }

  String get referenciaVisual {
    final ref = referenciaCredito?.trim();
    if (ref != null && ref.isNotEmpty) return ref;
    final numero = numeroPrestamo?.trim();
    if (numero != null && numero.isNotEmpty) return numero;
    return 'CR-${creditoId.toString().padLeft(6, '0')}';
  }

  String get codigoClienteVisual {
    final codigo = codigoCliente?.trim();
    return codigo != null && codigo.isNotEmpty ? codigo : '-';
  }

  String get tipoVisual {
    final value = tipo?.trim();
    return value != null && value.isNotEmpty ? value : '-';
  }

  factory CreditoReprestamoDisponible.fromJson(Map<String, dynamic> json) {
    final habilitadoEspecial =
        _asBool(json['habilitadoReprestamoEspecial']) ?? false;
    final aplicaAutomaticamente = _asBool(json['aplicaAutomaticamente']) ??
        _asBool(json['aplica']) ??
        false;
    final tieneElegibilidad = json.containsKey('aplicaReprestamo') ||
        json.containsKey('aplica') ||
        json.containsKey('aplicaAutomaticamente') ||
        json.containsKey('habilitadoReprestamoEspecial');
    final aplicaReprestamo = (_asBool(json['aplicaReprestamo']) ??
            (tieneElegibilidad ? false : true)) ||
        habilitadoEspecial;
    return CreditoReprestamoDisponible(
      creditoId: _asInt(json['creditoId']) ?? _asInt(json['id']) ?? 0,
      referenciaCredito: _nullableString(json['referenciaCredito']),
      numeroPrestamo: _nullableString(json['numeroPrestamo']),
      codigoCliente: _nullableString(json['codigoCliente']),
      cliente: _clienteTexto(json),
      clienteNombreCompleto: _nombreCompletoCliente(json),
      dui: _nullableString(json['dui']),
      monto: _asDouble(json['monto']),
      tipo: _firstNonEmpty([
        json['tipo'],
        json['tipoCredito'],
        json['frecuenciaPago'],
        json['modalidad'],
        json['periodicidad'],
      ]),
      saldoCapital: _asDouble(json['saldoCapital']),
      totalPagado: _asDouble(json['totalPagado']),
      interesTotal: _asDouble(json['interesTotal']),
      capitalRequerido: _asDouble(json['capitalRequerido']),
      montoMinimoRequerido: _asDouble(json['montoMinimoRequerido']),
      cuotasPagadas: _asInt(json['cuotasPagadas']) ?? 0,
      cuotasPendientes: _asInt(json['cuotasPendientes']) ?? 0,
      diasMora: _asInt(json['diasMora']) ?? 0,
      porcentaje: _asDouble(json['porcentaje']),
      cuotaPrestamo: _asDouble(json['cuotaPrestamo']),
      valorFuturoPrestamo: _asDouble(json['valorFuturoPrestamo']),
      carteraNombre: _nullableString(json['carteraNombre']),
      gestorNombre: _nullableString(json['gestorNombre']),
      aplicaReprestamo: aplicaReprestamo,
      aplicaAutomaticamente: aplicaAutomaticamente,
      habilitadoReprestamoEspecial: habilitadoEspecial,
      habilitadoReprestamoMotivo:
          _nullableString(json['habilitadoReprestamoMotivo']),
      habilitadoReprestamoFecha:
          _nullableString(json['habilitadoReprestamoFecha']),
      habilitadoReprestamoPorNombre:
          _nullableString(json['habilitadoReprestamoPorNombre']),
      motivoNoAplica: _nullableString(json['motivoNoAplica']) ??
          _nullableString(json['motivo']),
    );
  }
}

class ReprestamosDisponiblesPage {
  const ReprestamosDisponiblesPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<CreditoReprestamoDisponible> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory ReprestamosDisponiblesPage.fromJson(
    dynamic json, {
    int fallbackPage = 1,
    int fallbackLimit = 10,
  }) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rows = (map['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CreditoReprestamoDisponible.fromJson)
        .toList();
    return ReprestamosDisponiblesPage(
      data: rows,
      total: _asInt(map['total']) ?? rows.length,
      page: _asInt(map['page']) ?? fallbackPage,
      limit: _asInt(map['limit']) ?? fallbackLimit,
      totalPages: _asInt(map['totalPages']) ?? 1,
    );
  }
}

class ReprestamoContexto {
  const ReprestamoContexto({
    required this.credito,
    required this.resumen,
    required this.elegibilidad,
    required this.defaultsNuevoPrestamo,
    required this.calculosIniciales,
    required this.tecnicoPromotor,
  });

  final ReprestamoCreditoContexto credito;
  final ReprestamoResumenContexto resumen;
  final ReprestamoElegibilidadContexto elegibilidad;
  final ReprestamoDefaultsNuevoPrestamo defaultsNuevoPrestamo;
  final ReprestamoCalculosIniciales calculosIniciales;
  final ReprestamoTecnicoPromotor? tecnicoPromotor;

  factory ReprestamoContexto.fromJson(Map<String, dynamic> json) {
    final creditoJson =
        json['credito'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final clienteJson =
        json['cliente'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final creditoConCliente = <String, dynamic>{
      ...creditoJson,
      if (_nombreCompletoCliente(clienteJson).trim().isNotEmpty)
        'nombreCliente': _nombreCompletoCliente(clienteJson),
    };
    return ReprestamoContexto(
      credito: ReprestamoCreditoContexto.fromJson(creditoConCliente),
      resumen: ReprestamoResumenContexto.fromJson(
        json['resumen'] as Map<String, dynamic>? ?? const {},
      ),
      elegibilidad: ReprestamoElegibilidadContexto.fromJson(
        json['elegibilidad'] as Map<String, dynamic>? ?? const {},
      ),
      defaultsNuevoPrestamo: ReprestamoDefaultsNuevoPrestamo.fromJson(
        json['defaultsNuevoPrestamo'] as Map<String, dynamic>? ?? const {},
      ),
      calculosIniciales: ReprestamoCalculosIniciales.fromJson(
        json['calculosIniciales'] as Map<String, dynamic>? ?? const {},
      ),
      tecnicoPromotor: json['tecnicoPromotor'] is Map<String, dynamic>
          ? ReprestamoTecnicoPromotor.fromJson(
              json['tecnicoPromotor'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ReprestamoCreditoContexto {
  const ReprestamoCreditoContexto({
    required this.creditoOrigenId,
    required this.referenciaCreditoOrigen,
    required this.numeroPrestamoOrigen,
    required this.nombreCliente,
    required this.numeroCliente,
    required this.dui,
    required this.lineaCreditoOrigen,
    required this.formaPagoOrigen,
    required this.montoOtorgadoPrestamo,
    required this.numeroCuotasOrigen,
    required this.tasaRetornoOrigen,
    required this.fechaDesembolsoOrigen,
    required this.fechaVencimientoOrigen,
    required this.estadoCreditoOrigen,
    required this.carteraNombre,
    required this.gestorNombre,
  });

  final int creditoOrigenId;
  final String? referenciaCreditoOrigen;
  final String? numeroPrestamoOrigen;
  final String? nombreCliente;
  final String? numeroCliente;
  final String? dui;
  final String? lineaCreditoOrigen;
  final String? formaPagoOrigen;
  final double montoOtorgadoPrestamo;
  final int numeroCuotasOrigen;
  final double tasaRetornoOrigen;
  final String? fechaDesembolsoOrigen;
  final String? fechaVencimientoOrigen;
  final String? estadoCreditoOrigen;
  final String? carteraNombre;
  final String? gestorNombre;

  String get referenciaVisual {
    final ref = referenciaCreditoOrigen?.trim();
    if (ref != null && ref.isNotEmpty) return ref;
    final numero = numeroPrestamoOrigen?.trim();
    if (numero != null && numero.isNotEmpty) return numero;
    return 'CR-${creditoOrigenId.toString().padLeft(6, '0')}';
  }

  String get codigoClienteVisual {
    final codigo = numeroCliente?.trim();
    return codigo != null && codigo.isNotEmpty ? codigo : '-';
  }

  factory ReprestamoCreditoContexto.fromJson(Map<String, dynamic> json) {
    return ReprestamoCreditoContexto(
      creditoOrigenId: _asInt(json['creditoOrigenId']) ?? 0,
      referenciaCreditoOrigen: _nullableString(json['referenciaCreditoOrigen']),
      numeroPrestamoOrigen: _nullableString(json['numeroPrestamoOrigen']),
      nombreCliente: _nullableString(json['nombreCliente']),
      numeroCliente: _nullableString(json['numeroCliente']),
      dui: _nullableString(json['dui']),
      lineaCreditoOrigen: _nullableString(json['lineaCreditoOrigen']),
      formaPagoOrigen: _nullableString(json['formaPagoOrigen']),
      montoOtorgadoPrestamo: _asDouble(json['montoOtorgadoPrestamo']),
      numeroCuotasOrigen: _asInt(json['numeroCuotasOrigen']) ?? 0,
      tasaRetornoOrigen: _asDouble(json['tasaRetornoOrigen']),
      fechaDesembolsoOrigen: _nullableString(json['fechaDesembolsoOrigen']),
      fechaVencimientoOrigen: _nullableString(json['fechaVencimientoOrigen']),
      estadoCreditoOrigen: _nullableString(json['estadoCreditoOrigen']),
      carteraNombre: _nullableString(json['carteraNombre']),
      gestorNombre: _nullableString(json['gestorNombre']),
    );
  }
}

class ReprestamoResumenContexto {
  const ReprestamoResumenContexto({
    required this.saldoCapital,
    required this.saldoRefinanciar,
    required this.cuotasPagadas,
    required this.cuotasPendientes,
    required this.diasMora,
    required this.porcentaje,
    required this.cuotaPrestamo,
    required this.valorFuturoPrestamo,
  });

  final double saldoCapital;
  final double saldoRefinanciar;
  final int cuotasPagadas;
  final int cuotasPendientes;
  final int diasMora;
  final double porcentaje;
  final double cuotaPrestamo;
  final double valorFuturoPrestamo;

  factory ReprestamoResumenContexto.fromJson(Map<String, dynamic> json) {
    return ReprestamoResumenContexto(
      saldoCapital: _asDouble(json['saldoCapital']),
      saldoRefinanciar: _asDouble(json['saldoRefinanciar']),
      cuotasPagadas: _asInt(json['cuotasPagadas']) ?? 0,
      cuotasPendientes: _asInt(json['cuotasPendientes']) ?? 0,
      diasMora: _asInt(json['diasMora']) ?? 0,
      porcentaje: _asDouble(json['porcentaje']),
      cuotaPrestamo: _asDouble(json['cuotaPrestamo']),
      valorFuturoPrestamo: _asDouble(json['valorFuturoPrestamo']),
    );
  }
}

class ReprestamoElegibilidadContexto {
  const ReprestamoElegibilidadContexto({
    required this.aplica,
    required this.aplicaAutomaticamente,
    required this.habilitadoReprestamoEspecial,
    required this.habilitadoReprestamoMotivo,
    required this.habilitadoReprestamoFecha,
    required this.habilitadoReprestamoPorNombre,
    required this.motivo,
    required this.totalPagado,
    required this.interesTotal,
    required this.capitalRequerido,
    required this.montoMinimoRequerido,
    required this.faltaParaAplicar,
  });

  final bool aplica;
  final bool aplicaAutomaticamente;
  final bool habilitadoReprestamoEspecial;
  final String? habilitadoReprestamoMotivo;
  final String? habilitadoReprestamoFecha;
  final String? habilitadoReprestamoPorNombre;
  final String? motivo;
  final double totalPagado;
  final double interesTotal;
  final double capitalRequerido;
  final double montoMinimoRequerido;
  final double faltaParaAplicar;

  bool get esHabilitadoEspecial =>
      habilitadoReprestamoEspecial && !aplicaAutomaticamente;

  factory ReprestamoElegibilidadContexto.fromJson(Map<String, dynamic> json) {
    final habilitadoEspecial =
        _asBool(json['habilitadoReprestamoEspecial']) ?? false;
    final aplicaAutomaticamente = _asBool(json['aplicaAutomaticamente']) ??
        (_asBool(json['aplica']) == true && !habilitadoEspecial);
    return ReprestamoElegibilidadContexto(
      aplica: (_asBool(json['aplica']) ?? false) || habilitadoEspecial,
      aplicaAutomaticamente: aplicaAutomaticamente,
      habilitadoReprestamoEspecial: habilitadoEspecial,
      habilitadoReprestamoMotivo:
          _nullableString(json['habilitadoReprestamoMotivo']),
      habilitadoReprestamoFecha:
          _nullableString(json['habilitadoReprestamoFecha']),
      habilitadoReprestamoPorNombre:
          _nullableString(json['habilitadoReprestamoPorNombre']),
      motivo: _nullableString(json['motivoNoAplica']) ??
          _nullableString(json['motivo']),
      totalPagado: _asDouble(json['totalPagado']),
      interesTotal: _asDouble(json['interesTotal']),
      capitalRequerido: _asDouble(json['capitalRequerido']),
      montoMinimoRequerido: _asDouble(json['montoMinimoRequerido']),
      faltaParaAplicar: _asDouble(json['faltaParaAplicar']),
    );
  }
}

class ReprestamoDefaultsNuevoPrestamo {
  const ReprestamoDefaultsNuevoPrestamo({
    required this.solicitaAumento,
    required this.montoNuevoSolicitado,
    required this.liquidoEntregar,
    required this.numeroCuotas,
    required this.tasaRetorno,
    required this.formaPago,
    required this.lineaCredito,
    required this.fechaDesembolso,
    required this.fechaVencimiento,
    required this.fuenteFinanciamiento,
    required this.microcreditoMultidestino,
  });

  final bool solicitaAumento;
  final double montoNuevoSolicitado;
  final double liquidoEntregar;
  final int numeroCuotas;
  final double tasaRetorno;
  final String? formaPago;
  final String? lineaCredito;
  final String? fechaDesembolso;
  final String? fechaVencimiento;
  final String? fuenteFinanciamiento;
  final bool microcreditoMultidestino;

  factory ReprestamoDefaultsNuevoPrestamo.fromJson(Map<String, dynamic> json) {
    return ReprestamoDefaultsNuevoPrestamo(
      solicitaAumento: json['solicitaAumento'] == true,
      montoNuevoSolicitado: _asDouble(json['montoNuevoSolicitado']),
      liquidoEntregar: _asDouble(json['liquidoEntregar']),
      numeroCuotas: _asInt(json['numeroCuotas']) ?? 0,
      tasaRetorno: _asDouble(json['tasaRetorno']),
      formaPago: _nullableString(json['formaPago']),
      lineaCredito: _nullableString(json['lineaCredito']),
      fechaDesembolso: _nullableString(json['fechaDesembolso']),
      fechaVencimiento: _nullableString(json['fechaVencimiento']),
      fuenteFinanciamiento: _nullableString(json['fuenteFinanciamiento']),
      microcreditoMultidestino: json['microcreditoMultidestino'] != false,
    );
  }
}

class ReprestamoCalculosIniciales {
  const ReprestamoCalculosIniciales({
    required this.nuevaCuota,
    required this.valorFuturoNuevo,
    required this.capitalMasInteres,
    required this.valorCuota,
  });

  final double nuevaCuota;
  final double valorFuturoNuevo;
  final double capitalMasInteres;
  final double valorCuota;

  factory ReprestamoCalculosIniciales.fromJson(Map<String, dynamic> json) {
    return ReprestamoCalculosIniciales(
      nuevaCuota: _asDouble(json['nuevaCuota']),
      valorFuturoNuevo: _asDouble(json['valorFuturoNuevo']),
      capitalMasInteres: _asDouble(json['capitalMasInteres']),
      valorCuota: _asDouble(json['valorCuota']),
    );
  }
}

class ReprestamoTecnicoPromotor {
  const ReprestamoTecnicoPromotor({required this.id, required this.nombre});

  final int id;
  final String? nombre;

  factory ReprestamoTecnicoPromotor.fromJson(Map<String, dynamic> json) {
    return ReprestamoTecnicoPromotor(
      id: _asInt(json['id']) ?? 0,
      nombre: _nullableString(json['nombre']),
    );
  }
}

class CrearSolicitudReprestamoMobileRequest {
  const CrearSolicitudReprestamoMobileRequest({
    required this.creditoOrigenId,
    required this.solicitaAumento,
    this.montoNuevoSolicitado,
    required this.numeroCuotas,
    required this.tasaRetorno,
    required this.formaPago,
    required this.fechaDesembolso,
    this.comentario,
  });

  final int creditoOrigenId;
  final bool solicitaAumento;
  final double? montoNuevoSolicitado;
  final int numeroCuotas;
  final double tasaRetorno;
  final String formaPago;
  final String fechaDesembolso;
  final String? comentario;

  Map<String, dynamic> toJson() {
    return {
      'creditoOrigenId': creditoOrigenId,
      'solicitaAumento': solicitaAumento,
      if (montoNuevoSolicitado != null)
        'montoNuevoSolicitado': montoNuevoSolicitado,
      'numeroCuotas': numeroCuotas,
      'tasaRetorno': tasaRetorno,
      'formaPago': formaPago,
      'fechaDesembolso': fechaDesembolso,
      if (comentario != null && comentario!.trim().isNotEmpty)
        'comentario': comentario!.trim(),
    };
  }
}

class SolicitudReprestamoCreada {
  const SolicitudReprestamoCreada({
    required this.id,
    required this.estado,
    required this.correlativoReprestamo,
    required this.nombreCliente,
    required this.referenciaCreditoOrigen,
    required this.montoNuevoSolicitado,
    required this.liquidoEntregar,
  });

  final int id;
  final String? estado;
  final String? correlativoReprestamo;
  final String? nombreCliente;
  final String? referenciaCreditoOrigen;
  final double montoNuevoSolicitado;
  final double liquidoEntregar;

  factory SolicitudReprestamoCreada.fromJson(Map<String, dynamic> json) {
    return SolicitudReprestamoCreada(
      id: _asInt(json['id']) ?? 0,
      estado: _nullableString(json['estado']),
      correlativoReprestamo: _nullableString(json['correlativoReprestamo']),
      nombreCliente: _nullableString(json['nombreCliente']),
      referenciaCreditoOrigen: _nullableString(json['referenciaCreditoOrigen']),
      montoNuevoSolicitado: _asDouble(json['montoNuevoSolicitado']),
      liquidoEntregar: _asDouble(json['liquidoEntregar']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _asString(dynamic value) => value == null ? '' : '$value';

String? _nullableString(dynamic value) {
  final text = _asString(value).trim();
  return text.isEmpty ? null : text;
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = _asString(value).trim().toLowerCase();
  if (text.isEmpty) return null;
  if (['true', '1', 'si', 'yes'].contains(text)) return true;
  if (['false', '0', 'no'].contains(text)) return false;
  return null;
}

String _joinClean(List<dynamic> values) {
  final joined = values
      .map((value) => _asString(value).trim())
      .where((value) => value.isNotEmpty)
      .join(' ');
  return _collapseWhitespace(joined);
}

String _collapseWhitespace(String value) {
  final buffer = StringBuffer();
  var previousWasWhitespace = false;
  for (final codeUnit in value.trim().codeUnits) {
    final isWhitespace = codeUnit <= 32;
    if (isWhitespace) {
      if (!previousWasWhitespace) buffer.write(' ');
    } else {
      buffer.writeCharCode(codeUnit);
    }
    previousWasWhitespace = isWhitespace;
  }
  return buffer.toString().trim();
}

String _nombreCompletoCliente(Map<String, dynamic> json) {
  final clienteMap = json['cliente'] is Map<String, dynamic>
      ? json['cliente'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final directo = _firstNonEmpty([
    json['clienteNombreCompleto'],
    json['nombreCompleto'],
    json['nombreCliente'],
    clienteMap['nombreCompleto'],
  ]);
  if (directo != null && directo.isNotEmpty) return directo;

  final porPartes = _joinClean([
    json['primerNombre'],
    json['segundoNombre'],
    json['tercerNombre'],
    json['primerApellido'],
    json['segundoApellido'],
    json['tercerApellido'],
    json['apellidoCasada'],
    clienteMap['primerNombre'],
    clienteMap['segundoNombre'],
    clienteMap['tercerNombre'],
    clienteMap['primerApellido'],
    clienteMap['segundoApellido'],
    clienteMap['tercerApellido'],
    clienteMap['apellidoCasada'],
  ]);
  if (porPartes.isNotEmpty) return porPartes;

  final legacy = _joinClean([
    if (json['cliente'] is! Map<String, dynamic>) json['cliente'],
    json['clienteNombre'],
    json['clienteApellido'],
    clienteMap['nombre'],
    clienteMap['apellido'],
  ]);
  return legacy;
}

String _clienteTexto(Map<String, dynamic> json) {
  final clienteMap = json['cliente'] is Map<String, dynamic>
      ? json['cliente'] as Map<String, dynamic>
      : const <String, dynamic>{};
  return _firstNonEmpty([
        if (json['cliente'] is! Map<String, dynamic>) json['cliente'],
        json['nombreCliente'],
        json['clienteNombre'],
        clienteMap['nombreCompleto'],
        _joinClean([clienteMap['nombre'], clienteMap['apellido']]),
      ]) ??
      '';
}

String? _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = _asString(value).trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}
