import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../icons.dart';
import '../format.dart';
import '../loan.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'agregar.dart';
import 'cronograma.dart';

class DetalleScreen extends StatelessWidget {
  final String debtId;
  const DetalleScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    if (!s.debts.any((x) => x.id == debtId)) return Scaffold(backgroundColor: p.bg);
    final orig = s.debtById(debtId);
    final d = orig.atMonth(s.ymNow);
    final plan = s.plan;
    final due = nextDue(d.payDay, s.now);
    final n = daysUntil(due, s.now);
    final interest = d.firstMonthInterest.clamp(0, d.cuota).toDouble();
    final capital = d.cuota - interest;
    final share = d.cuota > 0 ? (interest / d.cuota * 100).round() : 0;
    final endMonth = plan.close[d.id] ?? plan.months;
    final remaining = plan.interestBy[d.id] ?? 0;
    final isPaid = s.isPaid(orig);

    // Próximas tres cuotas, según el cronograma de esta deuda.
    final start = d.planStart ?? s.ymNow;
    final all = d.planStart != null
        ? d.schedule
        : buildSchedule(balance: d.balance, r: d.monthlyRate, method: 0, cuota: d.cuota);
    final from = math.max(0, s.ymNow - start);
    final next = <(DateTime, double, double, double)>[
      for (final r in all.skip(from).take(3))
        (
          DateTime((start + r.i) ~/ 12, (start + r.i) % 12 + 1,
              math.min(d.payDay, daysInMonth((start + r.i) ~/ 12, (start + r.i) % 12 + 1))),
          r.pay,
          r.capital + r.extra,
          r.interest,
        ),
    ];
    final extraTotal = d.extras.values.fold(0.0, (t, v) => t + v);

