import 'package:flutter/material.dart';
import '../cats.dart';
import '../export.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes.dart';
import 'arranque.dart';
import 'pagos.dart';

class _Upcoming {
  final String name;
  final String sub;
  final DateTime due;
  final double amount;
  final IconData icon;
  final Color color;
  const _Upcoming(this.name, this.sub, this.due, this.amount, this.icon, this.color);
}

class HoyScreen extends StatelessWidget {
  final void Function(int) onTab;
  const HoyScreen({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    final now = s.now;
    final plan = s.plan;
    final cuotas = s.totalCuotas;
    final paidSum = s.debts.where((d) => s.paid.contains(d.id)).fold(0.0, (t, d) => t + d.cuota);
    final pct = cuotas > 0 ? paidSum / cuotas : 0.0;

    final ups = <_Upcoming>[
      for (final d in s.debts)
        if (!s.paid.contains(d.id))
          _Upcoming(d.name, '${d.owner.label} · ${d.rateLabel}', nextDue(d.payDay, now), d.cuota,
              Icons.percent, p.red),
      for (final f in s.fixed)
        if (!s.isFixedPaid(f))
          _Upcoming(f.name, 'Gasto fijo', nextDue(f.day, now), f.amount, fixedIcon(f.name), kFijo),
    ]..sort((a, b) => a.due.compareTo(b.due));
    final show = ups.take(3).toList();

    Widget tile(IconData ic, String label, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(22),
                  border: p.isDark ? Border.all(color: p.line) : null,
                ),
                child: Icon(ic, size: 28, color: mint),
              ),
              const SizedBox(height: 8),
              Text(label, style: ts(p, 12, w: FontWeight.w600)),
            ]),
          ),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        CeroHeader(
          bottom: 26,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CeroMark(size: 34, ring: Colors.white),
              const SizedBox(width: 8),
              Text('Cero', style: hs(26, w: FontWeight.w600, ls: -0.5)),
              const Spacer(),
              circleBtn(Icons.notifications_none, () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AjustesScreen()));
              }, label: 'Alertas'),
              const SizedBox(width: 10),
              circleBtn(Icons.settings_outlined, () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AjustesScreen()));
              }, label: 'Ajustes'),
            ]),
            const SizedBox(height: 22),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Hola, ', style: hs(26)),
              TextSpan(text: s.userName, style: hs(26, w: FontWeight.w700, color: mint)),
            ])),
            const SizedBox(height: 2),
            Text('Vas rumbo a cero en ${monthLabel(s.startMonth, plan.months, long: true)}',
                style: hs(14, color: const Color(0xB3FFFFFF))),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Pagado este mes', style: ts(p, 14, w: FontWeight.w600, color: p.muted)),
                  Text('${monthsShort[now.month - 1]} ${now.year}', style: ts(p, 12, w: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(money(paidSum), style: ts(p, 38, w: FontWeight.w700, ls: -1, tab: true, h: 1.1)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${(pct * 100).round()}%',
                        style: ts(p, 13, w: FontWeight.w700, color: p.green)),
                  ),
                ]),
                const SizedBox(height: 12),
                progressBar(p, pct, p.greenFill, height: 12),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('de las cuotas del mes', style: ts(p, 12, w: FontWeight.w600, color: p.muted)),
                  Text(money(cuotas), style: ts(p, 12, w: FontWeight.w600, color: p.muted, tab: true)),
                ]),
                const SizedBox(height: 14),
                wideButton(p, 'Ver pagos', () {
                  Navigator.of(context).push(subPage(const PagosScreen()));
                }),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              tile(Icons.track_changes, 'Plan', () => onTab(3)),
              tile(Icons.account_balance_wallet_outlined, 'Gastos', () => onTab(2)),
              tile(Icons.check_box_outlined, 'Pagos', () {
                Navigator.of(context).push(subPage(const PagosScreen()));
              }),
              tile(Icons.file_download_outlined, 'Excel', () => exportExcel(context, s)),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(26),
                border: p.isDark ? Border.all(color: p.line) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Libre de deudas', style: hs(13, w: FontWeight.w700, color: mint)),
                const SizedBox(height: 2),
                Text(_cap(monthLabel(s.startMonth, plan.months, long: true)),
                    style: hs(30, w: FontWeight.w700, ls: -0.6)),
                const SizedBox(height: 6),
                Text(
                    '${plan.months} meses pagando primero la deuda con más interés. Con S/ 500 extra al mes, terminas antes.',
                    style: hs(13, color: const Color(0xBFFFFFFF)).copyWith(height: 1.5)),
              ]),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Próximos pagos', style: ts(p, 21, w: FontWeight.w600)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(subPage(const PagosScreen())),
                child: Text('Ver todos', style: ts(p, 14, w: FontWeight.w600, color: p.green)),
              ),
            ]),
            const SizedBox(height: 10),
            panel(
              p,
              radius: 26,
              pad: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(children: [
                if (show.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text('Todo al día este ciclo.',
                        style: ts(p, 15, w: FontWeight.w700, color: p.green)),
                  ),
                for (var i = 0; i < show.length; i++) ...[
                  if (i > 0) divider(p),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                      iconTile(show[i].icon, show[i].color, show[i].color.withValues(alpha: 0.16),
                          size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(show[i].name, style: ts(p, 15, w: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${dueShort(show[i].due)} · ${show[i].sub}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ts(p, 12, color: p.muted)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Text('−${money(show[i].amount)}',
                          style: ts(p, 16, w: FontWeight.w600, tab: true)),
                    ]),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  static String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}
