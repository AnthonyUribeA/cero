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
}
