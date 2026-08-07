import '../../../core/network/api_client.dart';
import 'app_access_models.dart';

class AppAccessApi {
  AppAccessApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AppStatus> status() async {
    final response = await _client.get('/auth/app-status');
    return AppStatus.fromJson(response as Map<String, dynamic>);
  }

  Future<AppAccessRequest> solicitar({required String motivo}) async {
    final response = await _client.post(
      '/auth/app-access/solicitar',
      body: {'motivo': motivo.trim()},
    );
    final raw = response as Map<String, dynamic>;
    final solicitud = raw['solicitudAcceso'];
    if (solicitud is Map) {
      return AppAccessRequest.fromJson(solicitud.cast<String, dynamic>());
    }
    return AppAccessRequest(
      estado: raw['estado']?.toString(),
      mensaje: raw['mensaje']?.toString(),
    );
  }

  Future<AppAccessRequest> miSolicitud() async {
    final response = await _client.get('/auth/app-access/mi-solicitud');
    return AppAccessRequest.fromJson((response as Map).cast<String, dynamic>());
  }
}
