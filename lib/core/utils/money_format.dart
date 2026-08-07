import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'en_US', symbol: r'$');

String moneyFormat(num? value) => _money.format(value ?? 0);
