import 'package:credinexo/core/utils/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dateFormat', () {
    test('muestra timestamps UTC con la fecha de El Salvador', () {
      expect(dateFormat('2026-11-24T00:30:00.000Z'), '23/11/2026');
    });

    test('no desplaza fechas de calendario sin hora', () {
      expect(dateFormat('2026-11-24'), '24/11/2026');
    });
  });
}
