import 'package:flutter_test/flutter_test.dart';
import 'package:cero/loan.dart';

void main() {
  test('30 mil al 5% mensual en 10 meses: cuota de S/ 3,885', () {
    final c = amortCuota(30000, 0.05, 10);
    expect(c, closeTo(3885.14, 0.05));
    expect(c * 10 - 30000, closeTo(8851.37, 0.5));
  });

  test('con esa cuota se paga en 10 meses', () {
    expect(monthsToPay(30000, 0.05, 3885.14), 10);
  });

  test('si la cuota solo cubre el interés, nunca termina', () {
    expect(monthsToPay(30000, 0.05, 1500), -1);
  });

  test('la tasa que cobra el banco sale de la cuota y el plazo', () {
    final r = impliedRate(30000, 3885.14, 10);
    expect(r, closeTo(0.05, 0.0001));
  });

  test('después de pagar todas las cuotas no se debe nada', () {
    expect(balanceAfter(30000, 0.05, 10, 10), 0);
    expect(balanceAfter(30000, 0.05, 10, 0), closeTo(30000, 0.5));
  });

  test('TEA y tasa mensual son equivalentes', () {
    expect(teaOf(monthlyOf(0.32)), closeTo(0.32, 1e-9));
  });
}
