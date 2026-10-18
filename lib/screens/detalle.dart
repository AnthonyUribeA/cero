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

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(children: [
              roundButton(p, Icons.chevron_left, () => Navigator.of(context).pop(),
                  label: 'Volver a mis deudas'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(d.name, style: ts(p, 24, w: FontWeight.w700, ls: -0.4)),
              ),
              ownerChip(p, d.owner),
            ]),
            const SizedBox(height: 16),
            panel(
              p,
              radius: 28,
              color: p.card2,
              pad: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo pendiente', style: ts(p, 14, color: p.muted)),
                  Text(money(d.balance), style: ts(p, 44, w: FontWeight.w700, ls: -1.3, tab: true, h: 1.1)),
                  const SizedBox(height: 14),
                  if (d.monthlyRate > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: p.warn, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                          '${d.rateLabel} · equivale a ${(d.annualRate * 100).toStringAsFixed(1)}% al año',
                          style: ts(p, 13, w: FontWeight.w700, color: p.red)),
                    ),
                  const SizedBox(height: 16),
                  Text('Cómo se reparte la cuota de ${money(d.cuota)}',
                      style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
                  const SizedBox(height: 8),
                  splitBar(p, [MapEntry(interest, p.redFill), MapEntry(capital, p.greenFill)]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Intereses ${money(interest)}',
                        style: ts(p, 12, w: FontWeight.w700, color: p.red)),
                    Text('Baja la deuda ${money(capital)}',
                        style: ts(p, 12, w: FontWeight.w700, color: p.green)),
                  ]),
                ],
              ),
            ),
            if (share >= 40) ...[
              const SizedBox(height: 14),
              panel(
                p,
                radius: 20,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.warning_amber_rounded, color: p.red, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'El $share% de lo que pagas cada mes se va en intereses. Conviene cerrarla pronto.',
                        style: ts(p, 13, color: p.muted, h: 1.45)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            panel(
              p,
              pad: EdgeInsets.zero,
              child: Column(children: [
                _row(p, 'Próximo pago', '${dueShort(due)} · ${inDays(n)}'),
                divider(p),
                _row(p, 'Termina de pagarse',
                    '${monthLabel(s.startMonth, endMonth)} · $endMonth pagos'),
                divider(p),
                _row(p, 'Intereses que aún pagarán', '≈ ${money(remaining)}', color: p.red),
                divider(p),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Dueño de la deuda', style: ts(p, 13, color: p.muted)),
                    ownerChip(p, d.owner),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              bigButton(p, isPaid ? 'Marcar pendiente' : 'Registrar pago', () => s.togglePaid(d.id)),
              const SizedBox(width: 12),
              bigButton(p, 'Pago extra', () {
                s.setExtra(s.extra + 500);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Se sumaron S/ 500 de extra al plan.')));
              }, outline: true),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(Pal p, String l, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: ts(p, 13, color: p.muted)),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right, style: ts(p, 14, w: FontWeight.w700, color: color)),
          ),
        ]),
      );
}
