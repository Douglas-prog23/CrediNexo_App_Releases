import '../../../core/network/api_client.dart';
import 'represtamos_models.dart';

class ReprestamosApi {
  ReprestamosApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ReprestamosDisponiblesPage> creditosDisponibles({
    required int page,
    required int limit,
    String? q,
  }) async {
    final response = await _client.get(
      '/prestamos/solicitudes-represtamos/creditos-disponibles',
      query: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return ReprestamosDisponiblesPage.fromJson(
      response,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  }

  Future<ReprestamoContexto> contextoCredito(int creditoId) async {
    final response = await _client.get(
      '/prestamos/solicitudes-represtamos/creditos-disponibles/$creditoId/contexto',
    );
    return ReprestamoContexto.fromJson(response as Map<String, dynamic>);
  }

  Future<SolicitudReprestamoCreada> crearSolicitudMobile(
    CrearSolicitudReprestamoMobileRequest request,
  ) async {
    final response = await _client.post(
      '/prestamos/solicitudes-represtamos/mobile',
      body: request.toJson(),
    );
    return SolicitudReprestamoCreada.fromJson(response as Map<String, dynamic>);
  }
}
