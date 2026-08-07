import '../../../core/network/api_client.dart';
import 'gestion_mora_models.dart';

class GestionMoraApi {
  GestionMoraApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<CreditosMoraPage> creditosMora({
    required int page,
    required int limit,
    String? q,
  }) async {
    final response = await _client.get(
      '/cobranza/mora/creditos',
      query: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return CreditosMoraPage.fromJson(
      response,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  }

  Future<GestionMoraCreada> registrarGestion({
    required int creditoId,
    required CrearGestionMoraRequest request,
  }) async {
    final response = await _client.post(
      '/cobranza/mora/creditos/$creditoId/gestiones',
      body: request.toJson(),
    );
    return GestionMoraCreada.fromJson(response as Map<String, dynamic>);
  }
}
