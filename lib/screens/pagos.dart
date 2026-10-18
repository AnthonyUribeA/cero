import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../cats.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

const _wk = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

/// Un pago de un día: una cuota de deuda o un gasto fijo.
class _Ev {
  final String name;
  final String sub;
  final double amount;
  final bool isDebt;
  final Debt? debt;
  final FixedBill? bill;
  const _Ev(this.name, this.sub, this.amount, {required this.isDebt, this.debt, this.bill});
}

List<_Ev> _eventsOn(AppStore s, DateTime d) {
  final last = daysInMonth(d.year, d.month);
  final ym = d.year * 12 + d.month - 1;
  return [
    for (final x in s.debts)
      if (math.min(x.payDay, last) == d.day && x.paymentFor(ym) > 0.005)
        _Ev(x.name, '${x.owner.label} · ${x.rateLabel}', x.paymentFor(ym), isDebt: true, debt: x),
    for (final f in s.fixed)
      if (math.min(f.day, last) == d.day) _Ev(f.name, 'Gasto fijo', f.amount, isDebt: false, bill: f),
  ];
}

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  bool month = false;
  DateTime? sel;
  int monthOffset = 0;

  bool _isCurrentMonth(AppStore s, DateTime d) => d.year == s.now.year && d.month == s.now.month;

  bool _paid(AppStore s, _Ev e) =>
      e.isDebt ? s.paid.contains(e.debt!.id) : s.isFixedPaid(e.bill!);

  void _toggle(AppStore s, _Ev e) {
    if (e.isDebt) {
      s.togglePaid(e.debt!.id);
    } else {
      s.toggleFixed(e.bill!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final today = DateTime(s.now.year, s.now.month, s.now.day);
    final selected = sel ?? today;

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
                Expanded(
                    child: Text(month ? 'Calendario' : 'Pagos',
                        style: hs(28, w: FontWeight.w600, ls: -0.5))),
              ]),
              const SizedBox(height: 14),
              Container(
                width: 180,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  for (final m in const [false, true])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => month = m),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: month == m ? mint : Colors.transparent,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: Text(m ? 'Mes' : 'Día',
                              style: hs(14,
                                  w: FontWeight.w700,
                                  color: month == m ? const Color(0xFF04261B) : Colors.white)),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
              if (!month) _strip(s, today, selected) else _monthNav(s),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(children: [
              if (month) ...[
                _grid(p, s, today, selected),
                const SizedBox(height: 14),
              ],
              _dayCard(p, s, selected),
              if (!month) ...[
                const SizedBox(height: 14),
                _next(p, s, selected),
                const SizedBox(height: 14),
                wideButton(p, 'Ver el mes completo', () => setState(() {
                      month = true;
                      monthOffset = (selected.year - today.year) * 12 + selected.month - today.month;
                    })),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _strip(AppStore s, DateTime today, DateTime selected) {
    final days = [for (var i = -1; i < 13; i++) DateTime(today.year, today.month, today.day + i)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final d in days) ...[
          GestureDetector(
            onTap: () => setState(() => sel = d),
            child: Container(
              width: 58,
              height: 72,
              decoration: BoxDecoration(
                color: d == selected ? mint : Colors.transparent,
                border: Border.all(
                    color: d == selected
                        ? mint
                        : (d == today ? mint : const Color(0x47FFFFFF)),
                    width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${d.day}',
                    style: hs(17,
                        w: FontWeight.w700,
                        color: d == selected
                            ? const Color(0xFF04261B)
                            : (d == today ? mint : Colors.white))),
                Text(d == today ? 'Hoy' : _wk[d.weekday - 1],
                    style: hs(12,
                        w: FontWeight.w600,
                        color: d == selected ? const Color(0xFF04261B) : const Color(0xD9FFFFFF))),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _eventsOn(s, d).isEmpty
                        ? Colors.transparent
                        : (d == selected ? const Color(0xFF04261B) : mint),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }

  DateTime _shownMonth(AppStore s) => DateTime(s.now.year, s.now.month + monthOffset);

  Widget _monthNav(AppStore s) {
    final m = _shownMonth(s);
    Widget arrow(IconData ic, int delta) => GestureDetector(
          onTap: () => setState(() {
            monthOffset += delta;
            final nm = _shownMonth(s);
            sel = DateTime(nm.year, nm.month, 1);
          }),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x47FFFFFF), width: 1.5),
            ),
            child: Icon(ic, color: Colors.white, size: 20),
          ),
        );
    return Row(children: [
      arrow(Icons.chevron_left, -1),
      Expanded(
        child: Text('${_capi(monthsLong[m.month - 1])} ${m.year}',
            textAlign: TextAlign.center, style: hs(20, w: FontWeight.w600)),
      ),
      arrow(Icons.chevron_right, 1),
    ]);
  }

  Widget _grid(Pal p, AppStore s, DateTime today, DateTime selected) {
    final m = _shownMonth(s);
    final n = daysInMonth(m.year, m.month);
    final offset = DateTime(m.year, m.month, 1).weekday - 1;
    final cells = <DateTime?>[
      for (var i = 0; i < offset; i++) null,
      for (var d = 1; d <= n; d++) DateTime(m.year, m.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    double total = 0;
    int count = 0;
    for (final c in cells) {
      if (c == null) continue;
      final ev = _eventsOn(s, c);
      count += ev.length;
      total += ev.fold(0.0, (t, e) => t + e.amount);
    }
    Widget cell(DateTime? d) {
      if (d == null) return const Expanded(child: SizedBox(height: 50));
      final ev = _eventsOn(s, d);
      final isSel = d == selected;
      final isToday = d == today;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => sel = d),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 50,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? mint : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSel ? Border.all(color: mint, width: 1.5) : null,
                ),
                child: Text('${d.day}',
                    style: ts(p, 14,
                        w: isSel || isToday ? FontWeight.w700 : FontWeight.w600,
                        color: isSel
                            ? const Color(0xFF04261B)
                            : (isToday ? p.green : (d.isBefore(today) ? p.muted : p.text)))),
              ),
              const SizedBox(height: 3),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (ev.any((e) => e.isDebt)) _dot(p.red),
                if (ev.any((e) => e.isDebt) && ev.any((e) => !e.isDebt)) const SizedBox(width: 3),
                if (ev.any((e) => !e.isDebt)) _dot(kFijo),
              ]),
            ]),
          ),
        ),
      );
    }

    return panel(
      p,
      radius: 26,
      pad: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$count pagos en el mes', style: ts(p, 13, w: FontWeight.w700, color: p.muted)),
            Text(money(total), style: ts(p, 20, w: FontWeight.w700, tab: true)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          for (final l in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
            Expanded(
                child: Text(l,
                    textAlign: TextAlign.center,
                    style: ts(p, 12, w: FontWeight.w700, color: p.muted))),
        ]),
        for (var r = 0; r < cells.length ~/ 7; r++)
          Row(children: [for (var c = 0; c < 7; c++) cell(cells[r * 7 + c])]),
        const SizedBox(height: 8),
        Row(children: [
          const SizedBox(width: 6),
          _dot(p.red),
          const SizedBox(width: 6),
          Text('Deudas', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
          const SizedBox(width: 16),
          _dot(kFijo),
          const SizedBox(width: 6),
          Text('Gastos fijos', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
        ]),
      ]),
    );
  }

  Widget _dot(Color c) =>
      Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _dayCard(Pal p, AppStore s, DateTime d) {
    final ev = _eventsOn(s, d);
    final editable = _isCurrentMonth(s, d);
    final total = ev.fold(0.0, (t, e) => t + e.amount);
    final paid = editable ? ev.where((e) => _paid(s, e)).fold(0.0, (t, e) => t + e.amount) : 0.0;
    return panel(
      p,
      radius: 26,
      pad: const EdgeInsets.fromLTRB(18, 16, 14, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(dueLong(d), style: ts(p, 18, w: FontWeight.w600))),
            Text(ev.length == 1 ? '1 pago' : '${ev.length} pagos',
                style: ts(p, 12, w: FontWeight.w700, color: p.muted)),
          ]),
        ),
        if (ev.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No hay pagos este día.', style: ts(p, 14, color: p.muted)),
          )
        else ...[
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(money(total), style: ts(p, 32, w: FontWeight.w700, ls: -0.8, tab: true, h: 1.1)),
            const SizedBox(width: 10),
            if (editable)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(total - paid <= 0 ? 'todo pagado' : 'falta ${money(total - paid)}',
                    style: ts(p, 12, w: FontWeight.w700, color: p.green)),
              ),
          ]),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: progressBar(p, total > 0 ? paid / total : 0, p.greenFill, height: 10),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < ev.length; i++) ...[
            if (i > 0) divider(p),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                iconTile(ev[i].isDebt ? Icons.percent : fixedIcon(ev[i].name),
                    ev[i].isDebt ? p.red : kFijo,
                    (ev[i].isDebt ? p.redFill : kFijo).withValues(alpha: 0.16),
                    size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ev[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: editable && _paid(s, ev[i]) ? p.muted : p.text,
                          decoration: editable && _paid(s, ev[i]) ? TextDecoration.lineThrough : null,
                          decorationColor: p.muted,
                        )),
                    Text('${ev[i].isDebt ? 'Deuda' : 'Fijo'} · ${ev[i].sub}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(p, 12, color: p.muted)),
                  ]),
                ),
                const SizedBox(width: 6),
                Text(money(ev[i].amount), style: ts(p, 15, w: FontWeight.w600, tab: true)),
                if (editable)
                  checkBox(p, _paid(s, ev[i]), () => _toggle(s, ev[i]))
                else
                  const SizedBox(width: 12),
              ]),
            ),
          ],
          if (!editable)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6, right: 4),
              child: Text('Podrás marcarlos como pagados cuando llegue ese mes.',
                  style: ts(p, 12, color: p.muted)),
            ),
        ],
      ]),
    );
  }

  Widget _next(Pal p, AppStore s, DateTime from) {
    final rows = <(DateTime, _Ev)>[];
    for (var i = 1; i <= 40 && rows.length < 4; i++) {
      final d = DateTime(from.year, from.month, from.day + i);
      for (final e in _eventsOn(s, d)) {
        if (rows.length < 4) rows.add((d, e));
      }
    }
    return panel(
      p,
      radius: 26,
      pad: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Siguientes días', style: ts(p, 16, w: FontWeight.w600)),
        const SizedBox(height: 2),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) divider(p),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => sel = rows[i].$1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                SizedBox(
                  width: 56,
                  child: Text(dueShort(rows[i].$1),
                      style: ts(p, 12, w: FontWeight.w700, color: p.muted)),
                ),
                Expanded(
                  child: Text(rows[i].$2.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(p, 14, w: FontWeight.w700)),
                ),
                Text(money(rows[i].$2.amount), style: ts(p, 15, w: FontWeight.w600, tab: true)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  static String _capi(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}
