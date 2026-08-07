import 'package:intl/intl.dart';

final _date = DateFormat('dd/MM/yyyy');

String dateFormat(dynamic value) {
  if (value == null) return '-';
  final parsed = value is DateTime ? value : DateTime.tryParse('$value');
  if (parsed == null) return '$value';
  return _date.format(parsed);
}

String todayLocalIso() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
