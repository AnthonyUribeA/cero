import 'package:flutter/material.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'agregar.dart';
import 'detalle.dart';

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  int filter = 0; // 0 todas, 1 prestamistas, 2 bancos, 3 cuotas

  bool _match(Debt d) {
    switch (filter) {
      case 1:
        return d.kind == DebtKind.prestamista;
      case 2:
        return d.kind == DebtKind.banco || d.kind == DebtKind.tarjeta;
      case 3:
        return d.kind == DebtKind.cuota;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final list = s.debts.where(_match).toList()
      ..sort((a, b) => b.annualRate.compareTo(a.annualRate));
    const names = ['Todas', 'Prestamistas', 'Bancos', 'Cuotas'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        screenTitle(
          p,
          '${s.debts.length} deudas · ${money(s.totalDebt)}',
          'Mis deudas',
          trailing: roundButton(p, Icons.add, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgregarScreen()));
          }, primary: true, label: 'Agregar deuda'),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < names.length; i++) ...[
                GestureDetector(
                  onTap: () => setState(() => filter = i),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == filter ? p.text : p.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(names[i],
                        style: ts(p, 13,
                            w: i == filter ? FontWeight.w700 : FontWeight.w600,
                            color: i == filter ? p.bg : p.text)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Ordenadas por costo: la más cara primero',
            style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
        const SizedBox(height: 10),
        for (final d in list) ...[
          _card(context, p, s, d),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, Pal p, AppStore s, Debt d) {
    final share = s.totalDebt > 0 ? d.balance / s.totalDebt : 0.0;
    Color bg, fg;
    switch (d.level) {
      case RateLevel.alta:
        bg = p.warn;
        fg = p.red;
        break;
      case RateLevel.media:
        bg = p.card2;
        fg = p.text;
        break;
      case RateLevel.ninguna:
        bg = p.okBg;
        fg = p.green;
        break;
    }
    return panel(
      p,
      radius: 20,
      pad: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => DetalleScreen(debtId: d.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(
              child: Text(d.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(p, 16, w: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            ownerChip(p, d.owner),
            const Spacer(),
            Text(money(d.balance), style: ts(p, 17, w: FontWeight.w700, tab: true)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text(d.rateLabel, style: ts(p, 12, w: FontWeight.w700, color: fg)),
            ),
            Text('Cuota ${money(d.cuota)} · día ${d.payDay}',
                style: ts(p, 12, color: p.muted)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: progressBar(p, share, p.pri, height: 6)),
            const SizedBox(width: 10),
            Text('${(share * 100).round()}% del total · ${d.kind.label}',
                style: ts(p, 11, w: FontWeight.w600, color: p.muted)),
          ]),
        ],
      ),
    );
  }
}
