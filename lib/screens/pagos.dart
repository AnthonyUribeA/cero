import 'package:flutter/material.dart';
import '../format.dart';
import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class PagosScreen extends StatelessWidget {
  const PagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final now = s.now;
    final list = [...s.debts]
      ..sort((a, b) => nextDue(a.payDay, now).compareTo(nextDue(b.payDay, now)));

    final total = s.totalCuotas;
    final paidSum = list.where((d) => s.paid.contains(d.id)).fold(0.0, (t, d) => t + d.cuota);
    final pct = total > 0 ? paidSum / total : 0.0;
    final allPaid = list.isNotEmpty && paidSum >= total;
    final nextId = list.where((d) => !s.paid.contains(d.id)).map((d) => d.id).firstOrNull;
    final lastDue = list.isEmpty ? now : nextDue(list.last.payDay, now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        screenTitle(p, 'Marca cada pago cuando lo hagas', 'Pagos que vienen'),
        const SizedBox(height: 16),
        panel(
          p,
          radius: 28,
          color: p.card2,
          pad: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ya pagaron', style: ts(p, 14, color: p.muted)),
              Text(money(paidSum), style: ts(p, 44, w: FontWeight.w700, ls: -1.3, tab: true, h: 1.1)),
              const SizedBox(height: 2),
              Text('de ${money(total)} que vencen hasta el ${dueShort(lastDue)}',
                  style: ts(p, 14, color: p.muted)),
              const SizedBox(height: 14),
              progressBar(p, pct, p.greenFill, height: 12),
              const SizedBox(height: 14),
              allPaid
                  ? Text('Todo al día. No deben nada de este ciclo.',
                      style: ts(p, 15, w: FontWeight.w700, color: p.green))
                  : Text('Faltan ${money(total - paidSum)}', style: ts(p, 15, w: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        panel(
          p,
          pad: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) divider(p),
                _item(p, s, list[i], list[i].id == nextId, now),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        panel(
          p,
          pad: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Si les sobra dinero este mes', style: ts(p, 16, w: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  'Pónganlo en la deuda que más intereses cobra. Con un extra de S/ 500 al mes ahorran ${money(_ahorro(s))} en intereses.',
                  style: ts(p, 13, color: p.muted, h: 1.45)),
            ],
          ),
        ),
      ],
    );
  }

  int _ahorro(AppStore s) {
    final a = simulate(s.debts, s.order, 0, roll: true).interest;
    final b = simulate(s.debts, s.order, 500, roll: true).interest;
    return a - b;
  }

  Widget _item(Pal p, AppStore s, Debt d, bool isNext, DateTime now) {
    final paid = s.paid.contains(d.id);
    final due = nextDue(d.payDay, now);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => s.togglePaid(d.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: paid ? p.greenFill : Colors.transparent,
              border: paid ? null : Border.all(color: p.muted, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: paid ? Icon(Icons.check, size: 18, color: p.isDark ? const Color(0xFF06231A) : Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(d.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: paid ? FontWeight.w600 : FontWeight.w700,
                      color: paid ? p.muted : p.text,
                      decoration: paid ? TextDecoration.lineThrough : null,
                      decorationColor: p.muted,
                    )),
                ownerChip(p, d.owner),
                if (isNext)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(999)),
                    child: Text('Sigue', style: ts(p, 11, w: FontWeight.w700)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text('${dueLong(due)}, ${d.rateLabel}', style: ts(p, 12, color: p.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          Text(money(d.cuota),
              style: ts(p, 15, w: FontWeight.w700, color: paid ? p.muted : p.text, tab: true)),
        ]),
      ),
    );
  }
}
