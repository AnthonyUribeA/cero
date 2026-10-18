import 'package:flutter/material.dart';
import '../icons.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class IngresosScreen extends StatelessWidget {
  const IngresosScreen({super.key});

  static const _owners = [Owner.tu, Owner.pareja, Owner.persona3];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final total = s.totalIncome;
    final cuotas = s.totalCuotas;
    final aportes = s.contributions(cuotas);
    final debtPct = total > 0 ? (cuotas / total * 100).round() : 100;
    final pcts = [
      for (final x in s.people) total > 0 ? (x.income / total * 100).round() : 0
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        screenTitle(p, 'Cada uno aporta según lo que gana', 'Ingresos y reparto'),
        const SizedBox(height: 16),
        panel(
          p,
          radius: 28,
          color: p.card2,
          pad: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ingreso de los ${s.people.length} cada mes', style: ts(p, 14, color: p.muted)),
            Text(money(total), style: ts(p, 44, w: FontWeight.w700, ls: -1.3, tab: true, h: 1.1)),
            const SizedBox(height: 14),
            splitBar(p, [
              for (var i = 0; i < s.people.length; i++)
                MapEntry(s.people[i].income, p.own[_owners[i]]!),
            ], height: 14),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (var i = 0; i < s.people.length; i++)
                Text('${s.people[i].short} ${pcts[i]}%',
                    style: ts(p, 13, w: FontWeight.w600, color: p.own[_owners[i]])),
            ]),
            const SizedBox(height: 10),
            Text(
                'Los pagos de deudas usan el $debtPct% de lo que ganan. Lo saludable es menos de 35%.',
                style: ts(p, 13, w: FontWeight.w600, color: debtPct > 35 ? p.red : p.green, h: 1.45)),
          ]),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < s.people.length; i++) ...[
          _person(p, s, i, aportes[i]),
          const SizedBox(height: 12),
        ],
        panel(
          p,
          pad: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Ic.people, color: p.pri, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Los tres verán los mismos pagos en su iPhone. Cuando uno marque un pago, los demás lo verán.',
                  style: ts(p, 13, color: p.muted, h: 1.45)),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _person(Pal p, AppStore s, int i, double aporte) {
    final x = s.people[i];
    final o = _owners[i];
    final left = x.income - aporte;
    final cobro = i == 0 ? 'Cobras el día ${x.payDay}' : 'Cobra el día ${x.payDay}';
    return panel(
      p,
      pad: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.ownBg[o], shape: BoxShape.circle),
            child: Text(i == 2 ? '3' : x.short[0],
                style: ts(p, 16, w: FontWeight.w700, color: p.own[o])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(x.name, style: ts(p, 16, w: FontWeight.w700)),
              Text(cobro, style: ts(p, 12, color: p.muted)),
            ]),
          ),
          stepper(p,
              value: money(x.income),
              onLess: x.income <= 0 ? null : () => s.setIncome(i, x.income - 250),
              onMore: x.income >= 30000 ? null : () => s.setIncome(i, x.income + 250),
              lessLabel: 'Bajar sueldo de ${x.name} S/ 250',
              moreLabel: 'Subir sueldo de ${x.name} S/ 250',
              width: 70),
        ]),
        const SizedBox(height: 10),
        divider(p),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text.rich(TextSpan(style: ts(p, 13, color: p.muted), children: [
            TextSpan(text: i == 0 ? 'Aportas ' : 'Aporta '),
            TextSpan(text: money(aporte), style: ts(p, 13, w: FontWeight.w700, tab: true)),
          ])),
          Text.rich(TextSpan(style: ts(p, 13, color: p.muted), children: [
            TextSpan(text: i == 0 ? 'Te quedan ' : 'Le quedan '),
            TextSpan(
                text: money(left),
                style: ts(p, 13, w: FontWeight.w700, color: left < 0 ? p.red : p.text, tab: true)),
          ])),
        ]),
      ]),
    );
  }
}
