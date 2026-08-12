class ApiConfig {
  // Android emulator hacia backend local de la computadora: http://10.0.2.2:3000
  // Dispositivo fisico en red local: cambiar por http://IP_LAN:PUERTO
  // Produccion: usar dominio HTTPS.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'https://9pk1g821-3000.use2.devtunnels.ms');
    //defaultValue: 'https://api-creditos.queseriasv.com',
    defaultValue: 'https://api.credinexosv.com',
  );
}
