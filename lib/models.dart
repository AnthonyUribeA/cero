import 'dart:math' as math;
import 'loan.dart';

enum Owner { tu, pareja, persona3, varios }

extension OwnerX on Owner {
  String get label {
    switch (this) {
      case Owner.tu:
        return 'Tú';
      case Owner.pareja:
        return 'Pareja';
      case Owner.persona3:
        return 'Persona 3';
      case Owner.varios:
        return 'Varios';
    }
  }
}

enum DebtKind { banco, prestamista, tarjeta, cuota, otro }

extension DebtKindX on DebtKind {
  String get label {
    switch (this) {
      case DebtKind.banco:
        return 'Banco';
      case DebtKind.prestamista:
        return 'Prestamista';
      case DebtKind.tarjeta:
        return 'Tarjeta';
      case DebtKind.cuota:
        return 'Cuota';
      case DebtKind.otro:
        return 'Otro';
    }
  }
}

/// Cómo se expresa la tasa: mensual, anual (TEA) o sin interés.
enum RateKind { mensual, tea, ninguna }

enum RateLevel { alta, media, ninguna }

class Debt {
  final String id;
  final String name;
  final DebtKind kind;
  final Owner owner;
  final double balance;
  final RateKind rateKind;

  /// Tasa como fracción: 0.05 es 5%.
  final double rate;
  final double cuota;
  final int payDay;

  /// Opcional: monto que te prestaron, número total de cuotas y cuántas ya pagaste.
  final double? principal;
  final int? termMonths;
  final int? paidCount;

  /// Forma de pago (ver payMethodNames), adelantos de capital por mes y mes
  /// (año * 12 + mes - 1) del primer pago del cronograma. Sin [planStart], la
  /// deuda se paga con [cuota] fija todos los meses.
  final int method;
  final Map<int, double> extras;
  final int? planStart;

  const Debt({
    required this.id,
    required this.name,
    required this.kind,
    required this.owner,
    required this.balance,
    required this.rateKind,
    required this.rate,
    required this.cuota,
    required this.payDay,
    this.principal,
    this.termMonths,
    this.paidCount,
    this.method = 0,
    this.extras = const {},
    this.planStart,
  });

  Debt copyWith({Map<int, double>? extras, int? planStart, int? method, double? cuota}) => Debt(
        id: id,
        name: name,
        kind: kind,
        owner: owner,
        balance: balance,
        rateKind: rateKind,
        rate: rate,
        cuota: cuota ?? this.cuota,
        payDay: payDay,
        principal: principal,
        termMonths: termMonths,
        paidCount: paidCount,
        method: method ?? this.method,
        extras: extras ?? this.extras,
        planStart: planStart ?? this.planStart,
      );

  /// Cómo queda la deuda al empezar el mes [ym], suponiendo pagados los meses
  /// anteriores del cronograma.
  Debt atMonth(int ym) {
    if (planStart == null || ym <= planStart!) return this;
    final off = ym - planStart!;
    final rows = schedule;
    final bal = off <= rows.length ? rows[off - 1].remaining : 0.0;
    return Debt(
      id: id,
      name: name,
      kind: kind,
      owner: owner,
      balance: bal,
      rateKind: rateKind,
      rate: rate,
      cuota: cuota,
      payDay: payDay,
      principal: principal,
      termMonths: termMonths,
      paidCount: termMonths == null ? paidCount : (paidCount ?? 0) + off,
      method: method,
      extras: {for (final e in extras.entries) if (e.key >= off) e.key - off: e.value},
      planStart: ym,
    );
  }

  /// Cuotas que faltan según el plazo, si se conoce.
  int? get remainingTerm => termMonths == null ? null : termMonths! - (paidCount ?? 0);

  /// Cronograma completo desde [planStart].
  List<SchedRow> get schedule => buildSchedule(
        balance: balance,
        r: monthlyRate,
        method: method,
        cuota: cuota,
        term: remainingTerm,
        extras: extras,
      );

