import 'package:flutter_test/flutter_test.dart';
import 'package:cero/models.dart';
import 'package:cero/store.dart';

void main() {
  test('el margen libre descuenta cuotas, fijos, variables y hormiga', () {
    final s = AppStore();
    final esperado = s.totalIncome + s.extraIncomeMonth - s.totalCuotas - s.fixedTotal -
        s.varBudgetTotal - s.hormigaCap;
    expect(s.freeMargin, esperado);
    expect(s.fixedTotal, 2320);
    expect(s.varBudgetTotal, 2700);
  });

  test('los gastos hormiga del mes suman 214', () {
    final s = AppStore();
    expect(s.hormigaSpent, 214);
  });

  test('un gasto nuevo se suma y se puede borrar', () {
    final s = AppStore();
    final antes = s.hormigaSpent;
    s.addExpense(Expense(
      id: 'z1',
      kind: ExpenseKind.hormiga,
      category: 'Café',
      note: 'Café',
      amount: 10,
      date: DateTime(s.now.year, s.now.month, s.now.day),
      method: 'Yape',
    ));
    expect(s.hormigaSpent, antes + 10);
    s.removeExpense('z1');
    expect(s.hormigaSpent, antes);
  });

  test('marcar un fijo como pagado cambia el total pagado', () {
    final s = AppStore();
    expect(s.fixedPaidSum, 0);
    s.toggleFixed(s.fixed.first);
    expect(s.fixedPaidSum, s.fixed.first.amount);
  });

  test('lo guardado se puede volver a leer', () {
    final a = AppStore();
    a.addFixed(const FixedBill(id: 'fx', name: 'Gas', amount: 50, day: 7));
    a.setHormigaCap(450);
    final b = AppStore();
    b.fromJson(a.toJson());
    expect(b.fixed.length, a.fixed.length);
    expect(b.hormigaCap, 450);
    expect(b.debts.length, a.debts.length);
    expect(b.expenses.length, a.expenses.length);
  });

  test('los adelantos aplicados cambian el pago de ese mes y se guardan', () {
    final s = AppStore();
    final d = s.debts.first;
    final start = s.ymNow;
    s.updateDebt(d.copyWith(extras: {0: 1000}, planStart: start));
    final nd = s.debtById(d.id);
    expect(nd.paymentFor(start), closeTo(d.cuota + 1000, 0.01));
    final b = AppStore();
    b.fromJson(s.toJson());
    expect(b.debtById(d.id).extras[0], 1000);
    expect(b.debtById(d.id).planStart, start);
  });

  test('pagar la cuota del mes baja el saldo y queda marcada solo este mes', () {
    final s = AppStore();
    final d = s.debts.first;
    final antes = s.balanceOf(d);
    s.togglePaid(d.id);
    expect(s.isPaid(d), isTrue);
    expect(s.balanceOf(d), lessThan(antes));
    expect(s.paid.single, '${d.id}|${s.ymNow}');
  });

  test('al mes siguiente la deuda empieza con el saldo que quedó', () {
    final s = AppStore();
    final d = s.debts.first;
    final next = d.atMonth(s.ymNow + 1);
    expect(next.balance, closeTo(d.schedule.first.remaining, 0.01));
  });

  test('resumen: disponible hoy y al cierre del mes cuadran', () {
    final s = AppStore();
    // Sin nada pagado: disponible = ingresos - gastos ya anotados.
    expect(s.availableNow, closeTo(s.incomeMonth - s.varSpentTotal - s.hormigaSpent, 0.01));
    // Si no te pasas del presupuesto, al cierre te queda el margen libre.
    expect(s.endOfMonth, closeTo(s.freeMargin, 0.01));
    final antes = s.availableNow;
    s.togglePaid(s.debts.first.id);
    expect(s.availableNow, closeTo(antes - s.debts.first.paymentFor(s.ymNow), 0.01));
    expect(s.endOfMonth, closeTo(s.freeMargin, 0.01));
  });

  test('interés del mes: suma de cada deuda y cuadra con la cuota', () {
    final s = AppStore();
    // Con los datos de ejemplo, el primer mes se pagan unos S/ 5,806 de interés.
    expect(s.interestThisMonth, closeTo(5806, 2));
    expect(s.interestThisMonth + s.capitalThisMonth, closeTo(s.totalCuotas, 1));
    expect(s.interestByDebt.first.$2, greaterThanOrEqualTo(s.interestByDebt.last.$2));
  });

  test('empezar de cero deja la app vacía y pide los datos', () {
    final s = AppStore();
    expect(s.needsSetup, isFalse);
    s.resetAll();
    expect(s.debts, isEmpty);
    expect(s.fixed, isEmpty);
    expect(s.totalIncome, 0);
    expect(s.needsSetup, isTrue);
    expect(s.plan.months, 0);
    expect(s.freeMargin, 0);
  });

  test('editar y borrar un gasto fijo', () {
    final s = AppStore();
    final f = s.fixed.first;
    s.updateFixed(FixedBill(id: f.id, name: 'Alquiler nuevo', amount: 2000, day: 3));
    expect(s.fixed.first.amount, 2000);
    s.removeFixed(f.id);
    expect(s.fixed.any((x) => x.id == f.id), isFalse);
  });
}
