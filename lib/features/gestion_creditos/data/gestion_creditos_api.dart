import '../../pagos/data/pagos_api.dart';
import '../../pagos/data/pagos_models.dart';
import '../../represtamos/data/represtamos_api.dart';
import '../../represtamos/data/represtamos_models.dart';

class GestionCreditosApi {
  GestionCreditosApi({
    PagosApi? pagosApi,
    ReprestamosApi? represtamosApi,
  })  : _pagosApi = pagosApi ?? PagosApi(),
        _represtamosApi = represtamosApi ?? ReprestamosApi();

  final PagosApi _pagosApi;
  final ReprestamosApi _represtamosApi;

  Future<CreditosDisponiblesPage> creditos({
    required int page,
    required int limit,
    String? q,
  }) {
    return _pagosApi.creditosDisponibles(page: page, limit: limit, q: q);
  }

  Future<PagoContexto> detalleCredito(int creditoId) {
    return _pagosApi.contextoCredito(creditoId);
  }

  Future<ReprestamoContexto?> contextoReprestamo(int creditoId) async {
    try {
      return await _represtamosApi.contextoCredito(creditoId);
    } catch (_) {
      return null;
    }
  }
}
