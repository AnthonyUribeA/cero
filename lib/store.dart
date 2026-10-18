import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logic.dart';
import 'models.dart';

enum Strategy { avalancha, bolaDeNieve }

class AppStore extends ChangeNotifier {
  /// Si es verdadero, guarda cada cambio en el celular.
  final bool persist;
  AppStore({this.persist = false}) {
    DateTime day(int n) => DateTime(now.year, now.month, n.clamp(1, now.day).toInt());
    expenses.addAll([
      Expense(id: 'e1', kind: ExpenseKind.hormiga, category: 'Delivery', note: 'Pedido', amount: 45, date: day(3), method: 'Yape'),
      Expense(id: 'e2', kind: ExpenseKind.hormiga, category: 'Café', note: 'Café', amount: 32, date: day(5), method: 'Yape'),
      Expense(id: 'e3', kind: ExpenseKind.hormiga, category: 'Snacks', note: 'Snacks', amount: 40, date: day(8), method: 'Efectivo'),
      Expense(id: 'e4', kind: ExpenseKind.hormiga, category: 'Delivery', note: 'Pedido', amount: 43, date: day(10), method: 'Yape'),
      Expense(id: 'e5', kind: ExpenseKind.hormiga, category: 'Café', note: 'Café', amount: 30, date: day(12), method: 'Yape'),
      Expense(id: 'e6', kind: ExpenseKind.hormiga, category: 'Taxi', note: 'Taxi corto', amount: 24, date: day(14), method: 'Efectivo'),
      Expense(id: 'v1', kind: ExpenseKind.variable, category: 'Comida', note: 'Mercado', amount: 640, date: day(4), method: 'Tarjeta'),
      Expense(id: 'v2', kind: ExpenseKind.variable, category: 'Transporte', note: 'Pasajes', amount: 210, date: day(6), method: 'Efectivo'),
      Expense(id: 'v3', kind: ExpenseKind.variable, category: 'Salud', note: 'Farmacia', amount: 85, date: day(9), method: 'Yape'),
    ]);
    _migrate();
    incomes.addAll([
      IncomeItem(id: 'i1', label: 'Aporte de mamá', amount: 500, date: day(14), tag: 'Familia'),
      IncomeItem(id: 'i2', label: 'Trabajo extra', amount: 300, date: day(9), tag: 'Extra'),
    ]);
  }

  String userName = 'Anthony';
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

  final List<FixedBill> fixed = [
    const FixedBill(id: 'f1', name: 'Alquiler', amount: 1800, day: 1),
    const FixedBill(id: 'f2', name: 'Luz', amount: 160, day: 12),
    const FixedBill(id: 'f3', name: 'Agua', amount: 70, day: 15),
    const FixedBill(id: 'f4', name: 'Internet', amount: 110, day: 18),
    const FixedBill(id: 'f5', name: 'Celulares', amount: 180, day: 20),
  ];
  final List<Expense> expenses = [];
  final List<IncomeItem> incomes = [];

  /// Fijos pagados, con la forma "id|año-mes".
  final Set<String> fixedPaid = {};

  /// Tope mensual de gastos hormiga y presupuesto de gastos variables.
  double hormigaCap = 300;
  final Map<String, double> varBudget = {'Comida': 1800, 'Transporte': 600, 'Salud': 300};

  final Set<String> paid = {};
  Strategy strategy = Strategy.avalancha;
  double extra = 0;
  int goalMonths = 18;
  ThemeMode themeMode = ThemeMode.system;

  /// Avisos: 3 días antes, el día, sin marcar, resumen domingo, avisar a los tres, avisar si otro paga.
  final List<bool> alerts = [true, true, true, false, true, true];

  final DateTime now = DateTime.now();
  DateTime get startMonth => DateTime(now.year, now.month);

  double get totalDebt => debts.fold(0.0, (t, d) => t + balanceOf(d));
  int get ymNow => now.year * 12 + now.month - 1;

  void _migrate() {
    for (var i = 0; i < debts.length; i++) {
      if (debts[i].planStart == null) debts[i] = debts[i].copyWith(planStart: ymNow);
    }
  }

  /// Las deudas como están este mes (antes de pagar la cuota del mes).
  List<Debt> get current => [for (final d in debts) d.atMonth(ymNow)];

  bool isPaid(Debt d) => paid.contains('${d.id}|$ymNow');

