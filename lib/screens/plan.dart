import 'package:flutter/material.dart';
import '../format.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final plan = s.plan;
    final base = s.base;
    final saved = base.interest - plan.interest;
    final order = s.order;

    // Meta: cuánto extra hace falta y cuánto queda para vivir.
    final need = s.needForGoal;
    final n = s.people.length;
    final each = n > 0 ? (need / n).ceilToDouble() : 0.0;
    final shares = s.contributions(s.totalCuotas + need);
    double minLeft = double.infinity;
    for (var i = 0; i < n; i++) {
      final left = s.people[i].income - shares[i];
      if (left < minLeft) minLeft = left;
    }
    if (n == 0) minLeft = 0;
    final okLeft = minLeft >= 2000;

    final isAv = s.strategy == Strategy.avalancha;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Text('Plan para salir', style: ts(p, 32, w: FontWeight.w700, ls: -0.6)),
        const SizedBox(height: 14),
        panel(
          p,
          radius: 22,
          pad: const EdgeInsets.all(14),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                _mode(p, 'Más intereses primero', isAv, () => s.setStrategy(Strategy.avalancha)),
                const SizedBox(width: 4),
                _mode(p, 'La más chica primero', !isAv, () => s.setStrategy(Strategy.bolaDeNieve)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Extra cada mes', style: ts(p, 14, w: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text('Además de las cuotas', style: ts(p, 12, color: p.muted)),
                ]),
              ),
              stepper(p,
                  value: money(s.extra),
                  onLess: s.extra <= 0 ? null : () => s.setExtra(s.extra - 250),
                  onMore: s.extra >= 8000 ? null : () => s.setExtra(s.extra + 250),
                  lessLabel: 'Bajar S/ 250',
                  moreLabel: 'Subir S/ 250',
                  width: 76),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        panel(
          p,
          radius: 28,
          color: p.card2,
          pad: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Con este plan quedan libres en', style: ts(p, 14, color: p.muted)),
            const SizedBox(height: 2),
            Text(monthLabel(s.startMonth, plan.months, long: true),
                style: ts(p, 32, w: FontWeight.w700, ls: -0.6, h: 1.1)),
            Text('${plan.months} meses', style: ts(p, 14, w: FontWeight.w600, color: p.muted)),
            const SizedBox(height: 12),
            divider(p),
            const SizedBox(height: 12),
            _kv(p, 'Intereses que pagarán', money(plan.interest), p.red),
            const SizedBox(height: 8),
            _kv(p, 'Ahorran frente a pagar solo cuotas', money(saved), p.green),
            const SizedBox(height: 10),
            Text(
                'Pagando solo las cuotas, terminarían en ${monthLabel(s.startMonth, base.months, long: true)} y pagarían ${money(base.interest)} de intereses.',
                style: ts(p, 13, color: p.muted, h: 1.45)),
          ]),
        ),
        const SizedBox(height: 14),
        panel(
          p,
          pad: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Quiero terminar en', style: ts(p, 16, w: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text('Libres en ${monthLabel(s.startMonth, s.goalMonths, long: true)}',
                      style: ts(p, 12, color: p.muted)),
                ]),
              ),
              stepper(p,
                  value: '${s.goalMonths} meses',
                  onLess: s.goalMonths <= 6 ? null : () => s.setGoal(s.goalMonths - 1),
                  onMore: s.goalMonths >= 24 ? null : () => s.setGoal(s.goalMonths + 1),
                  lessLabel: 'Un mes menos',
                  moreLabel: 'Un mes más',
                  width: 76),
            ]),
            const SizedBox(height: 10),
            divider(p),
            const SizedBox(height: 10),
            _kv(p, 'Extra que necesitan al mes', money(need), p.text, big: true),
            const SizedBox(height: 6),
            _kv(p, 'Si lo ponen en partes iguales', money(each), p.text),
            const SizedBox(height: 6),
            _kv(p, 'Al que menos le queda para vivir', money(minLeft), okLeft ? p.green : p.red),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  need == 0
                      ? 'Con solo las cuotas ya llegan a esa fecha.'
                      : (okLeft
                          ? 'Es posible sin ahogarse. Usen el extra de arriba para verlo en el plan.'
                          : 'Les quedaría muy poco para vivir. Conviene una fecha más lejana o ingresos nuevos.'),
                  style: ts(p, 13, w: FontWeight.w600, color: okLeft ? p.muted : p.red, h: 1.45)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        panel(
          p,
          pad: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Orden en que cierran las deudas', style: ts(p, 16, w: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                'Cuando termina una, su cuota pasa a la siguiente. Siguen pagando ${money(s.totalCuotas + s.extra)} cada mes.',
                style: ts(p, 13, color: p.muted, h: 1.45)),
            const SizedBox(height: 10),
            for (var i = 0; i < order.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(11)),
                    child: Text('${i + 1}', style: ts(p, 12, w: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 112,
                    child: Text(s.debtById(order[i]).name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(p, 13, w: FontWeight.w600)),
                  ),
                  Expanded(
                    child: progressBar(
                        p,
                        plan.months > 0 ? (plan.close[order[i]] ?? plan.months) / plan.months : 1,
                        p.greenFill),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 64,
                    child: Text(monthLabel(s.startMonth, plan.close[order[i]] ?? plan.months),
                        textAlign: TextAlign.right,
                        style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
                  ),
                ]),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _mode(Pal p, String t, bool on, VoidCallback f) => Expanded(
        child: GestureDetector(
          onTap: f,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: on ? p.text : Colors.transparent, borderRadius: BorderRadius.circular(11)),
            child: Text(t,
                style: ts(p, 13,
                    w: on ? FontWeight.w700 : FontWeight.w600, color: on ? p.bg : p.muted)),
          ),
        ),
      );

  Widget _kv(Pal p, String k, String v, Color c, {bool big = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(child: Text(k, style: ts(p, 14, color: p.muted))),
          const SizedBox(width: 8),
          Text(v, style: ts(p, big ? 18 : 15, w: FontWeight.w700, color: c, tab: true)),
        ],
      );
}