  /// Lo que toca pagar en el mes [ym] (año * 12 + mes - 1). 0 si ya terminó.
  double paymentFor(int ym) {
    if (planStart == null) return cuota;
    final idx = ym - planStart!;
    if (idx < 0) return 0;
    final rows = schedule;
    return idx < rows.length ? rows[idx].pay : 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.index,
        'owner': owner.index,
        'balance': balance,
        'rateKind': rateKind.index,
        'rate': rate,
        'cuota': cuota,
        'payDay': payDay,
        if (principal != null) 'principal': principal,
        if (termMonths != null) 'termMonths': termMonths,
        if (paidCount != null) 'paidCount': paidCount,
        'method': method,
        if (extras.isNotEmpty) 'extras': {for (final e in extras.entries) '${e.key}': e.value},
        if (planStart != null) 'planStart': planStart,
      };

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: DebtKind.values[j['kind'] as int],
        owner: Owner.values[j['owner'] as int],
        balance: (j['balance'] as num).toDouble(),
        rateKind: RateKind.values[j['rateKind'] as int],
        rate: (j['rate'] as num).toDouble(),
        cuota: (j['cuota'] as num).toDouble(),
        payDay: j['payDay'] as int,
        principal: (j['principal'] as num?)?.toDouble(),
        termMonths: j['termMonths'] as int?,
        paidCount: j['paidCount'] as int?,
        method: (j['method'] as int?) ?? 0,
        extras: {
          for (final e in ((j['extras'] as Map?) ?? const {}).entries)
            int.parse(e.key as String): (e.value as num).toDouble()
        },
        planStart: j['planStart'] as int?,
      );

  double get monthlyRate {
    switch (rateKind) {
      case RateKind.mensual:
        return rate;
      case RateKind.tea:
        return math.pow(1 + rate, 1 / 12).toDouble() - 1;
      case RateKind.ninguna:
        return 0;
    }
  }

  double get annualRate => math.pow(1 + monthlyRate, 12).toDouble() - 1;

  RateLevel get level {
    if (monthlyRate <= 0) return RateLevel.ninguna;
    return annualRate >= 0.6 ? RateLevel.alta : RateLevel.media;
  }

  String get rateLabel {
    switch (rateKind) {
      case RateKind.mensual:
        return '${_pct(rate)}% mensual';
      case RateKind.tea:
        return 'TEA ${_pct(rate)}%';
      case RateKind.ninguna:
        return 'Sin interés';
    }
  }

  /// Interés que se cobra el primer mes.
  double get firstMonthInterest => balance * monthlyRate;
}

String _pct(double v) {
  final p = v * 100;
  return p == p.roundToDouble() ? p.round().toString() : p.toStringAsFixed(1);
}

class Person {
  String name;
  final String short;
  final int payDay;
  double income;

  Person({
    required this.name,
    required this.short,
    required this.payDay,
    required this.income,
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'short': short, 'payDay': payDay, 'income': income};

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        name: j['name'] as String,
        short: j['short'] as String,
        payDay: j['payDay'] as int,
        income: (j['income'] as num).toDouble(),
      );
}

/// Gasto fijo del mes: alquiler, luz, agua, internet...
class FixedBill {
  final String id;
  final String name;
  final double amount;
  final int day;

  const FixedBill({required this.id, required this.name, required this.amount, required this.day});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'amount': amount, 'day': day};

  factory FixedBill.fromJson(Map<String, dynamic> j) => FixedBill(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        day: j['day'] as int,
      );
}

enum ExpenseKind { variable, hormiga }

const hormigaCats = ['Delivery', 'Café', 'Snacks', 'Taxi', 'Otros'];
const variableCats = ['Comida', 'Transporte', 'Salud', 'Otros'];
const payMethods = ['Yape', 'Efectivo', 'Tarjeta'];

/// Un gasto anotado: variable (comida, transporte) o hormiga (café, snacks).
class Expense {
  final String id;
  final ExpenseKind kind;
  final String category;
  final String note;
  final double amount;
  final DateTime date;
  final String method;

  const Expense({
    required this.id,
    required this.kind,
    required this.category,
    required this.note,
    required this.amount,
    required this.date,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.index,
        'category': category,
        'note': note,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'method': method,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        kind: ExpenseKind.values[j['kind'] as int],
        category: j['category'] as String,
        note: j['note'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
        method: j['method'] as String,
      );
}

/// Ingreso extra: un aporte de la familia, un trabajo aparte...
class IncomeItem {
  final String id;
  final String label;
  final double amount;
  final DateTime date;
  final String tag;

  const IncomeItem({
    required this.id,
    required this.label,
    required this.amount,
    required this.date,
    required this.tag,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'tag': tag,
      };

  factory IncomeItem.fromJson(Map<String, dynamic> j) => IncomeItem(
        id: j['id'] as String,
        label: j['label'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
        tag: j['tag'] as String,
      );
}
