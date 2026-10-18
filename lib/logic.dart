import 'dart:math' as math;
import 'models.dart';

/// Una fila del calendario mes a mes.
class MonthRow {
  final int month;
  final double payment;
  final double interest;
  final double remaining;
  const MonthRow(this.month, this.payment, this.interest, this.remaining);
}

class SimResult {
  final int months;
  final int interest;

  /// Mes (1 = este mes) en que se termina cada deuda.
  final Map<String, int> close;

  /// Intereses totales que se pagarán en cada deuda.
  final Map<String, int> interestBy;

  /// Calendario: pago, intereses y saldo que queda al cerrar cada mes.
  final List<MonthRow> rows;

  const SimResult(this.months, this.interest, this.close, this.interestBy,
      [this.rows = const []]);
}

class _Live {
  final Debt d;
  double bal;
  _Live(this.d) : bal = d.balance;
}

/// Simula mes a mes. Si [roll] es verdadero, cuando una deuda termina su cuota
/// pasa a la siguiente del [order] y el pago total mensual no baja.
SimResult simulate(
  List<Debt> debts,
  List<String> order,
  double extra, {
  required bool roll,
  int? startYm,
}) {
  final live = debts.map((d) => _Live(d)).toList();
  double budget = extra;
  for (final d in debts) {
    budget += startYm == null ? d.cuota : d.paymentFor(startYm);
  }
  int months = 0;
  double interest = 0;
  final close = <String, int>{};
  final by = <String, double>{};
  final rows = <MonthRow>[];

  while (live.any((l) => l.bal > 0.5) && months < 600) {
    months += 1;
    double spent = 0;
    final before = live.fold<double>(0, (t, l) => t + l.bal);
    double monthInterest = 0;
    for (final l in live) {
      if (l.bal > 0) {
        final i = l.bal * l.d.monthlyRate;
        l.bal += i;
        interest += i;
        monthInterest += i;
        by[l.d.id] = (by[l.d.id] ?? 0) + i;
        final due = startYm == null ? l.d.cuota : l.d.paymentFor(startYm + months - 1);
        final pay = math.min(due, l.bal);
        l.bal -= pay;
        spent += pay;
      }
    }
    if (roll || extra > 0) {
      double left = roll ? budget - spent : extra;
      for (final id in order) {
        final l = live.firstWhere((x) => x.d.id == id);
        if (l.bal > 0 && left > 0) {
          final pay = math.min(left, l.bal);
          l.bal -= pay;
          left -= pay;
        }
      }
    }
    for (final l in live) {
      if (l.bal <= 0.5 && !close.containsKey(l.d.id)) {
        close[l.d.id] = months;
      }
    }
    final after = live.fold<double>(0, (t, l) => t + (l.bal > 0.5 ? l.bal : 0));
    rows.add(MonthRow(months, before + monthInterest - after, monthInterest, after));
  }
  return SimResult(
    months,
    interest.round(),
    close,
    by.map((k, v) => MapEntry(k, v.round())),
    rows,
  );
}

/// Más intereses primero.
List<String> avalancheOrder(List<Debt> ds) {
  final idx = <String, int>{for (var i = 0; i < ds.length; i++) ds[i].id: i};
  final l = [...ds];
  l.sort((a, b) {
    final c = b.monthlyRate.compareTo(a.monthlyRate);
    return c != 0 ? c : idx[a.id]!.compareTo(idx[b.id]!);
  });
  return l.map((d) => d.id).toList();
}

/// La más chica primero.
List<String> snowballOrder(List<Debt> ds) {
  final idx = <String, int>{for (var i = 0; i < ds.length; i++) ds[i].id: i};
  final l = [...ds];
  l.sort((a, b) {
    final c = a.balance.compareTo(b.balance);
    return c != 0 ? c : idx[a.id]!.compareTo(idx[b.id]!);
  });
  return l.map((d) => d.id).toList();
}

/// Extra mensual (de a S/ 50) que hace falta para terminar en [goalMonths].
double neededExtra(List<Debt> debts, List<String> order, int goalMonths, {int? startYm}) {
  double need = 0;
  while (need < 12000 &&
      simulate(debts, order, need, roll: true, startYm: startYm).months > goalMonths) {
    need += 50;
  }
  return need;
}