  /// Saldo de hoy: si ya pagaste la cuota del mes, lo que queda después.
  double balanceOf(Debt d) {
    final c = d.atMonth(ymNow);
    if (!isPaid(d)) return c.balance;
    final rows = c.schedule;
    return rows.isEmpty ? 0 : rows.first.remaining;
  }
  double get totalCuotas => debts.fold(0.0, (s, d) => s + d.paymentFor(ymNow));
  double get totalIncome => people.fold(0.0, (s, p) => s + p.income);
  double get totalInterest => current.fold(0.0, (t, d) => t + d.firstMonthInterest);

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

  String get _ym => '${now.year}-${now.month}';
  bool isFixedPaid(FixedBill f) => fixedPaid.contains('${f.id}|$_ym');

  bool _thisMonth(DateTime d) => d.year == now.year && d.month == now.month;

  List<Expense> monthExpenses(ExpenseKind k) =>
      expenses.where((e) => e.kind == k && _thisMonth(e.date)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double get hormigaSpent => monthExpenses(ExpenseKind.hormiga).fold(0.0, (t, e) => t + e.amount);

  double varSpent(String cat) => monthExpenses(ExpenseKind.variable)
      .where((e) => e.category == cat)
      .fold(0.0, (t, e) => t + e.amount);

  double get fixedTotal => fixed.fold(0.0, (t, f) => t + f.amount);
  double get fixedPaidSum =>
      fixed.where(isFixedPaid).fold(0.0, (t, f) => t + f.amount);
  double get varBudgetTotal => varBudget.values.fold(0.0, (t, v) => t + v);

  double get extraIncomeMonth =>
      incomes.where((i) => _thisMonth(i.date)).fold(0.0, (t, i) => t + i.amount);

  // ---- Resumen del mes ----
  double get incomeMonth => totalIncome + extraIncomeMonth;
  double get cuotasPaid => debts.where(isPaid).fold(0.0, (t, d) => t + d.paymentFor(ymNow));
  double get varSpentTotal => monthExpenses(ExpenseKind.variable).fold(0.0, (t, e) => t + e.amount);

  /// Lo que ya salió este mes: cuotas y fijos pagados, variables y hormiga gastados.
  double get spentSoFar => cuotasPaid + fixedPaidSum + varSpentTotal + hormigaSpent;

  /// Cuotas y fijos que todavía faltan pagar este mes.
  double get pendingDue => (totalCuotas - cuotasPaid) + (fixedTotal - fixedPaidSum);

  /// Lo que tienes hoy después de lo que ya pagaste y gastaste.
  double get availableNow => incomeMonth - spentSoFar;

  /// Lo que te quedaría al cerrar el mes si pagas todo y gastas lo presupuestado.
  double get endOfMonth {
    final varLeft = varBudgetTotal - varSpentTotal;
    final hormLeft = hormigaCap - hormigaSpent;
    return availableNow - pendingDue - (varLeft > 0 ? varLeft : 0) - (hormLeft > 0 ? hormLeft : 0);
  }

  /// Cuánto baja la deuda este mes (capital de las cuotas del mes).
  double get capitalThisMonth => current.fold(0.0, (t, d) {
        final r = d.schedule;
        return t + (r.isEmpty ? 0 : r.first.capital + r.first.extra);
      });

  /// Interés que pagas este mes en cada deuda, de mayor a menor.
  List<(Debt, double)> get interestByDebt {
    final out = <(Debt, double)>[
      for (final d in current)
        (d, d.schedule.isEmpty ? 0.0 : d.schedule.first.interest),
    ]..removeWhere((e) => e.$2 <= 0.005);
    out.sort((a, b) => b.$2.compareTo(a.$2));
    return out;
  }

  double get interestThisMonth => interestByDebt.fold(0.0, (t, e) => t + e.$2);

  /// Lo que queda libre tras cuotas, fijos, variables y el tope de hormiga.
  double get freeMargin =>
      totalIncome + extraIncomeMonth - totalCuotas - fixedTotal - varBudgetTotal - hormigaCap;

  List<String> get order => strategy == Strategy.avalancha
      ? avalancheOrder(current)
      : snowballOrder(current);

  SimResult get plan => simulate(current, order, extra, roll: true, startYm: ymNow);
  SimResult get base => simulate(current, avalancheOrder(current), 0, roll: false, startYm: ymNow);
  double get needForGoal => neededExtra(current, order, goalMonths, startYm: ymNow);

  Debt debtById(String id) => debts.firstWhere((d) => d.id == id);

  void togglePaid(String id) {
    final k = '$id|$ymNow';
    if (!paid.remove(k)) paid.add(k);
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
    goalMonths = m.clamp(3, 60).toInt();
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
    debts.add(d.planStart == null ? d.copyWith(planStart: ymNow) : d);
    notifyListeners();
  }

  void updateDebt(Debt d) {
    final i = debts.indexWhere((x) => x.id == d.id);
    if (i >= 0) debts[i] = d;
    notifyListeners();
  }

  void toggleFixed(FixedBill f) {
    final k = '${f.id}|$_ym';
    if (!fixedPaid.remove(k)) fixedPaid.add(k);
    notifyListeners();
  }

  void addFixed(FixedBill f) {
    fixed.add(f);
    notifyListeners();
  }

  void addExpense(Expense e) {
    expenses.add(e);
    notifyListeners();
  }

  void removeExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void addIncome(IncomeItem i) {
    incomes.add(i);
    notifyListeners();
  }

  void removeIncome(String id) {
    incomes.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void setHormigaCap(double v) {
    hormigaCap = v.clamp(0, 5000).toDouble();
    notifyListeners();
  }

  // ---- Guardado en el celular ----
  static const _key = 'cero_v1';

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'debts': [for (final d in debts) d.toJson()],
        'people': [for (final x in people) x.toJson()],
        'fixed': [for (final f in fixed) f.toJson()],
        'expenses': [for (final e in expenses) e.toJson()],
        'incomes': [for (final i in incomes) i.toJson()],
        'fixedPaid': fixedPaid.toList(),
        'paid': paid.toList(),
        'hormigaCap': hormigaCap,
        'varBudget': varBudget,
        'strategy': strategy.index,
        'extra': extra,
        'goalMonths': goalMonths,
        'themeMode': themeMode.index,
        'alerts': alerts,
      };

  void fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> list(String k) =>
        [for (final x in (j[k] as List? ?? const [])) Map<String, dynamic>.from(x as Map)];
    userName = (j['userName'] as String?) ?? userName;
    final d = list('debts');
    if (d.isNotEmpty) {
      debts
        ..clear()
        ..addAll(d.map(Debt.fromJson));
    }
    final pe = list('people');
    if (pe.isNotEmpty) {
      people
        ..clear()
        ..addAll(pe.map(Person.fromJson));
    }
    if (j.containsKey('fixed')) {
      fixed
        ..clear()
        ..addAll(list('fixed').map(FixedBill.fromJson));
    }
    if (j.containsKey('expenses')) {
      expenses
        ..clear()
        ..addAll(list('expenses').map(Expense.fromJson));
    }
    if (j.containsKey('incomes')) {
      incomes
        ..clear()
        ..addAll(list('incomes').map(IncomeItem.fromJson));
    }
    _migrate();
    fixedPaid
      ..clear()
      ..addAll([for (final x in (j['fixedPaid'] as List? ?? const [])) x as String]);
    paid
      ..clear()
      ..addAll([for (final x in (j['paid'] as List? ?? const [])) x as String]);
    hormigaCap = (j['hormigaCap'] as num?)?.toDouble() ?? hormigaCap;
    final vb = j['varBudget'];
    if (vb is Map) {
      varBudget
        ..clear()
        ..addAll({for (final e in vb.entries) e.key as String: (e.value as num).toDouble()});
    }
    strategy = Strategy.values[(j['strategy'] as int?) ?? strategy.index];
    extra = (j['extra'] as num?)?.toDouble() ?? extra;
    goalMonths = (j['goalMonths'] as int?) ?? goalMonths;
    themeMode = ThemeMode.values[(j['themeMode'] as int?) ?? themeMode.index];
    final al = j['alerts'];
    if (al is List && al.length == alerts.length) {
      for (var i = 0; i < alerts.length; i++) {
        alerts[i] = al[i] as bool;
      }
    }
  }

  /// Lee lo guardado en el celular, si hay algo.
  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_key);
      if (raw == null) return;
      fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      super.notifyListeners();
    } catch (_) {
      // Si no se puede leer, se queda con los datos de ejemplo.
    }
  }

  Future<void> _save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_key, jsonEncode(toJson()));
    } catch (_) {
      // Guardar es un extra: si falla, la app sigue funcionando.
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (persist) _save();
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
