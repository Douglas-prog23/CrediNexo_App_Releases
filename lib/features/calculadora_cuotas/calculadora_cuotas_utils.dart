class CuotaCalculada {
  const CuotaCalculada({
    required this.monto,
    required this.tasaRetorno,
    required this.numeroCuotas,
    required this.frecuencia,
    required this.interes,
    required this.totalAPagar,
    required this.valorCuota,
    required this.diasEquivalentes,
    required this.fechaVencimiento,
    required this.muestraNotaAsuetos,
  });

  final double monto;
  final double tasaRetorno;
  final int numeroCuotas;
  final String frecuencia;
  final double interes;
  final double totalAPagar;
  final double valorCuota;
  final int diasEquivalentes;
  final DateTime fechaVencimiento;
  final bool muestraNotaAsuetos;
}

const frecuenciaDiario = 'Diario';
const frecuenciaSemanal = 'Semanal';
const frecuenciaCatorcenal = 'Catorcenal';
const frecuenciaQuincenal = 'Quincenal';
const frecuenciaMensual = 'Mensual';
const frecuenciaLunesViernes = 'Lunes a Viernes';
const frecuenciaAcumulado = 'Acumulado';
const frecuenciaEstacional = 'Estacional';
const frecuenciaExcepcional = 'Excepcional';

const frecuenciasCalculadoraCuotas = [
  frecuenciaDiario,
  frecuenciaSemanal,
  frecuenciaCatorcenal,
  frecuenciaQuincenal,
  frecuenciaMensual,
  frecuenciaLunesViernes,
  frecuenciaAcumulado,
  frecuenciaEstacional,
  frecuenciaExcepcional,
];

double? parseMontoCalculadora(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

int? parseCuotasCalculadora(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}

CuotaCalculada? calcularCuotaEstimada({
  required double? monto,
  required double? tasaRetorno,
  required int? numeroCuotas,
  required String? frecuencia,
  required DateTime? fechaBase,
}) {
  final frecuenciaValida =
      frecuencia != null && frecuenciasCalculadoraCuotas.contains(frecuencia);
  if ((monto ?? 0) <= 0 ||
      (tasaRetorno ?? -1) < 0 ||
      (numeroCuotas ?? 0) <= 0 ||
      !frecuenciaValida ||
      fechaBase == null) {
    return null;
  }

  final montoSeguro = monto!;
  final tasaSegura = tasaRetorno!;
  final cuotasSeguras = numeroCuotas!;
  final interes = montoSeguro * tasaSegura / 100;
  final totalAPagar = montoSeguro + interes;
  final valorCuota = totalAPagar / cuotasSeguras;
  final diasEquivalentes =
      diasEquivalentesPorFrecuencia(frecuencia, cuotasSeguras);
  final fechaVencimiento = calcularFechaVencimientoEstimada(
    fechaBase: fechaBase,
    frecuencia: frecuencia,
    numeroCuotas: cuotasSeguras,
  );

  return CuotaCalculada(
    monto: montoSeguro,
    tasaRetorno: tasaSegura,
    numeroCuotas: cuotasSeguras,
    frecuencia: frecuencia,
    interes: interes,
    totalAPagar: totalAPagar,
    valorCuota: valorCuota,
    diasEquivalentes: diasEquivalentes,
    fechaVencimiento: fechaVencimiento,
    muestraNotaAsuetos: usaDiasHabilesSinAsuetos(frecuencia),
  );
}

int diasEquivalentesPorFrecuencia(String frecuencia, int numeroCuotas) {
  final dias = switch (frecuencia) {
    frecuenciaSemanal => 7,
    frecuenciaCatorcenal => 14,
    frecuenciaQuincenal => 15,
    frecuenciaMensual => 30,
    _ => 1,
  };
  return dias * numeroCuotas;
}

DateTime calcularFechaVencimientoEstimada({
  required DateTime fechaBase,
  required String frecuencia,
  required int numeroCuotas,
}) {
  final base = DateTime(fechaBase.year, fechaBase.month, fechaBase.day);
  if (frecuencia == frecuenciaDiario || frecuencia == frecuenciaAcumulado) {
    return _sumarDiasHabiles(base, numeroCuotas, excluirSabado: false);
  }
  if (frecuencia == frecuenciaLunesViernes) {
    return _sumarDiasHabiles(base, numeroCuotas, excluirSabado: true);
  }
  return base.add(
    Duration(days: diasEquivalentesPorFrecuencia(frecuencia, numeroCuotas)),
  );
}

bool usaDiasHabilesSinAsuetos(String frecuencia) =>
    frecuencia == frecuenciaDiario ||
    frecuencia == frecuenciaAcumulado ||
    frecuencia == frecuenciaLunesViernes;

DateTime _sumarDiasHabiles(
  DateTime fechaBase,
  int dias, {
  required bool excluirSabado,
}) {
  var fecha = fechaBase;
  var pendientes = dias;
  while (pendientes > 0) {
    fecha = fecha.add(const Duration(days: 1));
    final esDomingo = fecha.weekday == DateTime.sunday;
    final esSabado = fecha.weekday == DateTime.saturday;
    if (esDomingo || (excluirSabado && esSabado)) continue;
    pendientes--;
  }
  return fecha;
}
