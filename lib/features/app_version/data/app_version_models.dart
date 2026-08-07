class AppVersionStatus {
  const AppVersionStatus({
    required this.versionActual,
    required this.versionMinima,
    required this.actualizacionObligatoria,
    required this.mensaje,
    required this.urlDescarga,
    required this.zonaHoraria,
  });

  final String versionActual;
  final String versionMinima;
  final bool actualizacionObligatoria;
  final String mensaje;
  final String urlDescarga;
  final String zonaHoraria;

  factory AppVersionStatus.fromJson(Map<String, dynamic> json) {
    return AppVersionStatus(
      versionActual: _asString(json['versionActual']),
      versionMinima: _asString(json['versionMinima']),
      actualizacionObligatoria: json['actualizacionObligatoria'] == true,
      mensaje: _asString(json['mensaje']),
      urlDescarga: _asString(json['urlDescarga']),
      zonaHoraria: _asString(json['zonaHoraria']),
    );
  }
}

class InstalledAppVersion {
  const InstalledAppVersion({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final String buildNumber;

  String get display =>
      buildNumber.trim().isEmpty ? version : '$version+$buildNumber';
}

String _asString(dynamic value) => value == null ? '' : '$value';
