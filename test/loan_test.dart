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

  test('100 al 5% en 10 meses con capital fijo: 15, 14.50... y S/ 27.50 de interés', () {
    final rows = buildSchedule(balance: 100, r: 0.05, method: 1, term: 10);
    expect(rows.length, 10);
    expect(rows[0].pay, closeTo(15, 1e-9));
    expect(rows[1].pay, closeTo(14.5, 1e-9));
    expect(rows.last.pay, closeTo(10.5, 1e-9));
    expect(scheduleInterest(rows), closeTo(27.5, 1e-9));
  });

  test('100 al 5% en 10 meses con cuota fija: S/ 29.50 de interés', () {
    final rows = buildSchedule(balance: 100, r: 0.05, method: 0, term: 10);
    expect(rows.length, 10);
    expect(rows[0].interest, closeTo(5, 1e-9));
    expect(scheduleInterest(rows), closeTo(29.50, 0.01));
  });

  test('solo interés: 5 al mes y el capital al final', () {
    final rows = buildSchedule(balance: 100, r: 0.05, method: 2, term: 10);
    expect(rows.length, 10);
    expect(rows.first.pay, closeTo(5, 1e-9));
    expect(rows.last.pay, closeTo(105, 1e-9));
  });

  test('un adelanto de capital acorta el plazo y baja el interés', () {
    final base = buildSchedule(balance: 30000, r: 0.05, method: 0, term: 10);
    final con = buildSchedule(balance: 30000, r: 0.05, method: 0, term: 10, extras: {1: 5000});
    expect(con.length, lessThan(base.length));
    expect(scheduleInterest(con), lessThan(scheduleInterest(base)));
    expect(con[1].extra, 5000);
  });

  test('TEA y tasa mensual son equivalentes', () {
    expect(teaOf(monthlyOf(0.32)), closeTo(0.32, 1e-9));
  });
}
