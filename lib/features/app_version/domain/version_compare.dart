int compareVersions(String installed, String required) {
  final installedVersion = _FlutterVersion.parse(installed);
  final requiredVersion = _FlutterVersion.parse(required);
  final installedParts = installedVersion.nameParts;
  final requiredParts = requiredVersion.nameParts;
  final length = installedParts.length > requiredParts.length
      ? installedParts.length
      : requiredParts.length;

  for (var i = 0; i < length; i++) {
    final left = i < installedParts.length ? installedParts[i] : 0;
    final right = i < requiredParts.length ? requiredParts[i] : 0;
    if (left != right) return left.compareTo(right);
  }

  return installedVersion.buildNumber.compareTo(requiredVersion.buildNumber);
}

bool isVersionLowerThan(String installed, String required) {
  return compareVersions(installed, required) < 0;
}

class _FlutterVersion {
  const _FlutterVersion({
    required this.nameParts,
    required this.buildNumber,
  });

  final List<int> nameParts;
  final int buildNumber;

  static _FlutterVersion parse(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      throw FormatException('Version Flutter invalida', value);
    }

    final splitBuild = clean.split('+');
    if (splitBuild.length > 2) {
      throw FormatException('Version Flutter invalida', value);
    }

    final namePartsRaw = splitBuild.first.split('.');
    if (namePartsRaw.length != 3 || !namePartsRaw.every(_isNumeric)) {
      throw FormatException('Version Flutter invalida', value);
    }

    final buildRaw = splitBuild.length == 2 ? splitBuild[1] : '0';
    if (!_isNumeric(buildRaw)) {
      throw FormatException('Version Flutter invalida', value);
    }

    final nameParts = namePartsRaw.map(int.parse).toList();
    final buildNumber = int.parse(buildRaw);

    return _FlutterVersion(
      nameParts: nameParts,
      buildNumber: buildNumber,
    );
  }
}

bool _isNumeric(String value) {
  if (value.isEmpty) return false;
  for (final codeUnit in value.codeUnits) {
    if (codeUnit < 48 || codeUnit > 57) return false;
  }
  return true;
}
