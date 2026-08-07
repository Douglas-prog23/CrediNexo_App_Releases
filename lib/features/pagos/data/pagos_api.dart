import '../../../core/network/api_client.dart';
import 'pagos_models.dart';

class PagosApi {
  PagosApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<CreditosDisponiblesPage> creditosDisponibles({
    required int page,
    required int limit,
    String? q,
  }) async {
    final response = await _client.get(
      '/pagos/creditos-disponibles',
      query: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return CreditosDisponiblesPage.fromJson(
      response,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  }

  Future<PagoContexto> contextoCredito(int creditoId) async {
    final response =
        await _client.get('/pagos/creditos/$creditoId/contexto-caja');
    return PagoContexto.fromJson(response as Map<String, dynamic>);
  }

  Future<PagoRegistrado> registrarPago({
    required int creditoId,
    required double monto,
    required String medioPago,
    double? montoRecibido,
    double? vuelto,
    String? observacion,
    String? numeroReferencia,
    String? fechaTransferencia,
  }) async {
    final body = <String, dynamic>{
      'credito': creditoId,
      'creditoId': creditoId,
      'monto': monto,
      'origenPago': 'CAMPO',
      'medioPago': medioPago,
      if (medioPago == 'EFECTIVO') 'montoRecibido': montoRecibido ?? monto,
      if (medioPago == 'EFECTIVO') 'vuelto': vuelto ?? 0,
      if (observacion != null && observacion.trim().isNotEmpty)
        'observacion': observacion.trim(),
      if (numeroReferencia != null && numeroReferencia.trim().isNotEmpty)
        'numeroReferencia': numeroReferencia.trim(),
      if (fechaTransferencia != null && fechaTransferencia.trim().isNotEmpty)
        'fechaTransferencia': fechaTransferencia.trim(),
    };
    final response = await _client.post('/pagos', body: body);
    return PagoRegistrado.fromJson(response as Map<String, dynamic>);
  }

  Future<ComprobanteRender> renderComprobante(int pagoId) async {
    final response = await _client.get('/pagos/$pagoId/comprobante/render');
    return ComprobanteRender.fromJson(response as Map<String, dynamic>);
  }

  Future<ComprobanteRender> comprobanteSnapshot(int pagoId) async {
    final response = await _client.get('/pagos/$pagoId/comprobante');
    return ComprobanteRender.fromJson(response as Map<String, dynamic>);
  }

  Future<ReimpresionEstado> estadoReimpresion(int pagoId) async {
    final response = await _client.get('/pagos/$pagoId/reimpresion/estado');
    return ReimpresionEstado.fromJson(response as Map<String, dynamic>);
  }

  Future<ReimpresionEstado> solicitarReimpresion(
    int pagoId, {
    String? motivo,
  }) async {
    await _client.post(
      '/pagos/$pagoId/reimpresion/solicitar',
      body: {
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      },
    );
    return estadoReimpresion(pagoId);
  }

  Future<ComprobanteRender> renderComprobanteReimpresion(int pagoId) async {
    final response =
        await _client.get('/pagos/$pagoId/comprobante/reimpresion/render');
    return ComprobanteRender.fromJson(response as Map<String, dynamic>);
  }

  Future<void> marcarReimpresionUsada(int pagoId) async {
    await _client.patch('/pagos/$pagoId/reimpresion/marcar-usada');
  }
}
