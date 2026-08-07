class DesembolsoCampoDisponible {
  const DesembolsoCampoDisponible({
    required this.tipo,
    required this.id,
    required this.solicitudFondoId,
    required this.resolucionReprestamoId,
    required this.solicitudPrestamoId,
    required this.clienteId,
    required this.cliente,
    required this.codigoCliente,
    required this.duiMasked,
    required this.telefono,
    required this.direccion,
    required this.montoAprobado,
    required this.montoADesembolsar,
    required this.liquidoAEntregar,
    required this.estado,
    required this.estadoEntregaCampo,
    required this.responsableEntregaCampoId,
    required this.responsableEntregaCampoNombre,
    required this.tecnicoPromotorCreditoId,
    required this.tecnicoPromotorNombre,
    required this.fechaSolicitud,
    required this.fechaAprobacion,
    required this.numeroSolicitud,
    required this.referenciaCreditoOrigen,
    required this.agencia,
  });

  final String tipo;
  final int id;
  final int? solicitudFondoId;
  final int? resolucionReprestamoId;
  final int? solicitudPrestamoId;
  final int? clienteId;
  final String cliente;
  final String? codigoCliente;
  final String? duiMasked;
  final String? telefono;
  final String? direccion;
  final double montoAprobado;
  final double montoADesembolsar;
  final double liquidoAEntregar;
  final String? estado;
  final String? estadoEntregaCampo;
  final int? responsableEntregaCampoId;
  final String? responsableEntregaCampoNombre;
  final int? tecnicoPromotorCreditoId;
  final String? tecnicoPromotorNombre;
  final String? fechaSolicitud;
  final String? fechaAprobacion;
  final String? numeroSolicitud;
  final String? referenciaCreditoOrigen;
  final AgenciaCampo? agencia;

  String get codigoClienteVisual {
    final codigo = codigoCliente?.trim();
    return codigo != null && codigo.isNotEmpty ? codigo : '-';
  }

  bool get esReprestamo => tipo.toUpperCase() == 'REPRESTAMO';
  bool get esNormal => !esReprestamo;

  String get tipoLabel => esReprestamo ? 'REPRESTAMO' : 'NORMAL';

  String get identificadorVisual {
    if (esReprestamo) {
      return referenciaCreditoOrigen?.trim().isNotEmpty == true
          ? referenciaCreditoOrigen!.trim()
          : 'Re-prestamo ${resolucionReprestamoId ?? id}';
    }
    return numeroSolicitud?.trim().isNotEmpty == true
        ? numeroSolicitud!.trim()
        : 'Solicitud ${solicitudFondoId ?? id}';
  }

  factory DesembolsoCampoDisponible.fromJson(Map<String, dynamic> json) {
    final tipo = _nullableString(json['tipo'])?.toUpperCase() ?? 'NORMAL';
    return DesembolsoCampoDisponible(
      tipo: tipo == 'REPRESTAMO' ? 'REPRESTAMO' : 'NORMAL',
      id: _asInt(json['id']) ??
          _asInt(json['solicitudFondoId']) ??
          _asInt(json['resolucionReprestamoId']) ??
          0,
      solicitudFondoId: _asInt(json['solicitudFondoId']),
      resolucionReprestamoId: _asInt(json['resolucionReprestamoId']),
      solicitudPrestamoId: _asInt(json['solicitudPrestamoId']),
      clienteId: _asInt(json['clienteId']),
      cliente: _asString(json['cliente']),
      codigoCliente: _nullableString(json['codigoCliente']),
      duiMasked:
          _nullableString(json['duiMasked']) ?? _nullableString(json['dui']),
      telefono: _nullableString(json['telefono']),
      direccion: _nullableString(json['direccion']),
      montoAprobado: _asDouble(json['montoAprobado']),
      montoADesembolsar: _asDouble(json['montoADesembolsar']),
      liquidoAEntregar: _asDouble(json['liquidoAEntregar']),
      estado: _nullableString(json['estado']),
      estadoEntregaCampo: _nullableString(json['estadoEntregaCampo']),
      responsableEntregaCampoId: _asInt(json['responsableEntregaCampoId']),
      responsableEntregaCampoNombre:
          _nullableString(json['responsableEntregaCampoNombre']),
      tecnicoPromotorCreditoId: _asInt(json['tecnicoPromotorCreditoId']),
      tecnicoPromotorNombre: _nullableString(json['tecnicoPromotorNombre']),
      fechaSolicitud: _nullableString(json['fechaSolicitud']),
      fechaAprobacion: _nullableString(json['fechaAprobacion']),
      numeroSolicitud: _nullableString(json['numeroSolicitud']),
      referenciaCreditoOrigen: _nullableString(json['referenciaCreditoOrigen']),
      agencia: json['agencia'] is Map<String, dynamic>
          ? AgenciaCampo.fromJson(json['agencia'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AgenciaCampo {
  const AgenciaCampo({required this.id, required this.nombre});

  final int? id;
  final String? nombre;

  factory AgenciaCampo.fromJson(Map<String, dynamic> json) {
    return AgenciaCampo(
      id: _asInt(json['id']),
      nombre: _nullableString(json['nombre']),
    );
  }
}

class DesembolsosCampoPageResult {
  const DesembolsosCampoPageResult({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<DesembolsoCampoDisponible> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory DesembolsosCampoPageResult.fromJson(
    dynamic json, {
    int fallbackPage = 1,
    int fallbackLimit = 10,
  }) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rows = (map['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DesembolsoCampoDisponible.fromJson)
        .toList();
    return DesembolsosCampoPageResult(
      data: rows,
      total: _asInt(map['total']) ?? rows.length,
      page: _asInt(map['page']) ?? fallbackPage,
      limit: _asInt(map['limit']) ?? fallbackLimit,
      totalPages: _asInt(map['totalPages']) ?? 1,
    );
  }
}

class MarcarEntregaDesembolsoRequest {
  const MarcarEntregaDesembolsoRequest({
    required this.fechaEntregaCampo,
    this.observacionEntregaCampo,
  });

  final String fechaEntregaCampo;
  final String? observacionEntregaCampo;

  Map<String, dynamic> toJson() {
    return {
      'fechaEntregaCampo': fechaEntregaCampo,
      if (observacionEntregaCampo != null &&
          observacionEntregaCampo!.trim().isNotEmpty)
        'observacionEntregaCampo': observacionEntregaCampo!.trim(),
    };
  }
}

class EntregaDesembolsoCampoMarcada {
  const EntregaDesembolsoCampoMarcada({
    required this.solicitudFondoId,
    required this.resolucionReprestamoId,
    required this.estadoEntregaCampo,
    required this.entregadoPorAsesorId,
    required this.entregadoPorAsesorNombre,
    required this.fechaEntregaCampo,
    required this.observacionEntregaCampo,
    required this.fechaRegistroEntregaCampo,
  });

  final int? solicitudFondoId;
  final int? resolucionReprestamoId;
  final String? estadoEntregaCampo;
  final int? entregadoPorAsesorId;
  final String? entregadoPorAsesorNombre;
  final String? fechaEntregaCampo;
  final String? observacionEntregaCampo;
  final String? fechaRegistroEntregaCampo;

  factory EntregaDesembolsoCampoMarcada.fromJson(Map<String, dynamic> json) {
    return EntregaDesembolsoCampoMarcada(
      solicitudFondoId: _asInt(json['solicitudFondoId']),
      resolucionReprestamoId: _asInt(json['resolucionReprestamoId']),
      estadoEntregaCampo: _nullableString(json['estadoEntregaCampo']),
      entregadoPorAsesorId: _asInt(json['entregadoPorAsesorId']),
      entregadoPorAsesorNombre:
          _nullableString(json['entregadoPorAsesorNombre']),
      fechaEntregaCampo: _nullableString(json['fechaEntregaCampo']),
      observacionEntregaCampo: _nullableString(json['observacionEntregaCampo']),
      fechaRegistroEntregaCampo:
          _nullableString(json['fechaRegistroEntregaCampo']),
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
