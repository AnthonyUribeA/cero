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
}
