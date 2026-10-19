import 'package:flutter/material.dart';
import '../icons.dart';
import '../export.dart';
import '../format.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes.dart';
import 'arranque.dart';
import 'ingresos.dart';

class MasScreen extends StatelessWidget {
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final extras = s.incomes.where((i) => i.date.year == s.now.year && i.date.month == s.now.month).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final total = s.totalIncome + s.extraIncomeMonth;

    Widget row(IconData ic, String title, String sub, VoidCallback onTap, {bool top = true}) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(children: [
            if (top) divider(p),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(children: [
                iconTile(ic, p.text, p.card2, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: ts(p, 15, w: FontWeight.w700)),
                    Text(sub, style: ts(p, 12, color: p.muted)),
                  ]),
                ),
                Icon(Ic.next, size: 20, color: p.muted),
              ]),
            ),
          ]),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        CeroHeader(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Más', style: hs(30, w: FontWeight.w600, ls: -0.5))),
              circleBtn(Ic.gear, () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AjustesScreen()));
              }, label: 'Ajustes'),
            ]),
            const SizedBox(height: 2),
            Text('Ingresos, alertas y ajustes', style: hs(14, color: const Color(0xB3FFFFFF))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IngresosScreen())),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Ingresos del mes', style: ts(p, 18, w: FontWeight.w600)),
                  Text(money(total), style: ts(p, 22, w: FontWeight.w700, color: p.green, tab: true)),
                ]),
                const SizedBox(height: 4),
                Text('Sueldos ${money(s.totalIncome)} y ${money(s.extraIncomeMonth)} de extras',
                    style: ts(p, 12, color: p.muted)),
                const SizedBox(height: 8),
                for (final i in extras) ...[
                  divider(p),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(i.label, style: ts(p, 15, w: FontWeight.w700)),
                          Text('${dueShort(i.date)} · ${i.tag}', style: ts(p, 12, color: p.muted)),
                        ]),
                      ),
                      Text('+${money(i.amount)}',
                          style: ts(p, 15, w: FontWeight.w600, color: p.green, tab: true)),
                      GestureDetector(
                        onTap: () => s.removeIncome(i.id),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                            width: 36, height: 30, child: Icon(Ic.close, size: 16, color: p.muted)),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            wideButton(p, 'Agregar ingreso extra', () => showIncomeSheet(context)),
            const SizedBox(height: 14),
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(children: [
                row(Ic.bell, 'Alertas y ajustes', 'Avisos de pago y datos de la app', () {
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AjustesScreen()));
                }, top: false),
                row(Ic.download, 'Exportar a Excel', 'Deudas, aportes y calendario',
                    () => exportExcel(context, s)),
                row(Ic.reset, 'Empezar de cero', 'Borra los datos de ejemplo para poner los tuyos',
                    () => _confirmReset(context, s)),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    divider(p),
                    const SizedBox(height: 12),
                    Text('Apariencia', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(21)),
                      child: Row(children: [
                        for (final m in const [
                          (ThemeMode.system, 'Auto'),
                          (ThemeMode.light, 'Claro'),
                          (ThemeMode.dark, 'Oscuro'),
                        ])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => s.setTheme(m.$1),
                              child: Container(
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: s.themeMode == m.$1 ? mint : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(m.$2,
                                    style: ts(p, 13,
                                        w: FontWeight.w700,
                                        color: s.themeMode == m.$1 ? const Color(0xFF04261B) : p.muted)),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CeroMark(size: 26),
              const SizedBox(width: 8),
              Text('Cero', style: ts(p, 18, w: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text('Hecho por A. Uribe', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
          ]),
        ),
      ],
    );
  }


  void _confirmReset(BuildContext context, AppStore s) {
    final p = Pal.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Empezar de cero?', style: ts(p, 18, w: FontWeight.w700)),
        content: Text(
            'Se borran todas las deudas, gastos, ingresos y pagos marcados. Luego la app te guía para poner los tuyos. No se puede deshacer.',
            style: ts(p, 14, color: p.muted, h: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: ts(p, 14, w: FontWeight.w700, color: p.muted)),
          ),
          TextButton(
            onPressed: () {
              s.resetAll();
              Navigator.of(ctx).pop();
            },
            child: Text('Borrar todo', style: ts(p, 14, w: FontWeight.w700, color: p.red)),
          ),
        ],
      ),
    );
  }
}
