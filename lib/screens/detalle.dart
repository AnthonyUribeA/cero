import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class DetalleScreen extends StatelessWidget {
  final String debtId;
  const DetalleScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final d = s.debtById(debtId);
    final plan = s.plan;
    final due = nextDue(d.payDay, s.now);
    final n = daysUntil(due, s.now);
    final interest = d.firstMonthInterest.clamp(0, d.cuota).toDouble();
    final capital = d.cuota - interest;
    final share = d.cuota > 0 ? (interest / d.cuota * 100).round() : 0;
    final endMonth = plan.close[d.id] ?? plan.months;
    final remaining = plan.interestBy[d.id] ?? 0;
    final isPaid = s.paid.contains(d.id);

    // Próximas tres cuotas, solo con la cuota de esta deuda.
    final next = <(DateTime, double, double, double)>[];
    var bal = d.balance;
    for (var k = 0; k < 3 && bal > 0.5; k++) {
      final i = bal * d.monthlyRate;
      final pay = math.min(d.cuota, bal + i);
      final date = DateTime(due.year, due.month + k, 1);
      final day = math.min(d.payDay, daysInMonth(date.year, date.month));
      next.add((DateTime(date.year, date.month, day), pay, pay - i, i));
      bal = bal + i - pay;
    }

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
              Text(money(d.balance), style: hs(44, w: FontWeight.w700, ls: -1.2)),
              const SizedBox(height: 2),
              Text('${d.rateLabel} · cuota ${money(d.cuota)} · día ${d.payDay}',
                  style: hs(13,
                      w: FontWeight.w600,
                      color: d.monthlyRate > 0 ? const Color(0xFFFF9F9F) : mint)),
              if (d.principal != null && d.termMonths != null) ...[
                const SizedBox(height: 4),
                Text('Préstamo de ${money(d.principal!)} en ${d.termMonths} cuotas',
                    style: hs(13, color: const Color(0xB3FFFFFF))),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(children: [
              Row(children: [
                stat(Icons.schedule, '$endMonth pagos', 'que faltan'),
                const SizedBox(width: 10),
                stat(Icons.percent, money(interest), 'interés al mes'),
                const SizedBox(width: 10),
                stat(Icons.event_outlined, _cap(monthLabel(s.startMonth, endMonth)), 'termina'),
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
                            Text('Cuota ${k + 1}', style: ts(p, 14, w: FontWeight.w700)),
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
              const SizedBox(height: 16),
              wideButton(p, isPaid ? 'Marcar como pendiente' : 'Registrar pago de este mes',
                  () => s.togglePaid(d.id)),
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

  static String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}