    Widget stat(IconData ic, String v, String l) => Expanded(
          child: panel(
            p,
            radius: 20,
            pad: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(ic, size: 22, color: p.green),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(v, style: ts(p, 18, w: FontWeight.w700, tab: true)),
              ),
              Text(l, style: ts(p, 11, w: FontWeight.w600, color: p.muted)),
            ]),
          ),
        );

    return Scaffold(
      backgroundColor: p.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          CeroHeader(
            bottom: 26,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                backBtn(context),
                const Spacer(),
                circleBtn(Ic.edit, () {
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AgregarScreen(edit: d)));
                }, label: 'Editar deuda'),
                const SizedBox(width: 10),
                circleBtn(Ic.trash, () => _confirmDelete(context, s, orig.id, orig.name), label: 'Eliminar deuda'),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x59FFFFFF), width: 1.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(d.owner.label, style: hs(12, w: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 18),
              Text(d.name, style: hs(28, w: FontWeight.w600, ls: -0.5)),
              const SizedBox(height: 12),
              Text('Saldo pendiente', style: hs(13, color: const Color(0xB3FFFFFF))),
              Text(money(s.balanceOf(orig)), style: hs(44, w: FontWeight.w700, ls: -1.2)),
              const SizedBox(height: 2),
              Text('${d.rateLabel} · cuota ${money(d.cuota)} · día ${d.payDay}',
                  style: hs(13,
                      w: FontWeight.w600,
                      color: d.monthlyRate > 0 ? const Color(0xFFFF9F9F) : mint)),
              if (d.termMonths != null) ...[
                const SizedBox(height: 4),
                Text(
                    '${d.principal != null ? 'Préstamo de ${money(d.principal!)} · ' : ''}'
                    '${isPaid ? 'pagaste la cuota' : 'vas en la cuota'} '
                    '${((d.paidCount ?? 0) + 1).clamp(1, d.termMonths!)} de ${d.termMonths}',
                    style: hs(13, color: const Color(0xB3FFFFFF))),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(children: [
              Row(children: [
                stat(Ic.clock, '$endMonth pagos', 'que faltan'),
                const SizedBox(width: 10),
                stat(Ic.percent, money(interest), 'interés al mes'),
                const SizedBox(width: 10),
                stat(Ic.calendar, _cap(monthLabel(s.startMonth, endMonth)), 'termina'),
              ]),
              const SizedBox(height: 14),
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                      share >= 40
                          ? 'Casi la mitad es interés'
                          : (d.monthlyRate > 0 ? 'Cómo se reparte la cuota' : 'Sin intereses'),
                      style: ts(p, 17, w: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                      d.monthlyRate > 0
                          ? 'De cada cuota de ${money(d.cuota)}, ${money(interest)} se va en intereses. Al año equivale a ${(d.annualRate * 100).toStringAsFixed(1)}%.${share >= 40 ? ' Es de las primeras que conviene cerrar.' : ''}'
                          : 'Toda la cuota baja la deuda. Esta puede esperar mientras cierras las caras.',
                      style: ts(p, 13, color: p.muted, h: 1.5)),
                  const SizedBox(height: 12),
                  splitBar(p, [MapEntry(interest, p.redFill), MapEntry(capital, p.greenFill)]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Interés ${money(interest)}', style: ts(p, 12, w: FontWeight.w700, color: p.red)),
                    Text('Baja la deuda ${money(capital)}',
                        style: ts(p, 12, w: FontWeight.w700, color: p.green)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Próximas cuotas', style: ts(p, 17, w: FontWeight.w600)),
                    Text(inDays(n), style: ts(p, 12, w: FontWeight.w700, color: p.muted)),
                  ]),
                  for (var k = 0; k < next.length; k++) ...[
                    if (k > 0) divider(p),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        SizedBox(
                          width: 52,
                          child: Text(dueShort(next[k].$1),
                              style: ts(p, 12, w: FontWeight.w700, color: p.muted)),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(k == 0 ? 'Este pago' : 'Luego', style: ts(p, 14, w: FontWeight.w700)),
                            Text('Capital ${money(next[k].$3)} · interés ${money(next[k].$4)}',
                                style: ts(p, 12, color: p.muted)),
                          ]),
                        ),
                        Text(money(next[k].$2), style: ts(p, 15, w: FontWeight.w600, tab: true)),
                      ]),
                    ),
                  ],
                  divider(p),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Intereses que aún pagarás', style: ts(p, 13, color: p.muted)),
                      Text('≈ ${money(remaining)}', style: ts(p, 14, w: FontWeight.w700, color: p.red)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              panel(
                p,
                radius: 26,
                pad: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                onTap: () async {
                  final res = await Navigator.of(context).push<Map<int, double>>(MaterialPageRoute(
                    builder: (_) => CronogramaScreen(
                      title: d.name,
                      balance: d.balance,
                      rate: d.monthlyRate,
                      method: d.method,
                      cuota: d.cuota,
                      term: d.remainingTerm,
                      extras: d.extras,
                      startYm: start,
                    ),
                  ));
                  if (res != null) {
                    final off = s.ymNow - (orig.planStart ?? s.ymNow);
                    s.updateDebt(orig.copyWith(extras: {
                      for (final e in orig.extras.entries)
                        if (e.key < off) e.key: e.value,
                      for (final e in res.entries) e.key + off: e.value,
                    }));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Listo: tus nuevos pagos ya están en el plan y el calendario.')));
                    }
                  }
                },
                child: Row(children: [
                  iconTile(Ic.table, p.green, p.okBg, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Cronograma y adelantos', style: ts(p, 15, w: FontWeight.w700)),
                      Text(
                          extraTotal > 0
                              ? 'Tienes ${money(extraTotal)} de capital adelantado en tu plan'
                              : 'Mes a mes. Adelanta capital y mira cuánto ahorras',
                          style: ts(p, 12, color: p.muted)),
                    ]),
                  ),
                  Icon(Ic.next, color: p.muted),
                ]),
              ),
              const SizedBox(height: 16),
              wideButton(p, isPaid ? 'Marcar como pendiente' : 'Registrar pago de este mes',
                  () => s.togglePaid(orig.id)),
              const SizedBox(height: 10),
              Row(children: [
                bigButton(p, 'Sumar S/ 500 de extra al plan', () {
                  s.setExtra(s.extra + 500);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Se sumaron S/ 500 de extra al plan.')));
                }, outline: true),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppStore s, String id, String name) {
    final p = Pal.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Eliminar $name?', style: ts(p, 18, w: FontWeight.w700)),
        content: Text('Se borra la deuda, su cronograma y sus pagos marcados. No se puede deshacer.',
            style: ts(p, 14, color: p.muted, h: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: ts(p, 14, w: FontWeight.w700, color: p.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              s.removeDebt(id);
            },
            child: Text('Eliminar', style: ts(p, 14, w: FontWeight.w700, color: p.red)),
          ),
        ],
      ),
    );
  }

  static String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}
