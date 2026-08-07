class ClientePago {
  const ClientePago({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.nombreCompleto,
  });

  final int? id;
  final String nombre;
  final String apellido;
  final String nombreCompleto;

  factory ClientePago.fromJson(Map<String, dynamic>? json) {
    final safe = json ?? const <String, dynamic>{};
    return ClientePago(
      id: _asInt(safe['id']),
      nombre: _asString(safe['nombre']),
      apellido: _asString(safe['apellido']),
      nombreCompleto: _asString(safe['nombreCompleto']).isNotEmpty
          ? _asString(safe['nombreCompleto'])
          : '${_asString(safe['nombre'])} ${_asString(safe['apellido'])}'
              .trim(),
    );
  }
}

class CreditoDisponible {
  const CreditoDisponible({
    required this.id,
    required this.codigoCredito,
    required this.referenciaCredito,
    required this.codigoCliente,
    required this.cliente,
    required this.carteraNombre,
    required this.gestorId,
    required this.monto,
    required this.estado,
    required this.tipo,
  });

  final int id;
  final String codigoCredito;
  final String? referenciaCredito;
  final String? codigoCliente;
  final ClientePago cliente;
  final String? carteraNombre;
  final int? gestorId;
  final double monto;
  final String estado;
  final String tipo;

  String get referenciaVisual => (referenciaCredito?.trim().isNotEmpty ?? false)
      ? referenciaCredito!.trim()
      : codigoCredito;
  String get codigoClienteVisual =>
      (codigoCliente?.trim().isNotEmpty ?? false) ? codigoCliente!.trim() : '-';

  factory CreditoDisponible.fromJson(Map<String, dynamic> json) {
    return CreditoDisponible(
      id: _asInt(json['id']) ?? _asInt(json['creditoId']) ?? 0,
      codigoCredito: _asString(json['codigoCredito']).isNotEmpty
          ? _asString(json['codigoCredito'])
          : 'CR-${(_asInt(json['id']) ?? 0).toString().padLeft(6, '0')}',
      referenciaCredito: _nullableString(json['referenciaCredito']),
      codigoCliente: _nullableString(json['codigoCliente']),
      cliente: ClientePago.fromJson(
          json['cliente'] is Map<String, dynamic> ? json['cliente'] : null),
      carteraNombre: _nullableString(json['carteraNombre']),
      gestorId: _asInt(json['gestorId']),
      monto: _asDouble(json['monto']),
      estado: _asString(json['estado']),
      tipo: _firstNonEmpty([
        json['tipo'],
        json['frecuencia'],
        json['periodicidad'],
        json['formaPago'],
      ]),
    );
  }
}

