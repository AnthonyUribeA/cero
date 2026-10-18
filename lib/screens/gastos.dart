import 'package:flutter/material.dart';
import '../cats.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'agregar_gasto.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  int tab = 0; // 0 resumen, 1 fijos, 2 variables, 3 hormiga

  void _add(int kind) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => AgregarGastoScreen(initialKind: kind)));
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    const names = ['Resumen', 'Fijos', 'Variables', 'Hormiga'];

    final List<Widget> body;
    switch (tab) {
      case 1:
        body = _fijos(p, s);
        break;
      case 2:
        body = _variables(p, s);
        break;
      case 3:
        body = _hormiga(p, s);
        break;
      default:
        body = _resumen(p, s);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        CeroHeader(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Gastos', style: hs(30, w: FontWeight.w600, ls: -0.5))),
              circleBtn(Icons.add, () => _add(tab == 1 ? 0 : (tab == 2 ? 1 : 2)),
                  label: 'Agregar gasto'),
            ]),
            const SizedBox(height: 2),
            Text('${monthsLong[s.now.month - 1]} ${s.now.year}',
                style: hs(14, color: const Color(0xB3FFFFFF))),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < names.length; i++) ...[
                  headPill(names[i], i == tab, () => setState(() => tab = i)),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: body),
        ),
      ],
    );
  }

  // ---------- Resumen ----------
  List<Widget> _resumen(Pal p, AppStore s) {
    final free = s.freeMargin;
    final legend = <(String, double, Color)>[
      ('Fijos', s.fixedTotal, kFijo),
      ('Variables', s.varBudgetTotal, kVar),
      ('Hormiga', s.hormigaCap, kHormiga),
      ('Libre', free < 0 ? 0.0 : free, mint),
    ];
    return [
      panel(
        p,
        radius: 26,
        pad: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Libre este mes, después de gastos',
              style: ts(p, 14, w: FontWeight.w600, color: p.muted)),
          const SizedBox(height: 2),
          Text(money(free),
              style: ts(p, 38, w: FontWeight.w700, ls: -1, tab: true, h: 1.1,
                  color: free < 0 ? p.red : p.green)),
          const SizedBox(height: 12),
          splitBar(p, [for (final l in legend) MapEntry(l.$2, l.$3)], height: 14),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in legend) outlineChip(p, '${l.$1} ${money(l.$2)}', dot: l.$3, border: l.$3),
          ]),
          const SizedBox(height: 10),
          Text(
              'Ingresos ${money(s.totalIncome + s.extraIncomeMonth)} menos cuotas de deuda ${money(s.totalCuotas)}.',
              style: ts(p, 12, color: p.muted, h: 1.4)),
        ]),
      ),
      const SizedBox(height: 14),
      _fijosCard(p, s, limit: 5),
      const SizedBox(height: 14),
      _hormigaCard(p, s),
    ];
  }

  Widget _fijosCard(Pal p, AppStore s, {int? limit}) {
    final items = limit == null ? s.fixed : s.fixed.take(limit).toList();
    return panel(
      p,
      radius: 26,
      pad: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Fijos del mes', style: ts(p, 18, w: FontWeight.w600)),
          Text('Pagado ${money(s.fixedPaidSum)}',
              style: ts(p, 12, w: FontWeight.w700, color: p.green)),
        ]),
        const SizedBox(height: 4),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) divider(p),
          _fixedRow(p, s, items[i]),
        ],
      ]),
    );
  }

  Widget _fixedRow(Pal p, AppStore s, FixedBill f) {
    final paid = s.isFixedPaid(f);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        iconTile(fixedIcon(f.name), kFijo, kFijo.withValues(alpha: 0.16), size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: paid ? p.muted : p.text,
                  decoration: paid ? TextDecoration.lineThrough : null,
                  decorationColor: p.muted,
                )),
            Text('Día ${f.day} de cada mes', style: ts(p, 12, color: p.muted)),
          ]),
        ),
        Text(money(f.amount),
            style: ts(p, 16, w: FontWeight.w600, tab: true, color: paid ? p.muted : p.text)),
        checkBox(p, paid, () => s.toggleFixed(f)),
      ]),
    );
  }

  Widget _hormigaCard(Pal p, AppStore s) {
    final spent = s.hormigaSpent;
    final cap = s.hormigaCap;
    final frac = cap > 0 ? spent / cap : 0.0;
    final byCat = <String, double>{};
    for (final e in s.monthExpenses(ExpenseKind.hormiga)) {
      byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    }
    final cats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return panel(
      p,
      radius: 26,
      pad: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Gastos hormiga', style: ts(p, 18, w: FontWeight.w600)),
          Text('${(frac * 100).round()}% del tope',
              style: ts(p, 12, w: FontWeight.w700, color: frac > 1 ? p.red : kHormiga)),
        ]),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(money(spent), style: ts(p, 28, w: FontWeight.w700, tab: true)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('de ${money(cap)}', style: ts(p, 13, w: FontWeight.w600, color: p.muted)),
          ),
        ]),
        const SizedBox(height: 10),
        progressBar(p, frac, frac > 1 ? p.redFill : kHormiga, height: 10),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in cats) outlineChip(p, '${c.key} ${money(c.value)}'),
        ]),
      ]),
    );
  }

  // ---------- Fijos ----------
  List<Widget> _fijos(Pal p, AppStore s) {
    return [
      _fijosCard(p, s),
      const SizedBox(height: 14),
      wideButton(p, 'Agregar gasto fijo', () => _add(0)),
    ];
  }

  // ---------- Variables ----------
  List<Widget> _variables(Pal p, AppStore s) {
    final cats = s.varBudget.keys.toList();
    return [
      panel(
        p,
        radius: 26,
        pad: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Presupuesto del mes', style: ts(p, 18, w: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final c in cats) ...[
            Row(children: [
              iconTile(catIcon(c), kVar, kVar.withValues(alpha: 0.16), size: 36),
              const SizedBox(width: 10),
              Expanded(child: Text(c, style: ts(p, 15, w: FontWeight.w700))),
              Text('${money(s.varSpent(c))} de ${money(s.varBudget[c] ?? 0)}',
                  style: ts(p, 12, w: FontWeight.w600, color: p.muted, tab: true)),
            ]),
            const SizedBox(height: 8),
            progressBar(
                p,
                (s.varBudget[c] ?? 0) > 0 ? s.varSpent(c) / (s.varBudget[c] ?? 1) : 0,
                s.varSpent(c) > (s.varBudget[c] ?? 0) ? p.redFill : kVar,
                height: 8),
            const SizedBox(height: 14),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      _entries(p, s, ExpenseKind.variable, 'Anotados este mes'),
      const SizedBox(height: 14),
      wideButton(p, 'Agregar gasto variable', () => _add(1)),
    ];
  }

  // ---------- Hormiga ----------
  List<Widget> _hormiga(Pal p, AppStore s) {
    return [
      _hormigaCard(p, s),
      const SizedBox(height: 14),
      panel(
        p,
        radius: 26,
        pad: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tope del mes', style: ts(p, 15, w: FontWeight.w700)),
              Text('Lo que te permites gastar en cosas chicas',
                  style: ts(p, 12, color: p.muted, h: 1.4)),
            ]),
          ),
          stepper(p,
              value: money(s.hormigaCap),
              width: 78,
              onLess: () => s.setHormigaCap(s.hormigaCap - 50),
              onMore: () => s.setHormigaCap(s.hormigaCap + 50),
              lessLabel: 'Bajar el tope',
              moreLabel: 'Subir el tope'),
        ]),
      ),
      const SizedBox(height: 14),
      _entries(p, s, ExpenseKind.hormiga, 'Anotados este mes'),
      const SizedBox(height: 14),
      wideButton(p, 'Anotar gasto hormiga', () => _add(2)),
    ];
  }

  Widget _entries(Pal p, AppStore s, ExpenseKind k, String title) {
    final list = s.monthExpenses(k);
    return panel(
      p,
      radius: 26,
      pad: const EdgeInsets.fromLTRB(18, 16, 10, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(title, style: ts(p, 18, w: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text('Todavía no hay gastos este mes.', style: ts(p, 13, color: p.muted)),
          ),
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) divider(p),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              iconTile(catIcon(list[i].category), k == ExpenseKind.hormiga ? kHormiga : kVar,
                  (k == ExpenseKind.hormiga ? kHormiga : kVar).withValues(alpha: 0.16),
                  size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(list[i].note, style: ts(p, 15, w: FontWeight.w700)),
                  Text('${list[i].category} · ${dueShort(list[i].date)} · ${list[i].method}',
                      style: ts(p, 12, color: p.muted)),
                ]),
              ),
              Text('−${money(list[i].amount)}', style: ts(p, 15, w: FontWeight.w600, tab: true)),
              GestureDetector(
                onTap: () => s.removeExpense(list[i].id),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.close, size: 16, color: p.muted),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
