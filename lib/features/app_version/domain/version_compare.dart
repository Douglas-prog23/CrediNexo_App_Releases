int compareVersions(String installed, String required) {
  final installedParts = _parseVersion(installed);
  final requiredParts = _parseVersion(required);
  final length = installedParts.length > requiredParts.length
      ? installedParts.length
      : requiredParts.length;

  for (var i = 0; i < length; i++) {
    final left = i < installedParts.length ? installedParts[i] : 0;
    final right = i < requiredParts.length ? requiredParts[i] : 0;
    if (left != right) return left.compareTo(right);
  }
  return 0;
}

bool isVersionLowerThan(String installed, String required) {
  return compareVersions(installed, required) < 0;
}

List<int> _parseVersion(String value) {
  final clean = value.trim().split('+').first;
  if (clean.isEmpty) return const [0];
  return clean.split('.').map((part) {
    final digits = _leadingDigits(part.trim());
    return int.tryParse(digits) ?? 0;
  }).toList();
}

String _leadingDigits(String value) {
  final buffer = StringBuffer();
  for (final codeUnit in value.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    if (!isDigit) break;
    buffer.writeCharCode(codeUnit);
  }
  return buffer.isEmpty ? '0' : buffer.toString();
}