class CreditosDisponiblesPage {
  const CreditosDisponiblesPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<CreditoDisponible> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory CreditosDisponiblesPage.fromJson(dynamic json,
      {int fallbackPage = 1, int fallbackLimit = 10}) {
    if (json is List) {
      final rows = json
          .whereType<Map<String, dynamic>>()
          .map(CreditoDisponible.fromJson)
          .toList();
      return CreditosDisponiblesPage(
        data: rows,
        total: rows.length,
        page: fallbackPage,
        limit: fallbackLimit,
        totalPages: 1,
      );
    }
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rows = (map['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CreditoDisponible.fromJson)
        .toList();
    return CreditosDisponiblesPage(
      data: rows,
      total: _asInt(map['total']) ?? rows.length,
      page: _asInt(map['page']) ?? fallbackPage,
      limit: _asInt(map['limit']) ?? fallbackLimit,
      totalPages: _asInt(map['totalPages']) ?? 1,
    );
  }
}

class PagoContexto {
  const PagoContexto({
    required this.credito,
    required this.resumen,
    required this.cuotasPendientes,
    required this.pagos,
  });

  final CreditoContexto credito;
  final ResumenCreditoPago resumen;
  final List<CuotaPendientePago> cuotasPendientes;
  final List<PagoHistorial> pagos;

  factory PagoContexto.fromJson(Map<String, dynamic> json) {
    return PagoContexto(
      credito: CreditoContexto.fromJson(
          json['credito'] as Map<String, dynamic>? ?? const {}),
      resumen: ResumenCreditoPago.fromJson(
          json['resumen'] as Map<String, dynamic>? ?? const {}),
      cuotasPendientes: (json['cuotasPendientes'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CuotaPendientePago.fromJson)
          .toList(),
      pagos: (json['pagos'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PagoHistorial.fromJson)
          .toList(),
    );
  }
}

class CreditoContexto {
  const CreditoContexto({
    required this.id,
    required this.codigoCredito,
    required this.referenciaCredito,
    required this.codigoCliente,
    required this.estado,
    required this.tipo,
    required this.monto,
    required this.carteraNombre,
    required this.cliente,
  });

  final int id;
  final String codigoCredito;
  final String? referenciaCredito;
  final String? codigoCliente;
  final String estado;
  final String tipo;
  final double monto;
  final String? carteraNombre;
  final ClientePago cliente;

  String get referenciaVisual => (referenciaCredito?.trim().isNotEmpty ?? false)
      ? referenciaCredito!.trim()
      : codigoCredito;
  String get codigoClienteVisual =>
      (codigoCliente?.trim().isNotEmpty ?? false) ? codigoCliente!.trim() : '-';

  factory CreditoContexto.fromJson(Map<String, dynamic> json) {
    return CreditoContexto(
      id: _asInt(json['id']) ?? 0,
      codigoCredito: _asString(json['codigoCredito']).isNotEmpty
          ? _asString(json['codigoCredito'])
          : 'CR-${(_asInt(json['id']) ?? 0).toString().padLeft(6, '0')}',
      referenciaCredito: _nullableString(json['referenciaCredito']),
      codigoCliente: _nullableString(json['codigoCliente']),
      estado: _asString(json['estado']),
      tipo: _asString(json['tipo']),
      monto: _asDouble(json['monto']),
      carteraNombre: _nullableString(json['carteraNombre']),
      cliente: ClientePago.fromJson(
          json['cliente'] is Map<String, dynamic> ? json['cliente'] : null),
    );
  }
}

class ResumenCreditoPago {
  const ResumenCreditoPago({
    required this.totalAPagar,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.cuotasPendientes,
    required this.cuotasVencidas,
    required this.diasMora,
    required this.planPendienteDesembolso,
  });

  final double totalAPagar;
  final double totalPagado;
  final double saldoPendiente;
  final int cuotasPendientes;
  final int cuotasVencidas;
  final int diasMora;
  final String? planPendienteDesembolso;

  factory ResumenCreditoPago.fromJson(Map<String, dynamic> json) {
    return ResumenCreditoPago(
      totalAPagar: _asDouble(json['totalAPagar']),
      totalPagado: _asDouble(json['totalPagado']),
      saldoPendiente: _asDouble(json['saldoPendiente']),
      cuotasPendientes: _asInt(json['cuotasPendientes']) ?? 0,
      cuotasVencidas: _asInt(json['cuotasVencidas']) ?? 0,
      diasMora: _asInt(json['diasMora']) ?? 0,
      planPendienteDesembolso: _nullableString(json['planPendienteDesembolso']),
    );
  }
}

class CuotaPendientePago {
  const CuotaPendientePago({
    required this.id,
    required this.numero,
    required this.fechaPago,
    required this.total,
    required this.montoPagado,
    required this.saldoCuota,
    required this.estado,
  });

  final int id;
  final int numero;
  final String fechaPago;
  final double total;
  final double montoPagado;
  final double saldoCuota;
  final String estado;

  factory CuotaPendientePago.fromJson(Map<String, dynamic> json) {
    return CuotaPendientePago(
      id: _asInt(json['id']) ?? 0,
      numero: _asInt(json['numero']) ?? 0,
      fechaPago: _asString(json['fechaPago']),
      total: _asDouble(json['total']),
      montoPagado: _asDouble(json['montoPagado']),
      saldoCuota: _asDouble(json['saldoCuota']),
      estado: _asString(json['estado']),
    );
  }
}

class PagoHistorial {
  const PagoHistorial({
    required this.id,
    required this.monto,
    required this.fechaPago,
    required this.medioPago,
    required this.observacion,
    required this.reimpresion,
  });

  final int id;
  final double monto;
  final String fechaPago;
  final String? medioPago;
  final String? observacion;
  final ReimpresionEstado reimpresion;

  factory PagoHistorial.fromJson(Map<String, dynamic> json) {
    return PagoHistorial(
      id: _asInt(json['id']) ?? 0,
      monto: _asDouble(json['monto']),
      fechaPago: _asString(json['fecha_pago']),
      medioPago: _nullableString(json['medioPago']),
      observacion: _nullableString(json['observacion']),
      reimpresion: ReimpresionEstado.fromJson(
        json['reimpresion'] is Map<String, dynamic>
            ? json['reimpresion'] as Map<String, dynamic>
            : null,
      ),
    );
  }
}

class ReimpresionEstado {
  const ReimpresionEstado({
    required this.puedeSolicitar,
    required this.puedeImprimir,
    required this.estado,
    required this.mensaje,
    this.motivoRespuesta,
    this.solicitudId,
  });

  final bool puedeSolicitar;
  final bool puedeImprimir;
  final String estado;
  final String mensaje;
  final String? motivoRespuesta;
  final String? solicitudId;

  factory ReimpresionEstado.fromJson(Map<String, dynamic>? json) {
    final safe = json ?? const <String, dynamic>{};
    return ReimpresionEstado(
      puedeSolicitar: safe['puedeSolicitar'] == true,
      puedeImprimir: safe['puedeImprimir'] == true,
      estado: _asString(safe['estado']).isNotEmpty
          ? _asString(safe['estado'])
          : 'SIN_SOLICITUD',
      mensaje: _asString(safe['mensaje']),
      motivoRespuesta: _nullableString(safe['motivoRespuesta']),
      solicitudId: _nullableString(safe['solicitudId']),
    );
  }
}

class PagoRegistrado {
  const PagoRegistrado({required this.id, required this.monto});

  final int id;
  final double monto;

  factory PagoRegistrado.fromJson(Map<String, dynamic> json) {
    return PagoRegistrado(
      id: _asInt(json['id']) ?? 0,
      monto: _asDouble(json['monto']),
    );
  }
}

class ComprobanteRender {
  const ComprobanteRender({
    required this.usandoPlantilla,
    required this.html,
    required this.snapshot,
    required this.historicoSinSnapshot,
  });

  final bool usandoPlantilla;
  final String? html;
  final Map<String, dynamic>? snapshot;
  final bool historicoSinSnapshot;

  factory ComprobanteRender.fromJson(Map<String, dynamic> json) {
    return ComprobanteRender(
      usandoPlantilla: json['usandoPlantilla'] == true,
      html: _nullableString(json['html']),
      snapshot: json['snapshot'] is Map<String, dynamic>
          ? json['snapshot'] as Map<String, dynamic>
          : null,
      historicoSinSnapshot: json['historicoSinSnapshot'] == true,
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

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = _asString(value).trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}
