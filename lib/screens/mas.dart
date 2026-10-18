import 'package:flutter/material.dart';
import '../export.dart';
import '../format.dart';
import '../models.dart';
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
                Icon(Icons.chevron_right, size: 20, color: p.muted),
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
              circleBtn(Icons.settings_outlined, () {
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
              onTap: () => Navigator.of(context).push(subPage(const IngresosScreen())),
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
                            width: 36, height: 30, child: Icon(Icons.close, size: 16, color: p.muted)),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            wideButton(p, 'Agregar ingreso extra', () => _addIncome(context)),
            const SizedBox(height: 14),
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(children: [
                row(Icons.notifications_none, 'Alertas y ajustes', 'Avisos de pago y datos de la app', () {
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AjustesScreen()));
                }, top: false),
                row(Icons.file_download_outlined, 'Exportar a Excel', 'Deudas, aportes y calendario',
                    () => exportExcel(context, s)),
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

  void _addIncome(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _IncomeSheet(),
    );
  }
}

class _IncomeSheet extends StatefulWidget {
  const _IncomeSheet();

  @override
  State<_IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends State<_IncomeSheet> {
  final labelC = TextEditingController();
  final amountC = TextEditingController();
  String tag = 'Extra';
  String? error;

  @override
  void dispose() {
    labelC.dispose();
    amountC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: ts(p, 16, color: p.muted),
          isCollapsed: true,
          border: InputBorder.none,
        );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ingreso extra', style: ts(p, 20, w: FontWeight.w700)),
          const SizedBox(height: 14),
          Text('Qué fue', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: labelC,
            style: ts(p, 16, w: FontWeight.w600),
            cursorColor: p.green,
            textCapitalization: TextCapitalization.sentences,
            decoration: deco('Aporte de mamá, trabajo extra...'),
          ),
          const SizedBox(height: 10),
          divider(p),
          const SizedBox(height: 12),
          Text('Monto', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: amountC,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: ts(p, 22, w: FontWeight.w700),
            cursorColor: p.green,
            decoration: deco('S/ 0.00'),
          ),
          const SizedBox(height: 10),
          divider(p),
          const SizedBox(height: 12),
          Row(children: [
            for (final t in const ['Extra', 'Familia']) ...[
              outlineChip(p, t, on: tag == t, onTap: () => setState(() => tag = t)),
              const SizedBox(width: 8),
            ],
          ]),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: ts(p, 12, w: FontWeight.w700, color: p.red)),
          ],
          const SizedBox(height: 16),
          wideButton(p, 'Guardar ingreso', () {
            final a = double.tryParse(amountC.text.trim().replaceAll(',', '.'));
            if (a == null || a <= 0) {
              setState(() => error = 'Pon un monto mayor que cero');
              return;
            }
            final l = labelC.text.trim();
            s.addIncome(IncomeItem(
              id: 'i${DateTime.now().microsecondsSinceEpoch}',
              label: l.isEmpty ? tag : l,
              amount: a,
              date: DateTime(s.now.year, s.now.month, s.now.day),
              tag: tag,
            ));
            Navigator.of(context).pop();
          }),
        ]),
      ),
    );
  }
}
