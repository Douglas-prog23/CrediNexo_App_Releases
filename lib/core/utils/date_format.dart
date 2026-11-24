import 'package:intl/intl.dart';

final _date = DateFormat('dd/MM/yyyy');
const _elSalvadorUtcOffset = Duration(hours: 6);

DateTime nowElSalvador() {
  final value = DateTime.now().toUtc().subtract(_elSalvadorUtcOffset);
  return DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
}

String dateFormat(dynamic value) {
  if (value == null) return '-';
  final raw = '$value'.trim();
  if (raw.isEmpty) return '-';

  // Las fechas de calendario no llevan zona horaria y no deben desplazarse.
  final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (dateOnly != null) {
    return _date.format(DateTime(
      int.parse(dateOnly.group(1)!),
      int.parse(dateOnly.group(2)!),
      int.parse(dateOnly.group(3)!),
    ));
  }

  final parsed = value is DateTime ? value : DateTime.tryParse(raw);
  if (parsed == null) return '$value';
  final local = parsed.isUtc
      ? parsed.subtract(_elSalvadorUtcOffset)
      : parsed;
  return _date.format(local);
}

String todayLocalIso() {
  final now = nowElSalvador();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
