import 'package:flutter/material.dart';
import '../icons.dart';
import '../export.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'agregar.dart';
import 'detalle.dart';

const _debtColors = [
  Color(0xFFFF6B6B),
  Color(0xFFFF9F5A),
  Color(0xFFF7C948),
  Color(0xFF38E0A8),
  Color(0xFF4FC3F7),
  Color(0xFFB39DFF),
  Color(0xFFF472B6),
  Color(0xFF9AA29A),
];

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
    final all = [...s.debts]..sort((a, b) => b.annualRate.compareTo(a.annualRate));
    final colorOf = {
      for (var i = 0; i < all.length; i++) all[i].id: _debtColors[i % _debtColors.length]
    };
    final list = all.where(_match).toList();
    const names = ['Todas', 'Prestamistas', 'Bancos', 'Cuotas'];

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        CeroHeader(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Mis deudas', style: hs(30, w: FontWeight.w600, ls: -0.5))),
              circleBtn(Ic.download, () => exportExcel(context, s),
                  label: 'Exportar a Excel'),
              const SizedBox(width: 10),
              circleBtn(Ic.plus, () {
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const AgregarScreen()));
              }, label: 'Agregar deuda'),
            ]),
            const SizedBox(height: 2),
            Text('${s.debts.length} deudas · la más cara primero',
                style: hs(14, color: const Color(0xB3FFFFFF))),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < names.length; i++) ...[
                  headPill(names[i], i == filter, () => setState(() => filter = i)),
                  const SizedBox(width: 8),
                ],
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Debes en total', style: ts(p, 14, w: FontWeight.w600, color: p.muted)),
                const SizedBox(height: 2),
                Text(money(s.totalDebt), style: ts(p, 38, w: FontWeight.w700, ls: -1, tab: true, h: 1.1)),
                const SizedBox(height: 12),
                splitBar(p, [for (final d in all) MapEntry(s.balanceOf(d), colorOf[d.id]!)], height: 14),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final d in all)
                    outlineChip(
                      p,
                      '${d.name.replaceFirst('Préstamo ', '').replaceFirst('Tarjeta ', 'T. ')} ${s.totalDebt > 0 ? (s.balanceOf(d) / s.totalDebt * 100).round() : 0}%',
                      dot: colorOf[d.id],
                      border: colorOf[d.id],
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(children: [
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No hay deudas en este grupo.', style: ts(p, 14, color: p.muted)),
                  ),
                for (var i = 0; i < list.length; i++) ...[
                  if (i > 0) divider(p),
                  _row(context, p, s, list[i]),
                ],
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, Pal p, AppStore s, Debt d) {
    Color fg;
    Color bg;
    switch (d.level) {
      case RateLevel.alta:
        fg = p.red;
        bg = p.warn;
        break;
      case RateLevel.media:
        fg = const Color(0xFFF7C948);
        bg = const Color(0x29F7C948);
        break;
      case RateLevel.ninguna:
        fg = p.green;
        bg = p.okBg;
        break;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => DetalleScreen(debtId: d.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          iconTile(Ic.percent, fg, bg, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(p, 15, w: FontWeight.w700)),
              const SizedBox(height: 3),
              Row(children: [
                Flexible(
                  child: Text(d.rateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(p, 12, w: FontWeight.w600, color: fg)),
                ),
                const SizedBox(width: 6),
                ownerChip(p, d.owner),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(money(s.balanceOf(d)), style: ts(p, 17, w: FontWeight.w600, tab: true)),
            const SizedBox(height: 2),
            Text(s.balanceOf(d) <= 0.5 ? 'Pagada' : 'Cuota ${money(d.paymentFor(s.ymNow))} · día ${d.payDay}',
                style: ts(p, 11, color: p.muted)),
          ]),
        ]),
      ),
    );
  }
}
