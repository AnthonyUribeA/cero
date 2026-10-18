import 'dart:math' as math;

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
  });

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
  final String name;
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
