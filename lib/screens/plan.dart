import 'package:flutter/material.dart';
import '../cats.dart';
import '../format.dart';
import '../logic.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  static const _goals = [12, 18, 24, 36];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final plan = s.plan;
    final base = s.base;
    final order = s.order;
    final need = s.needForGoal;
    final margin = s.freeMargin;
    final fits = need <= margin;
    final withMargin = margin > 0 ? simulate(s.debts, order, margin, roll: true) : plan;
    final isAv = s.strategy == Strategy.avalancha;

    Widget stat(String v, String l) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(v, style: ts(p, 19, w: FontWeight.w700, ls: -0.3, tab: true)),
            ),
            const SizedBox(height: 2),
            Text(l, style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
          ]),
        );

    Widget line(String k, double v, {Color? c, bool bold = false}) => Padding(
          padding: EdgeInsets.only(top: bold ? 10 : 7, bottom: bold ? 0 : 0),
          child: Column(children: [
            if (bold) ...[divider(p), const SizedBox(height: 10)],
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(k, style: ts(p, 14, w: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? p.text : p.muted)),
              Text(money(v), style: ts(p, 14, w: FontWeight.w700, tab: true, color: c ?? p.text)),
            ]),
          ]),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        CeroHeader(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Plan para salir', style: hs(30, w: FontWeight.w600, ls: -0.5)),
            const SizedBox(height: 2),
            Text('¿En cuántos meses quieres estar en cero?',
                style: hs(14, color: const Color(0xB3FFFFFF))),
            const SizedBox(height: 16),
            Row(children: [
              for (var i = 0; i < _goals.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => s.setGoal(_goals[i]),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.goalMonths == _goals[i] ? mint : Colors.transparent,
                        border: s.goalMonths == _goals[i]
                            ? null
                            : Border.all(color: const Color(0x47FFFFFF), width: 1.5),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Text('${_goals[i]}',
                          style: hs(15,
                              w: FontWeight.w700,
                              color: s.goalMonths == _goals[i] ? const Color(0xFF04261B) : Colors.white)),
                    ),
                  ),
                ),
              ],
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            // Meta
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text('Salir en ${s.goalMonths} meses, en ${monthLabel(s.startMonth, s.goalMonths, long: true)}',
                        style: ts(p, 14, w: FontWeight.w600, color: p.muted)),
                  ),
                  stepper(p,
                      value: '${s.goalMonths}',
                      width: 40,
                      onLess: s.goalMonths <= 3 ? null : () => s.setGoal(s.goalMonths - 1),
                      onMore: s.goalMonths >= 60 ? null : () => s.setGoal(s.goalMonths + 1),
                      lessLabel: 'Un mes menos',
                      moreLabel: 'Un mes más'),
                ]),
                const SizedBox(height: 10),
                if (need <= 0) ...[
                  Text('Con solo las cuotas ya llegas a esa fecha.',
                      style: ts(p, 20, w: FontWeight.w700, color: p.green, h: 1.3)),
                ] else ...[
                  Text('Necesitas, extra al mes', style: ts(p, 13, w: FontWeight.w600, color: p.muted)),
                  Text(money(need),
                      style: ts(p, 38, w: FontWeight.w700, ls: -1, tab: true, h: 1.1, color: p.green)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: fits ? p.okBg : const Color(0x29F7C948),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                        fits
                            ? 'Cabe en tu margen libre de ${money(margin)}. Te quedan ${money(margin - need)} después del extra.'
                            : 'Te faltan ${money(need - margin)} al mes: tu margen libre es ${money(margin)}. '
                                'Con todo tu margen como extra sales en ${withMargin.months} meses, en ${monthLabel(s.startMonth, withMargin.months, long: true)}.',
                        style: ts(p, 13, w: FontWeight.w600, h: 1.45)),
                  ),
                  if (!fits) ...[
                    const SizedBox(height: 8),
                    Text(
                        'Tus gastos hormiga van ${money(s.hormigaSpent)} este mes, con un tope de ${money(s.hormigaCap)}. Bajar ese tope suma directo a tu margen.',
                        style: ts(p, 12, color: p.muted, h: 1.45)),
                  ],
                  const SizedBox(height: 12),
                  wideButton(p, 'Usar ${money(need)} como extra', () => s.setExtra(need)),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            // Estrategia y extra
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _mode(p, 'Más interés primero', isAv, () => s.setStrategy(Strategy.avalancha)),
                  const SizedBox(width: 8),
                  _mode(p, 'Menor saldo primero', !isAv, () => s.setStrategy(Strategy.bolaDeNieve)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Extra cada mes', style: ts(p, 15, w: FontWeight.w700)),
                      Text('Además de las cuotas', style: ts(p, 12, color: p.muted)),
                    ]),
                  ),
                  stepper(p,
                      value: money(s.extra),
                      width: 76,
                      onLess: s.extra <= 0 ? null : () => s.setExtra(s.extra - 250),
                      onMore: s.extra >= 8000 ? null : () => s.setExtra(s.extra + 250),
                      lessLabel: 'Bajar S/ 250',
                      moreLabel: 'Subir S/ 250'),
                ]),
                const SizedBox(height: 14),
                divider(p),
                const SizedBox(height: 14),
                Row(children: [
                  stat('${plan.months}', 'meses'),
                  stat(money(plan.interest), 'intereses'),
                  stat(_cap(monthLabel(s.startMonth, plan.months)), 'termina'),
                ]),
                const SizedBox(height: 10),
                Text(
                    'Pagando solo las cuotas, sin pasar la cuota de una deuda terminada a la siguiente: ${base.months} meses y ${money(base.interest)} de intereses.',
                    style: ts(p, 12, color: p.muted, h: 1.45)),
              ]),
            ),
            const SizedBox(height: 14),
            // Margen real
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Lo que de verdad te queda', style: ts(p, 17, w: FontWeight.w600)),
                const SizedBox(height: 4),
                line('Ingresos del mes', s.totalIncome + s.extraIncomeMonth),
                line('Cuotas de deuda', -s.totalCuotas, c: p.red),
                line('Gastos fijos', -s.fixedTotal, c: p.red),
                line('Variables', -s.varBudgetTotal, c: p.red),
                line('Hormiga (tope)', -s.hormigaCap, c: kHormiga),
                line('Margen libre', margin, c: margin < 0 ? p.red : p.green, bold: true),
              ]),
            ),
            const SizedBox(height: 14),
            // Orden
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Orden en que cierran', style: ts(p, 17, w: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Cuando termina una, su cuota pasa a la siguiente.',
                    style: ts(p, 12, color: p.muted, h: 1.4)),
                const SizedBox(height: 8),
                for (var i = 0; i < order.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.card2, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: ts(p, 12, w: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: Text(s.debtById(order[i]).name,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(p, 13, w: FontWeight.w600)),
                      ),
                      Expanded(
                        child: progressBar(
                            p,
                            plan.months > 0 ? (plan.close[order[i]] ?? plan.months) / plan.months : 1,
                            p.greenFill),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 62,
                        child: Text(monthLabel(s.startMonth, plan.close[order[i]] ?? plan.months),
                            textAlign: TextAlign.right,
                            style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
                      ),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  static String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

  Widget _mode(Pal p, String t, bool on, VoidCallback f) => Expanded(
        child: GestureDetector(
          onTap: f,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? p.cta : Colors.transparent,
              border: on ? null : Border.all(color: p.line, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(t,
                style: ts(p, 12, w: FontWeight.w700, color: on ? p.onCta : p.muted)),
          ),
        ),
      );
}
