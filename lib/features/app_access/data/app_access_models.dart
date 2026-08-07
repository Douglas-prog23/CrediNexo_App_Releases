class AppStatus {
  const AppStatus({
    required this.abierta,
    required this.fueraHorario,
    required this.puedeIngresar,
    required this.puedeIngresarFueraHorario,
    required this.requiereSolicitud,
    required this.horaActual,
    required this.fechaActual,
    required this.horaApertura,
    required this.horaCierre,
    required this.zonaHoraria,
    required this.mensaje,
    this.solicitudAcceso,
  });

  final bool abierta;
  final bool fueraHorario;
  final bool puedeIngresar;
  final bool puedeIngresarFueraHorario;
  final bool requiereSolicitud;
  final String horaActual;
  final String fechaActual;
  final String horaApertura;
  final String horaCierre;
  final String zonaHoraria;
  final String mensaje;
  final AppAccessRequest? solicitudAcceso;

  factory AppStatus.fromJson(Map<String, dynamic> json) {
    return AppStatus(
      abierta: json['abierta'] == true,
      fueraHorario: json['fueraHorario'] == true,
      puedeIngresar: json['puedeIngresar'] == true,
      puedeIngresarFueraHorario: json['puedeIngresarFueraHorario'] == true,
      requiereSolicitud: json['requiereSolicitud'] == true,
      horaActual: '${json['horaActual'] ?? ''}',
      fechaActual: '${json['fechaActual'] ?? ''}',
      horaApertura: '${json['horaApertura'] ?? '06:00'}',
      horaCierre: '${json['horaCierre'] ?? '19:00'}',
      zonaHoraria: '${json['zonaHoraria'] ?? 'America/El_Salvador'}',
      mensaje: '${json['mensaje'] ?? ''}',
      solicitudAcceso: json['solicitudAcceso'] is Map
          ? AppAccessRequest.fromJson(
              (json['solicitudAcceso'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

class AppAccessRequest {
  const AppAccessRequest({
    this.id,
    this.estado,
    this.mensaje,
    this.motivoSolicitud,
    this.motivoRespuesta,
    this.finAcceso,
  });

  final String? id;
  final String? estado;
  final String? mensaje;
  final String? motivoSolicitud;
  final String? motivoRespuesta;
  final DateTime? finAcceso;

  factory AppAccessRequest.fromJson(Map<String, dynamic> json) {
    return AppAccessRequest(
      id: json['id']?.toString(),
      estado: json['estado']?.toString(),
      mensaje: json['mensaje']?.toString(),
      motivoSolicitud: json['motivoSolicitud']?.toString(),
      motivoRespuesta: json['motivoRespuesta']?.toString(),
      finAcceso: DateTime.tryParse('${json['finAcceso'] ?? ''}'),
    );
  }
}
