import 'package:flutter/material.dart';
import '../export.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'arranque.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);

    Widget group(String title, List<Widget> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
              child: Text(title, style: ts(p, 12, w: FontWeight.w600, color: p.muted, ls: 0.4)),
            ),
            panel(
              p,
              pad: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) divider(p),
                  rows[i],
                ],
              ]),
            ),
          ],
        );

    Widget sw(int i, String t, String sub) =>
        switchTile(p, t, sub, s.alerts[i], (v) => s.setAlert(i, v));

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(children: [
              roundButton(p, Icons.chevron_left, () => Navigator.of(context).pop(), label: 'Volver'),
              const SizedBox(width: 12),
            ]),
            const SizedBox(height: 12),
            screenTitle(p, 'Alertas y datos de la app', 'Ajustes'),
            group('AVISOS DE PAGO', [
              sw(0, '3 días antes', 'Te avisamos para que separes el dinero'),
              sw(1, 'El día del vencimiento', 'Un aviso por la mañana'),
              sw(2, 'Si un pago queda sin marcar', 'Al día siguiente, a quien es dueño de la deuda'),
              sw(3, 'Resumen de los domingos', 'Qué vence esta semana y cuánto aporta cada uno'),
            ]),
            group('EN FAMILIA', [
              sw(4, 'Avisar a los tres', 'Las deudas de “Varios” llegan a todos'),
              sw(5, 'Avisar cuando otro marca un pago', 'Para que todos vean el avance'),
            ]),
            group('DATOS', [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => exportExcel(context, s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Exportar a Excel', style: ts(p, 15, w: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Todas las deudas, los aportes y el calendario del plan',
                            style: ts(p, 12, color: p.muted, h: 1.4)),
                      ]),
                    ),
                    Icon(Icons.ios_share, color: p.pri, size: 22),
                  ]),
                ),
              ),
            ]),
            group('APARIENCIA', [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  for (final m in const [
                    (ThemeMode.system, 'Del sistema'),
                    (ThemeMode.dark, 'Oscuro'),
                    (ThemeMode.light, 'Claro'),
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => s.setTheme(m.$1),
                        child: Container(
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: s.themeMode == m.$1 ? p.pri : p.card2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m.$2,
                              style: ts(p, 13,
                                  w: FontWeight.w700,
                                  color: s.themeMode == m.$1 ? p.onPri : p.text)),
                        ),
                      ),
                    ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            panel(
              p,
              pad: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(children: [
                const CeroMark(size: 48),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cero · versión 1.0', style: ts(p, 16, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Hecho por A. Uribe', style: ts(p, 13, color: p.muted)),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
