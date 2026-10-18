import 'package:flutter/material.dart';
import 'logic.dart';
import 'models.dart';

enum Strategy { avalancha, bolaDeNieve }

class AppStore extends ChangeNotifier {
  // Datos de ejemplo. Se reemplazan con los reales desde la app.
  final List<Debt> debts = [
    const Debt(id: 'p2', name: 'Prestamista 2', kind: DebtKind.prestamista, owner: Owner.pareja, balance: 15000, rateKind: RateKind.mensual, rate: 0.06, cuota: 1500, payDay: 22),
    const Debt(id: 'p1', name: 'Prestamista 1', kind: DebtKind.prestamista, owner: Owner.tu, balance: 25000, rateKind: RateKind.mensual, rate: 0.05, cuota: 2500, payDay: 20),
    const Debt(id: 'tj', name: 'Tarjeta Banco A', kind: DebtKind.banco, owner: Owner.persona3, balance: 38000, rateKind: RateKind.tea, rate: 0.68, cuota: 1900, payDay: 25),
    const Debt(id: 'bb', name: 'Préstamo Banco B', kind: DebtKind.banco, owner: Owner.varios, balance: 52000, rateKind: RateKind.tea, rate: 0.32, cuota: 2150, payDay: 28),
    const Debt(id: 'co', name: 'Cooperativa', kind: DebtKind.otro, owner: Owner.pareja, balance: 38000, rateKind: RateKind.mensual, rate: 0.02, cuota: 1800, payDay: 30),
    const Debt(id: 'el', name: 'Electrodoméstico', kind: DebtKind.cuota, owner: Owner.persona3, balance: 12000, rateKind: RateKind.ninguna, rate: 0, cuota: 1000, payDay: 5),
  ];

  final List<Person> people = [
    Person(name: 'Tú', short: 'Tú', payDay: 30, income: 6000),
    Person(name: 'Tu pareja', short: 'Pareja', payDay: 15, income: 6000),
    Person(name: 'Persona 3', short: 'Persona 3', payDay: 5, income: 6000),
  ];

  final Set<String> paid = {};
  Strategy strategy = Strategy.avalancha;
  double extra = 0;
  int goalMonths = 18;
  ThemeMode themeMode = ThemeMode.system;

  /// Avisos: 3 días antes, el día, sin marcar, resumen domingo, avisar a los tres, avisar si otro paga.
  final List<bool> alerts = [true, true, true, false, true, true];

  final DateTime now = DateTime.now();
  DateTime get startMonth => DateTime(now.year, now.month);

  double get totalDebt => debts.fold(0.0, (s, d) => s + d.balance);
  double get totalCuotas => debts.fold(0.0, (s, d) => s + d.cuota);
  double get totalIncome => people.fold(0.0, (s, p) => s + p.income);
  double get totalInterest => debts.fold(0.0, (s, d) => s + d.firstMonthInterest);

  /// Lo que aporta cada persona: las cuotas repartidas según el sueldo.
  List<double> contributions(double amount) {
    final total = totalIncome;
    final out = <double>[];
    if (people.isEmpty) return out;
    for (var i = 0; i < people.length; i++) {
      out.add(total > 0
          ? (amount * people[i].income / total).roundToDouble()
          : (amount / people.length).roundToDouble());
    }
    // El último ajusta la diferencia para que la suma sea exacta.
    final others = out.take(out.length - 1).fold(0.0, (s, v) => s + v);
    out[out.length - 1] = amount - others;
    return out;
  }

  List<String> get order => strategy == Strategy.avalancha
      ? avalancheOrder(debts)
      : snowballOrder(debts);

  SimResult get plan => simulate(debts, order, extra, roll: true);
  SimResult get base => simulate(debts, avalancheOrder(debts), 0, roll: false);
  double get needForGoal => neededExtra(debts, order, goalMonths);

  Debt debtById(String id) => debts.firstWhere((d) => d.id == id);

  void togglePaid(String id) {
    if (!paid.remove(id)) paid.add(id);
    notifyListeners();
  }

  void setStrategy(Strategy s) {
    strategy = s;
    notifyListeners();
  }

  void setExtra(double v) {
    extra = v.clamp(0, 8000).toDouble();
    notifyListeners();
  }

  void setGoal(int m) {
    goalMonths = m.clamp(6, 24).toInt();
    notifyListeners();
  }

  void setIncome(int i, double v) {
    people[i].income = v.clamp(0, 30000).toDouble();
    notifyListeners();
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    notifyListeners();
  }

  void setAlert(int i, bool v) {
    alerts[i] = v;
    notifyListeners();
  }

  void addDebt(Debt d) {
    debts.add(d);
    notifyListeners();
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
