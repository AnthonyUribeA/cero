import 'package:flutter_test/flutter_test.dart';
import 'package:cero/logic.dart';
import 'package:cero/store.dart';

void main() {
  final s = AppStore();

  test('solo cuotas con la deuda que termina pasando su cuota: 24 meses', () {
    final r = simulate(s.debts, avalancheOrder(s.debts), 0, roll: true);
    expect(r.months, 24);
    expect(r.interest, 79156);
  });

  test('con S/ 500 extra se termina un mes antes y se paga menos', () {
    final r = simulate(s.debts, avalancheOrder(s.debts), 500, roll: true);
    expect(r.months, 23);
    expect(r.interest, 71244);
  });

  test('para terminar en 18 meses hace falta un extra de S/ 2,200', () {
    expect(neededExtra(s.debts, avalancheOrder(s.debts), 18), 2200);
  });

  test('solo pagando las cuotas, sin pasar la cuota: 50 meses', () {
    final r = simulate(s.debts, avalancheOrder(s.debts), 0, roll: false);
    expect(r.months, 50);
    expect(r.interest, 113115);
  });

  test('el reparto entre tres suma exactamente las cuotas', () {
    final c = s.contributions(s.totalCuotas);
    expect(c.fold<double>(0, (a, b) => a + b), s.totalCuotas);
  });
}
