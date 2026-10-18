import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'deudas.dart';
import 'hoy.dart';
import 'ingresos.dart';
import 'pagos.dart';
import 'plan.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  static const _tabs = <(String, IconData)>[
    ('Hoy', Icons.home_outlined),
    ('Deudas', Icons.format_list_bulleted),
    ('Pagos', Icons.check_box_outlined),
    ('Plan', Icons.track_changes),
    ('Ingresos', Icons.groups_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: index,
          children: const [
            HoyScreen(),
            DeudasScreen(),
            PagosScreen(),
            PlanScreen(),
            IngresosScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.nav,
          border: Border(top: BorderSide(color: p.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => index = i),
                      child: SizedBox(
                        height: 56,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 30,
                              decoration: BoxDecoration(
                                color: i == index ? p.tint : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(_tabs[i].$2,
                                  size: 22, color: i == index ? p.pri : p.muted),
                            ),
                            const SizedBox(height: 2),
                            Text(_tabs[i].$1,
                                style: ts(p, 12,
                                    w: i == index ? FontWeight.w700 : FontWeight.w600,
                                    color: i == index ? p.pri : p.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
