import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/network/api_client.dart';
import 'app_version_models.dart';

class AppVersionApi {
  AppVersionApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AppVersionStatus> status() async {
    final response = await _client.get('/auth/app-version');
    return AppVersionStatus.fromJson(response as Map<String, dynamic>);
  }

  Future<InstalledAppVersion> installedVersion() async {
    final info = await PackageInfo.fromPlatform();
    return InstalledAppVersion(
      version: _normalizeVersion(info.version),
      buildNumber: info.buildNumber,
    );
  }

  String _normalizeVersion(String value) {
    final version = value.trim();
    final plusIndex = version.indexOf('+');
    return plusIndex >= 0 ? version.substring(0, plusIndex) : version;
  }
}
