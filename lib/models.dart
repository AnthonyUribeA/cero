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
  });

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
}
