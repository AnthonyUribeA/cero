import 'package:flutter/material.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes.dart';

class HoyScreen extends StatelessWidget {
  const HoyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final now = s.now;

    // Próximo pago sin marcar.
    final pending = s.debts.where((d) => !s.paid.contains(d.id)).toList()
      ..sort((a, b) => nextDue(a.payDay, now).compareTo(nextDue(b.payDay, now)));
    final next = pending.isEmpty ? null : pending.first;

    final plan = s.plan;
    final income = s.totalIncome;
    final cuotas = s.totalCuotas;
    final interest = s.totalInterest;
    final lowers = (cuotas - interest).clamp(0, double.infinity).toDouble();
    final live = income - cuotas;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        screenTitle(
          p,
          '${_cap(weekdays[now.weekday - 1])} ${now.day} de ${monthsLong[now.month - 1]}',
          'Hoy',
          trailing: roundButton(p, Icons.settings_outlined, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AjustesScreen()));
          }, label: 'Ajustes'),
        ),
        const SizedBox(height: 16),
        if (next != null) _nextCard(context, p, s, next) else _allDone(p),
        const SizedBox(height: 14),
        panel(
          p,
          pad: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A dónde va el ingreso de ${money(income)}',
                  style: ts(p, 17, w: FontWeight.w700)),
              const SizedBox(height: 12),
              splitBar(p, [
                MapEntry(interest, p.redFill),
                MapEntry(lowers, p.greenFill),
                MapEntry(live < 0 ? 0.0 : live, p.track),
              ], height: 14),
              const SizedBox(height: 12),
              _legend(p, p.redFill, 'Se van en intereses', money(interest)),
              const SizedBox(height: 8),
              _legend(p, p.greenFill, 'Bajan la deuda', money(lowers)),
              const SizedBox(height: 8),
              _legend(p, p.track, 'Quedan para vivir', money(live)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        panel(
          p,
          pad: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Libres de deudas en ${monthLabel(s.startMonth, plan.months, long: true)}',
                  style: ts(p, 17, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  'Si cada mes siguen pagando ${money(cuotas + s.extra)}, aunque terminen algunas deudas por el camino.',
                  style: ts(p, 13, color: p.muted, h: 1.45)),
              const SizedBox(height: 12),
              for (final id in s.order) ...[
                _closeRow(p, s, id, plan.months, plan.close[id] ?? plan.months),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _nextCard(BuildContext context, Pal p, AppStore s, Debt d) {
    final due = nextDue(d.payDay, s.now);
    final n = daysUntil(due, s.now);
    final interest = d.firstMonthInterest.clamp(0, d.cuota).toDouble();
    final capital = d.cuota - interest;
    return panel(
      p,
      radius: 28,
      color: p.card2,
      pad: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lo próximo que vence', style: ts(p, 14, color: p.muted)),
          const SizedBox(height: 2),
          Row(children: [
            Text(d.name, style: ts(p, 24, w: FontWeight.w700, ls: -0.2)),
            const SizedBox(width: 8),
            ownerChip(p, d.owner),
          ]),
          const SizedBox(height: 2),
          Text('${dueLong(due)}, ${inDays(n)}',
              style: ts(p, 14, w: FontWeight.w600, color: p.red)),
          const SizedBox(height: 14),
          Text(money(d.cuota), style: ts(p, 50, w: FontWeight.w700, ls: -1.5, tab: true, h: 1)),
          const SizedBox(height: 14),
          splitBar(p, [MapEntry(interest, p.redFill), MapEntry(capital, p.greenFill)]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Interés ${money(interest)}', style: ts(p, 13, w: FontWeight.w600, color: p.red)),
              Text('Baja la deuda ${money(capital)}',
                  style: ts(p, 13, w: FontWeight.w600, color: p.green)),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [bigButton(p, 'Registrar pago', () => s.togglePaid(d.id))]),
        ],
      ),
    );
  }

  Widget _allDone(Pal p) => panel(
        p,
        radius: 28,
        color: p.card2,
        pad: const EdgeInsets.all(22),
        child: Text('Todo al día. No hay pagos pendientes este ciclo.',
            style: ts(p, 17, w: FontWeight.w700, color: p.green)),
      );

  Widget _legend(Pal p, Color c, String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(label, style: ts(p, 14, color: p.muted)),
          ]),
          Text(value, style: ts(p, 14, w: FontWeight.w700, tab: true)),
        ],
      );

  Widget _closeRow(Pal p, AppStore s, String id, int total, int month) {
    final d = s.debtById(id);
    return Row(children: [
      SizedBox(
        width: 118,
        child: Text(d.name,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(p, 13, w: FontWeight.w600)),
      ),
      const SizedBox(width: 10),
      Expanded(child: progressBar(p, total > 0 ? month / total : 1, p.greenFill)),
      const SizedBox(width: 10),
      SizedBox(
        width: 64,
        child: Text(monthLabel(s.startMonth, month),
            textAlign: TextAlign.right, style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
      ),
    ]);
  }

  String _cap(String t) => t[0].toUpperCase() + t.substring(1);
}
