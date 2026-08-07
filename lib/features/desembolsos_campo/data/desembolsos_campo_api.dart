import '../../../core/network/api_client.dart';
import 'desembolsos_campo_models.dart';

class DesembolsosCampoApi {
  DesembolsosCampoApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<DesembolsosCampoPageResult> getDisponibles({
    required int page,
    required int limit,
    String? q,
  }) async {
    final response = await _client.get(
      '/caja/desembolsos-campo/disponibles',
      query: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return DesembolsosCampoPageResult.fromJson(
      response,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  }

  Future<EntregaDesembolsoCampoMarcada> marcarEntregado({
    required DesembolsoCampoDisponible item,
    required MarcarEntregaDesembolsoRequest request,
  }) async {
    final path = _marcarEntregadoPath(item);
    final response = await _client.post(
      path,
      body: request.toJson(),
    );
    return EntregaDesembolsoCampoMarcada.fromJson(
        response as Map<String, dynamic>);
  }

  String _marcarEntregadoPath(DesembolsoCampoDisponible item) {
    if (item.esReprestamo) {
      final id = item.resolucionReprestamoId;
      if (id == null || id <= 0) {
        throw StateError('El re-prestamo no tiene resolucionReprestamoId.');
      }
      return '/caja/desembolsos-campo/represtamos/$id/marcar-entregado';
    }

    final id = item.solicitudFondoId;
    if (id == null || id <= 0) {
      throw StateError('El desembolso normal no tiene solicitudFondoId.');
    }
    return '/caja/desembolsos-campo/$id/marcar-entregado';
  }
}
