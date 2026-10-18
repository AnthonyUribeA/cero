import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cero/export.dart';
import 'package:cero/store.dart';

void main() {
  test('el Excel trae las cuatro hojas con sus filas', () {
    final s = AppStore();
    final bytes = buildWorkbook(s);
    expect(bytes, isNotNull);
    final x = Excel.decodeBytes(bytes!);
    expect(x.tables.keys, containsAll(['Resumen', 'Deudas', 'Aportes', 'Calendario']));
    // encabezado + 6 deudas + total
    expect(x['Deudas'].maxRows, 8);
    // encabezado + 3 personas + total
    expect(x['Aportes'].maxRows, 5);
    // encabezado + 24 meses
    expect(x['Calendario'].maxRows, 25);
  });

  test('el calendario termina en cero', () {
    final s = AppStore();
    final rows = s.plan.rows;
    expect(rows.length, 24);
    expect(rows.last.remaining, lessThan(1));
  });
}
