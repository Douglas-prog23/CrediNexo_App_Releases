class CreditoMora {
  const CreditoMora({
    required this.creditoId,
    required this.referenciaCredito,
    required this.numeroPrestamo,
    required this.codigoCliente,
    required this.cliente,
    required this.dui,
    required this.monto,
    required this.saldoPendiente,
    required this.saldoCapital,
    required this.valorCuota,
    required this.cuotasVencidas,
    required this.diasMora,
    required this.metodoMora,
    required this.tramo,
    required this.fechaUltimoPago,
    required this.fechaProximaCuota,
    required this.estado,
    required this.carteraNombre,
    required this.gestorNombre,
    required this.telefonoCliente,
    required this.direccionCliente,
  });

  final int creditoId;
  final String? referenciaCredito;
  final String? numeroPrestamo;
  final String? codigoCliente;
  final String cliente;
  final String? dui;
  final double monto;
  final double saldoPendiente;
  final double saldoCapital;
  final double valorCuota;
  final int cuotasVencidas;
  final int diasMora;
  final String? metodoMora;
  final String? tramo;
  final String? fechaUltimoPago;
  final String? fechaProximaCuota;
  final String? estado;
  final String? carteraNombre;
  final String? gestorNombre;
  final String? telefonoCliente;
  final String? direccionCliente;

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

  factory CreditoMora.fromJson(Map<String, dynamic> json) {
    return CreditoMora(
      creditoId: _asInt(json['creditoId']) ?? _asInt(json['id']) ?? 0,
      referenciaCredito: _nullableString(json['referenciaCredito']),
      numeroPrestamo: _nullableString(json['numeroPrestamo']),
      codigoCliente: _nullableString(json['codigoCliente']),
      cliente: _asString(json['cliente']),
      dui: _nullableString(json['dui']),
      monto: _asDouble(json['monto']),
      saldoPendiente: _asDouble(json['saldoPendiente']),
      saldoCapital: _asDouble(json['saldoCapital']),
      valorCuota: _asDouble(json['valorCuota']),
      cuotasVencidas: _asInt(json['cuotasVencidas']) ?? 0,
      diasMora: _asInt(json['diasMora']) ?? 0,
      metodoMora: _nullableString(json['metodoMora']),
      tramo: _nullableString(json['tramo']),
      fechaUltimoPago: _nullableString(json['fechaUltimoPago']),
      fechaProximaCuota: _nullableString(json['fechaProximaCuota']),
      estado: _nullableString(json['estado']),
      carteraNombre: _nullableString(json['carteraNombre']),
      gestorNombre: _nullableString(json['gestorNombre']),
      telefonoCliente: _nullableString(json['telefonoCliente']),
      direccionCliente: _nullableString(json['direccionCliente']),
    );
  }
}

class CreditosMoraPage {
  const CreditosMoraPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<CreditoMora> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory CreditosMoraPage.fromJson(
    dynamic json, {
    int fallbackPage = 1,
    int fallbackLimit = 10,
  }) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rows = (map['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CreditoMora.fromJson)
        .toList();
    return CreditosMoraPage(
      data: rows,
      total: _asInt(map['total']) ?? rows.length,
      page: _asInt(map['page']) ?? fallbackPage,
      limit: _asInt(map['limit']) ?? fallbackLimit,
      totalPages: _asInt(map['totalPages']) ?? 1,
    );
  }
}

class CrearGestionMoraRequest {
  const CrearGestionMoraRequest({
    required this.tipoGestion,
    required this.resultado,
    required this.comentario,
    this.fechaCompromiso,
    this.montoCompromiso,
    this.proximaGestion,
  });

  final String tipoGestion;
  final String resultado;
  final String comentario;
  final String? fechaCompromiso;
  final double? montoCompromiso;
  final String? proximaGestion;

  Map<String, dynamic> toJson() {
    return {
      'tipoGestion': tipoGestion,
      'resultado': resultado,
      'comentario': comentario.trim(),
      if (fechaCompromiso != null && fechaCompromiso!.trim().isNotEmpty)
        'fechaCompromiso': fechaCompromiso,
      if (montoCompromiso != null) 'montoCompromiso': montoCompromiso,
      if (proximaGestion != null && proximaGestion!.trim().isNotEmpty)
        'proximaGestion': proximaGestion,
    };
  }
}

class GestionMoraCreada {
  const GestionMoraCreada({
    required this.id,
    required this.creditoId,
    required this.tipoGestion,
    required this.resultado,
    required this.comentario,
    required this.fechaCompromiso,
    required this.montoCompromiso,
    required this.proximaGestion,
    required this.creadoEn,
  });

  final int id;
  final int creditoId;
  final String? tipoGestion;
  final String? resultado;
  final String? comentario;
  final String? fechaCompromiso;
  final double? montoCompromiso;
  final String? proximaGestion;
  final String? creadoEn;

  factory GestionMoraCreada.fromJson(Map<String, dynamic> json) {
    return GestionMoraCreada(
      id: _asInt(json['id']) ?? 0,
      creditoId: _asInt(json['creditoId']) ?? 0,
      tipoGestion: _nullableString(json['tipoGestion']),
      resultado: _nullableString(json['resultado']),
      comentario: _nullableString(json['comentario']),
      fechaCompromiso: _nullableString(json['fechaCompromiso']),
      montoCompromiso: json['montoCompromiso'] == null
          ? null
          : _asDouble(json['montoCompromiso']),
      proximaGestion: _nullableString(json['proximaGestion']),
      creadoEn: _nullableString(json['creadoEn']),
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
