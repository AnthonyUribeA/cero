import 'package:flutter/material.dart';
import 'cronograma.dart';
import '../format.dart';
import '../loan.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

/// Resultado del cálculo antes de guardar.
/// Soles con céntimos para montos chicos, sin céntimos para montos grandes.
String _m(double v) {
  if (v.abs() >= 1000) return money(v);
  final neg = v < 0;
  return '${neg ? '−' : ''}S/ ${v.abs().toStringAsFixed(2)}';
}

class _Preview {
  final double balance;
  final double cuota;
  final double rate; // como se guarda (mensual o TEA)
  final RateKind rateKind;
  final int? months; // meses que faltan; null si nunca termina
  final double interest; // interés que falta pagar
  final String? warn;
  final int? term;
  final int? paidCount;
  final double baseCuota; // cuota que se guarda
  final double? lastPay;
  final double total;
  const _Preview({
    required this.balance,
    required this.cuota,
    required this.rate,
    required this.rateKind,
    required this.months,
    required this.interest,
    this.warn,
    this.term,
    this.paidCount,
    double? baseCuota,
    this.lastPay,
    double? total,
  })  : baseCuota = baseCuota ?? cuota,
        total = total ?? 0;
}

class AgregarScreen extends StatefulWidget {
  const AgregarScreen({super.key});

  @override
  State<AgregarScreen> createState() => _AgregarScreenState();
}

class _AgregarScreenState extends State<AgregarScreen> {
  final name = TextEditingController();
  final amount = TextEditingController();
  final rate = TextEditingController();
  final cuota = TextEditingController();
  final count = TextEditingController();

  DebtKind kind = DebtKind.prestamista;
  Owner owner = Owner.tu;
  bool rateMonthly = true;
  int method = 0;
  Map<int, double> extras = {};
  int plazo = 10;
  int paid = 0;
  int day = 15;

  static const _kinds = [
    (DebtKind.prestamista, 'Prestamista'),
    (DebtKind.banco, 'Banco'),
    (DebtKind.tarjeta, 'Tarjeta'),
    (DebtKind.cuota, 'En cuotas'),
  ];

