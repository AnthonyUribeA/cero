import 'package:flutter/material.dart';
import '../icons.dart';
import '../cats.dart';
import '../export.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes.dart';
import 'arranque.dart';
import 'pagos.dart';

class _Upcoming {
  final String name;
  final String sub;
  final DateTime due;
  final double amount;
  final IconData icon;
  final Color color;
  const _Upcoming(this.name, this.sub, this.due, this.amount, this.icon, this.color);
}

class HoyScreen extends StatelessWidget {
  final void Function(int) onTab;
  const HoyScreen({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final now = s.now;
    final plan = s.plan;

    final ups = <_Upcoming>[
      for (final d in s.debts)
        if (!s.isPaid(d) && _pay(d, nextDue(d.payDay, now)) > 0.005)
          _Upcoming(d.name, '${d.owner.label} · ${d.rateLabel}', nextDue(d.payDay, now),
              _pay(d, nextDue(d.payDay, now)), Ic.percent, p.red),
      for (final f in s.fixed)
        if (!s.isFixedPaid(f))
          _Upcoming(f.name, 'Gasto fijo', nextDue(f.day, now), f.amount, fixedIcon(f.name), kFijo),
    ]..sort((a, b) => a.due.compareTo(b.due));
    final show = ups.take(3).toList();

    Widget tile(IconData ic, String label, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(22),
                  border: p.isDark ? Border.all(color: p.line) : null,
                ),
                child: Icon(ic, size: 28, color: mint),
              ),
              const SizedBox(height: 8),
              Text(label, style: ts(p, 12, w: FontWeight.w600)),
            ]),
          ),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        CeroHeader(
          bottom: 26,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CeroMark(size: 34, ring: Colors.white),
              const SizedBox(width: 8),
              Text('Cero', style: hs(26, w: FontWeight.w600, ls: -0.5)),
              const Spacer(),
              circleBtn(Ic.bell, () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AjustesScreen()));
              }, label: 'Alertas'),
              const SizedBox(width: 10),
              circleBtn(Ic.gear, () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AjustesScreen()));
              }, label: 'Ajustes'),
            ]),
            const SizedBox(height: 22),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Hola, ', style: hs(26)),
              TextSpan(text: s.userName, style: hs(26, w: FontWeight.w700, color: mint)),
            ])),
            const SizedBox(height: 2),
            Text('Vas rumbo a cero en ${monthLabel(s.startMonth, plan.months, long: true)}',
                style: hs(14, color: const Color(0xB3FFFFFF))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            _dashboard(context, p, s),
            const SizedBox(height: 16),
            Row(children: [
              tile(Ic.target, 'Plan', () => onTab(3)),
              tile(Ic.wallet, 'Gastos', () => onTab(2)),
              tile(Ic.checks, 'Pagos', () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PagosScreen()));
              }),
              tile(Ic.download, 'Excel', () => exportExcel(context, s)),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(26),
                border: p.isDark ? Border.all(color: p.line) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Libre de deudas', style: hs(13, w: FontWeight.w700, color: mint)),
                const SizedBox(height: 2),
                Text(_cap(monthLabel(s.startMonth, plan.months, long: true)),
                    style: hs(30, w: FontWeight.w700, ls: -0.6)),
                const SizedBox(height: 6),
                Text(
                    '${plan.months} meses pagando primero la deuda con más interés. Con S/ 500 extra al mes, terminas antes.',
                    style: hs(13, color: const Color(0xBFFFFFFF)).copyWith(height: 1.5)),
              ]),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Próximos pagos', style: ts(p, 21, w: FontWeight.w600)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PagosScreen())),
                child: Text('Ver todos', style: ts(p, 14, w: FontWeight.w600, color: p.green)),
              ),
            ]),
            const SizedBox(height: 10),
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(children: [
                if (show.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text('Todo al día este ciclo.',
                        style: ts(p, 15, w: FontWeight.w700, color: p.green)),
                  ),
                for (var i = 0; i < show.length; i++) ...[
                  if (i > 0) divider(p),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                      iconTile(show[i].icon, show[i].color, show[i].color.withValues(alpha: 0.16),
                          size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(show[i].name, style: ts(p, 15, w: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${dueShort(show[i].due)} · ${show[i].sub}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ts(p, 12, color: p.muted)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Text('−${money(show[i].amount)}',
                          style: ts(p, 16, w: FontWeight.w600, tab: true)),
                    ]),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _dashboard(BuildContext context, Pal p, AppStore s) {
    final income = s.incomeMonth;
    final avail = s.availableNow;
    final end = s.endOfMonth;
    final cuotas = s.totalCuotas;
    final cPaid = s.cuotasPaid;
    final fixed = s.fixedTotal;
    final fPaid = s.fixedPaidSum;
    final gastado = s.varSpentTotal + s.hormigaSpent;
    final pending = s.pendingDue;
    final libre = avail - pending;
    const amber = Color(0xFFF7C948);

    Widget legend(Color c, String l, double v) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text(l, style: ts(p, 13, color: p.muted))),
            Text(money(v), style: ts(p, 13, w: FontWeight.w700, tab: true)),
          ]),
        );

    Widget kpi(IconData ic, Color c, String label, String value, String sub, {double? frac, VoidCallback? onTap}) =>
        Expanded(
          child: panel(
            p,
            radius: 22,
            pad: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                iconTile(ic, c, c.withValues(alpha: 0.16), size: 34),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(p, 12, w: FontWeight.w700, color: p.muted)),
                ),
              ]),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: ts(p, 22, w: FontWeight.w700, ls: -0.5, tab: true)),
              ),
              const SizedBox(height: 2),
              Text(sub, maxLines: 2, style: ts(p, 11, w: FontWeight.w600, color: p.muted, h: 1.3)),
              if (frac != null) ...[
                const SizedBox(height: 8),
                progressBar(p, frac, frac >= 1 ? p.greenFill : c, height: 6),
              ],
            ]),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Resumen de ${monthsLong[s.now.month - 1]}', style: ts(p, 21, w: FontWeight.w600)),
      const SizedBox(height: 10),
      panel(
        p,
        radius: 26,
        pad: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Disponible hoy', style: ts(p, 14, w: FontWeight.w600, color: p.muted)),
          const SizedBox(height: 2),
          Text(money(avail),
              style: ts(p, 38, w: FontWeight.w700, ls: -1, tab: true, h: 1.1, color: avail < 0 ? p.red : p.text)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(style: ts(p, 13, color: p.muted), children: [
            const TextSpan(text: 'Al cerrar el mes te quedarían '),
            TextSpan(
                text: money(end),
                style: ts(p, 13, w: FontWeight.w700, color: end < 0 ? p.red : p.green)),
            const TextSpan(text: ' si pagas todo y gastas lo presupuestado.'),
          ])),
          const SizedBox(height: 14),
          splitBar(p, [
            MapEntry(cPaid + fPaid, p.greenFill),
            MapEntry(gastado, kHormiga),
            MapEntry(pending, amber.withValues(alpha: 0.45)),
            MapEntry(libre > 0 ? libre : 0.0, p.track),
          ], height: 14),
          legend(p.greenFill, 'Ya pagaste (cuotas y fijos)', cPaid + fPaid),
          legend(kHormiga, 'Gastado (variables y hormiga)', gastado),
          legend(amber.withValues(alpha: 0.45), 'Falta pagar este mes', pending),
          legend(p.track, 'Libre después de pagar', libre),
          const SizedBox(height: 10),
          divider(p),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Ingresos del mes', style: ts(p, 13, w: FontWeight.w700)),
            Text(money(income), style: ts(p, 13, w: FontWeight.w700, tab: true, color: p.green)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        kpi(Ic.debts, p.red, 'Deuda total', money(s.totalDebt),
            'Este mes baja ${money(s.capitalThisMonth)}', onTap: () => onTab(1)),
        const SizedBox(width: 12),
        kpi(Ic.percent, const Color(0xFFFF9F5A), 'Cuotas del mes', money(cuotas),
            cuotas - cPaid <= 0.5 ? 'Todas pagadas' : 'Pagaste ${money(cPaid)} · faltan ${money(cuotas - cPaid)}',
            frac: cuotas > 0 ? cPaid / cuotas : 1,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PagosScreen()))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        kpi(Ic.receipt, kFijo, 'Gastos fijos', money(fixed),
            fixed - fPaid <= 0.5 ? 'Todos pagados' : 'Pagaste ${money(fPaid)} · faltan ${money(fixed - fPaid)}',
            frac: fixed > 0 ? fPaid / fixed : 1, onTap: () => onTab(2)),
        const SizedBox(width: 12),
        kpi(Ic.snack, kHormiga, 'Hormiga y variables', money(gastado),
            'Hormiga ${money(s.hormigaSpent)} de ${money(s.hormigaCap)}',
            frac: s.hormigaCap > 0 ? s.hormigaSpent / s.hormigaCap : 0, onTap: () => onTab(2)),
      ]),
    ]);
  }

  static double _pay(Debt d, DateTime due) => d.paymentFor(due.year * 12 + due.month - 1);

  static String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}