  @override
  void dispose() {
    for (final c in [name, amount, rate, cuota, count]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').replaceAll(' ', '')) ?? 0;

  int get _count => _num(count).round();

  double get _monthlyRate {
    final v = _num(rate) / 100;
    if (v <= 0) return 0;
    return rateMonthly ? v : monthlyOf(v);
  }

  /// Interés total pagando [c] al mes, mes a mes.
  (int, double) _payoff(double p, double r, double c) {
    var bal = p;
    var m = 0;
    var interest = 0.0;
    while (bal > 0.5 && m < 600) {
      final i = bal * r;
      interest += i;
      bal = bal + i - c;
      m++;
      if (c <= i) return (-1, interest);
    }
    return (m, interest);
  }

  int _startYm(AppStore s) {
    final d = nextDue(day, s.now);
    return d.year * 12 + d.month - 1;
  }

  _Preview? _preview() {
    final p = _num(amount);
    if (p <= 0) return null;
    switch (kind) {
      case DebtKind.prestamista:
      case DebtKind.otro:
        final r = _monthlyRate;
        final rk = r <= 0 ? RateKind.ninguna : (rateMonthly ? RateKind.mensual : RateKind.tea);
        final stored = r <= 0 ? 0.0 : _num(rate) / 100;
        final fixed = amortCuota(p, r, plazo);
        final rows = buildSchedule(
            balance: p, r: r, method: method, cuota: method == 0 ? fixed : null, term: plazo, extras: extras);
        if (rows.isEmpty) return null;
        return _Preview(
          balance: p,
          cuota: rows.first.pay - rows.first.extra,
          baseCuota: method == 0 ? fixed : rows.first.pay - rows.first.extra,
          rate: stored,
          rateKind: rk,
          months: rows.length,
          interest: scheduleInterest(rows),
          total: rows.fold(0.0, (t, x) => t + x.pay),
          lastPay: rows.last.pay,
          term: plazo,
          warn: r <= 0
              ? 'Falta la tasa de interés: sin ella se calcula como si no cobrara interés.'
              : (method == 2 ? 'Cada mes pagas solo el interés y el último mes devuelves todo el capital.' : null),
        );
      case DebtKind.banco:
        final c = _num(cuota);
        final n = _count;
        if (c <= 0 || n <= 0) return null;
        final k = paid.clamp(0, n).toInt();
        final r = impliedRate(p, c, n);
        final bal = balanceAfter(p, r, n, k);
        final rows = buildSchedule(balance: bal, r: r, method: 0, cuota: c, term: n - k, extras: extras);
        return _Preview(
          balance: bal,
          cuota: c,
          rate: r <= 0 ? 0 : teaOf(r),
          rateKind: r <= 0 ? RateKind.ninguna : RateKind.tea,
          months: rows.length,
          interest: scheduleInterest(rows),
          total: rows.fold(0.0, (t, x) => t + x.pay),
          term: n,
          paidCount: k,
          warn: c * n < p ? 'Las cuotas suman menos que lo prestado. Revisa los números.' : null,
        );
      case DebtKind.tarjeta:
        final c = _num(cuota);
        final r = _monthlyRate;
        if (c <= 0) return null;
        final res = _payoff(p, r, c);
        return _Preview(
          balance: p,
          cuota: c,
          rate: r <= 0 ? 0 : _num(rate) / 100,
          rateKind: r <= 0 ? RateKind.ninguna : (rateMonthly ? RateKind.mensual : RateKind.tea),
          months: res.$1 < 0 ? null : res.$1,
          interest: res.$2,
          total: res.$1 < 0 ? 0 : p + res.$2,
          warn: r <= 0
              ? 'Falta la tasa (TEA): sin ella se calcula como si no cobrara interés.'
              : (res.$1 < 0 ? 'Con esa cuota no cubres ni el interés: la deuda crece.' : null),
        );
      case DebtKind.cuota:
        final n = _count;
        if (n <= 0) return null;
        final k = paid.clamp(0, n).toInt();
        final c = p / n;
        final rows = buildSchedule(balance: c * (n - k), r: 0, method: 0, cuota: c, term: n - k, extras: extras);
        return _Preview(
          balance: c * (n - k),
          cuota: c,
          rate: 0,
          rateKind: RateKind.ninguna,
          months: rows.length,
          interest: 0,
          total: c * (n - k),
          term: n,
          paidCount: k,
        );
    }
  }

  bool get _hasSchedule => kind != DebtKind.tarjeta;

  Future<void> _openSchedule(AppStore s, _Preview pv) async {
    final r = pv.rateKind == RateKind.tea
        ? monthlyOf(pv.rate)
        : (pv.rateKind == RateKind.mensual ? pv.rate : 0.0);
    final isLoan = kind == DebtKind.prestamista || kind == DebtKind.otro;
    final res = await Navigator.of(context).push<Map<int, double>>(MaterialPageRoute(
      builder: (_) => CronogramaScreen(
        title: name.text.trim().isEmpty ? 'Nueva deuda' : name.text.trim(),
        balance: pv.balance,
        rate: r,
        method: isLoan ? method : 0,
        cuota: pv.baseCuota,
        term: isLoan ? plazo : (pv.term! - (pv.paidCount ?? 0)),
        extras: extras,
        startYm: _startYm(s),
        applyLabel: 'Usar estos pagos',
      ),
    ));
    if (res != null) setState(() => extras = res);
  }

  void _save(_Preview? pv) {
    if (name.text.trim().isEmpty || pv == null || pv.cuota <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa el nombre y los montos para calcular la deuda.')));
      return;
    }
    StoreScope.of(context).addDebt(Debt(
      id: 'd${DateTime.now().microsecondsSinceEpoch}',
      name: name.text.trim(),
      kind: kind,
      owner: owner,
      balance: pv.balance,
      rateKind: pv.rateKind,
      rate: pv.rate,
      cuota: double.parse(pv.baseCuota.toStringAsFixed(2)),
      payDay: day,
      principal: _num(amount),
      termMonths: pv.term,
      paidCount: pv.paidCount,
      method: (kind == DebtKind.prestamista || kind == DebtKind.otro) ? method : 0,
      extras: _hasSchedule ? extras : const {},
      planStart: _hasSchedule ? _startYm(StoreScope.of(context)) : null,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final pv = _preview();

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t, style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
        );

    Widget field(String l, TextEditingController c, String hint, {bool numeric = true, String? prefix}) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          label(l),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: p.card2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.line),
            ),
            child: Row(children: [
              if (prefix != null) Text(prefix, style: ts(p, 16, w: FontWeight.w700, color: p.muted)),
              Expanded(
                child: TextField(
                  controller: c,
                  keyboardType: numeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  textCapitalization: numeric ? TextCapitalization.none : TextCapitalization.sentences,
                  style: ts(p, 16, w: FontWeight.w600),
                  cursorColor: p.green,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: ts(p, 16, color: p.muted.withValues(alpha: 0.55)),
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
        ]);

    Widget rateField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          label(kind == DebtKind.tarjeta ? 'Tasa (TEA del estado de cuenta)' : 'Tasa de interés'),
          Row(children: [
            Expanded(
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: p.card2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line),
                ),
                child: TextField(
                  controller: rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: ts(p, 16, w: FontWeight.w600),
                  cursorColor: p.green,
                  decoration: InputDecoration(
                    hintText: rateMonthly ? 'Ej. 5' : 'Ej. 68',
                    hintStyle: ts(p, 16, color: p.muted.withValues(alpha: 0.55)),
                    suffixText: '%',
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 8),
            outlineChip(p, 'mensual', on: rateMonthly, onTap: () => setState(() => rateMonthly = true)),
            const SizedBox(width: 6),
            outlineChip(p, 'anual', on: !rateMonthly, onTap: () => setState(() => rateMonthly = false)),
          ]),
          const SizedBox(height: 14),
        ]);

    Widget paidStepper(int max) => Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cuotas que ya pagaste', style: ts(p, 14, w: FontWeight.w700)),
              Text(max > 0 ? 'de $max' : 'Pon primero el número de cuotas',
                  style: ts(p, 12, color: p.muted)),
            ]),
          ),
          stepper(p,
              value: '$paid',
              width: 48,
              onLess: paid > 0 ? () => setState(() => paid--) : null,
              onMore: paid < max ? () => setState(() => paid++) : null,
              lessLabel: 'Una cuota menos',
              moreLabel: 'Una cuota más'),
        ]);

    final List<Widget> specific;
    switch (kind) {
      case DebtKind.prestamista:
      case DebtKind.otro:
        specific = [
          field('¿Cuánto te prestaron? (o lo que debes hoy)', amount, 'Ej. 30,000', prefix: 'S/ '),
          rateField(),
          label('¿Cómo le pagas?'),
          Row(children: [
            for (var m = 0; m < 3; m++) ...[
              if (m > 0) const SizedBox(width: 6),
              Expanded(child: _seg(p, payMethodNames[m], method == m, () => setState(() => method = m))),
            ],
          ]),
          const SizedBox(height: 8),
          Text(
              const [
                'Pagas lo mismo cada mes. Al inicio casi todo es interés.',
                'Bajas lo mismo de capital cada mes y el interés va bajando. Pagas menos interés en total.',
                'Cada mes solo el interés; el capital completo al final.',
              ][method],
              style: ts(p, 12, color: p.muted, h: 1.4)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('¿En cuántos meses quieres terminar?',
                    style: ts(p, 14, w: FontWeight.w700)),
                Text('Termina en ${monthLabel(s.startMonth, plazo, long: true)}',
                    style: ts(p, 12, color: p.muted)),
              ]),
            ),
            stepper(p,
                value: '$plazo',
                width: 44,
                onLess: plazo > 1 ? () => setState(() => plazo--) : null,
                onMore: plazo < 60 ? () => setState(() => plazo++) : null,
                lessLabel: 'Un mes menos',
                moreLabel: 'Un mes más'),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in const [6, 10, 12, 18, 24])
              outlineChip(p, '$m meses', on: plazo == m, onTap: () => setState(() => plazo = m)),
          ]),
        ];
        break;
      case DebtKind.banco:
        specific = [
          field('Monto que te prestaron', amount, 'Ej. 30,000', prefix: 'S/ '),
          Row(children: [
            Expanded(child: field('Cuota mensual', cuota, 'Ej. 1,450', prefix: 'S/ ')),
            const SizedBox(width: 10),
            Expanded(child: field('Número de cuotas', count, 'Ej. 24')),
          ]),
          paidStepper(_count),
          const SizedBox(height: 6),
          Text('No necesitas la tasa: la calculamos con la cuota y el plazo, como la cobra el banco.',
              style: ts(p, 12, color: p.muted, h: 1.4)),
        ];
        break;
      case DebtKind.tarjeta:
        specific = [
          field('Deuda actual de la tarjeta', amount, 'Ej. 8,000', prefix: 'S/ '),
          rateField(),
          field('¿Cuánto pagas al mes?', cuota, 'Ej. 600', prefix: 'S/ '),
        ];
        break;
      case DebtKind.cuota:
        specific = [
          field('Precio total en cuotas', amount, 'Ej. 12,000', prefix: 'S/ '),
          field('Número de cuotas', count, 'Ej. 12'),
          paidStepper(_count),
        ];
        break;
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          CeroHeader(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                backBtn(context),
                const SizedBox(width: 12),
                Text('Nueva deuda', style: hs(26, w: FontWeight.w600, ls: -0.5)),
              ]),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final k in _kinds) ...[
                    headPill(k.$2, kind == k.$1, () => setState(() {
                          kind = k.$1;
                          rateMonthly = k.$1 != DebtKind.tarjeta;
                          paid = 0;
                        })),
                    const SizedBox(width: 8),
                  ],
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  field('¿A quién le debes?', name,
                      kind == DebtKind.banco ? 'Banco, financiera...' : 'Nombre', numeric: false),
                  label('¿De quién es esta deuda?'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final o in Owner.values)
                      outlineChip(p, o.label, on: owner == o, onTap: () => setState(() => owner = o)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Text('Día de pago', style: ts(p, 14, w: FontWeight.w700))),
                    stepper(p,
                        value: 'Día $day',
                        width: 70,
                        onLess: day > 1 ? () => setState(() => day--) : null,
                        onMore: day < 31 ? () => setState(() => day++) : null,
                        lessLabel: 'Día anterior',
                        moreLabel: 'Día siguiente'),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: specific),
              ),
              const SizedBox(height: 14),
              _result(p, s, pv),
              if ((kind == DebtKind.prestamista || kind == DebtKind.otro) && pv != null) ...[
                const SizedBox(height: 14),
                _compare(p),
              ],
              const SizedBox(height: 16),
              wideButton(p, 'Guardar deuda', () => _save(pv)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _seg(Pal p, String t, bool on, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? p.cta : Colors.transparent,
            border: on ? null : Border.all(color: p.line, width: 1.5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(t, style: ts(p, 13, w: FontWeight.w700, color: on ? p.onCta : p.muted)),
        ),
      );

  Widget _result(Pal p, AppStore s, _Preview? pv) {
    if (pv == null) {
      return panel(
        p,
        radius: 26,
        pad: const EdgeInsets.all(18),
        child: Text('Completa los montos y aquí verás la cuota, cuándo terminas y cuánto interés pagas.',
            style: ts(p, 13, color: p.muted, h: 1.45)),
      );
    }
    Widget kv(String k, String v, {Color? c}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(k, style: hs(13, color: const Color(0xB3FFFFFF))),
            Text(v, style: hs(14, w: FontWeight.w700, color: c ?? Colors.white)),
          ]),
        );
    final monthly = pv.rateKind == RateKind.tea ? monthlyOf(pv.rate) : (pv.rateKind == RateKind.mensual ? pv.rate : 0.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26),
        border: p.isDark ? Border.all(color: p.line) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(pv.months == null ? 'Lo que pagarías' : 'Tu plan con esta deuda',
            style: hs(13, w: FontWeight.w700, color: mint)),
        const SizedBox(height: 4),
        Text('${method == 1 && (kind == DebtKind.prestamista || kind == DebtKind.otro) ? 'Desde ' : ''}${_m(pv.cuota)} al mes',
            style: hs(30, w: FontWeight.w700, ls: -0.6)),
        if (pv.months != null)
          Text(
              pv.months == 0
                  ? 'Ya está pagada.'
                  : 'Terminas en ${pv.months} ${pv.months == 1 ? 'mes' : 'meses'}, en ${monthLabel(s.startMonth, pv.months!, long: true)}.',
              style: hs(14, color: const Color(0xD9FFFFFF))),
        const SizedBox(height: 6),
        if (pv.term != null && kind == DebtKind.banco) kv('Te queda por pagar', _m(pv.balance)),
        if (pv.paidCount != null && pv.term != null)
          kv('Vas en la cuota', '${(pv.paidCount! + 1).clamp(1, pv.term!)} de ${pv.term}'),
        kv(pv.months == null ? 'Interés en $plazo meses' : 'Interés que pagarás', _m(pv.interest),
            c: pv.interest > 0 ? const Color(0xFFFF9F9F) : mint),
        if (pv.lastPay != null && method != 0) kv('Último pago', _m(pv.lastPay!)),
        if (extras.isNotEmpty && _hasSchedule)
          kv('Adelantos de capital', _m(extras.values.fold(0.0, (t, v) => t + v)), c: mint),
        if (pv.total > 0) kv('Total que pagarás', _m(pv.total)),
        if (monthly > 0) kv('Tasa', '${(monthly * 100).toStringAsFixed(2)}% mensual · TEA ${(teaOf(monthly) * 100).toStringAsFixed(1)}%'),
        if (pv.warn != null) ...[
          const SizedBox(height: 10),
          Text(pv.warn!, style: hs(13, w: FontWeight.w700, color: const Color(0xFFFFC857))),
        ],
        if (_hasSchedule) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _openSchedule(s, pv),
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: mint, width: 1.5),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Text('Ver cronograma y adelantar capital', style: hs(14, w: FontWeight.w700, color: mint)),
            ),
          ),
        ],
      ]),
    );
  }

  double _interestFor(double pr, double r, int n, int m) => scheduleInterest(
      buildSchedule(balance: pr, r: r, method: m, cuota: m == 0 ? amortCuota(pr, r, n) : null, term: n));

  double _first(double pr, double r, int n) {
    final rows = buildSchedule(
        balance: pr, r: r, method: method, cuota: method == 0 ? amortCuota(pr, r, n) : null, term: n);
    return rows.isEmpty ? 0 : rows.first.pay;
  }

  Widget _compare(Pal p) {
    final pr = _num(amount);
    final r = _monthlyRate;
    final terms = {6, 10, 12, 18, 24, plazo}.toList()..sort();
    return panel(
      p,
      radius: 26,
      pad: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Compara plazos', style: ts(p, 17, w: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('Más meses = cuota más baja, pero más interés.', style: ts(p, 12, color: p.muted)),
        const SizedBox(height: 10),
        Row(children: [
          SizedBox(width: 70, child: Text('Plazo', style: ts(p, 12, w: FontWeight.w700, color: p.muted))),
          Expanded(child: Text(method == 1 ? '1ª cuota' : 'Cuota', textAlign: TextAlign.right, style: ts(p, 12, w: FontWeight.w700, color: p.muted))),
          Expanded(child: Text('Interés total', textAlign: TextAlign.right, style: ts(p, 12, w: FontWeight.w700, color: p.muted))),
        ]),
        for (final n in terms) ...[
          const SizedBox(height: 6),
          divider(p),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => plazo = n),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(
                  width: 70,
                  child: Text('$n meses',
                      style: ts(p, 14, w: n == plazo ? FontWeight.w800 : FontWeight.w600,
                          color: n == plazo ? p.green : p.text)),
                ),
                Expanded(
                  child: Text(_m(_first(pr, r, n)),
                      textAlign: TextAlign.right, style: ts(p, 14, w: FontWeight.w700, tab: true)),
                ),
                Expanded(
                  child: Text(_m(_interestFor(pr, r, n, method)),
                      textAlign: TextAlign.right,
                      style: ts(p, 14, w: FontWeight.w700, tab: true, color: p.red)),
                ),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
            'En $plazo meses: cuota fija ${_m(_interestFor(pr, r, plazo, 0))} de interés, '
            'capital fijo ${_m(_interestFor(pr, r, plazo, 1))}, solo interés ${_m(_interestFor(pr, r, plazo, 2))}.',
            style: ts(p, 12, w: FontWeight.w600, color: p.muted, h: 1.4)),
      ]),
    );
  }
}
