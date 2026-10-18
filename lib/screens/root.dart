import 'package:flutter/material.dart';
import '../icons.dart';
import '../theme.dart';
import '../widgets.dart';
import 'deudas.dart';
import 'gastos.dart';
import 'hoy.dart';
import 'mas.dart';
import 'plan.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  static const _tabs = <(String, IconData, IconData)>[
    ('Hoy', Ic.home, Ic.homeOn),
    ('Deudas', Ic.debts, Ic.debtsOn),
    ('Gastos', Ic.wallet, Ic.walletOn),
    ('Plan', Ic.target, Ic.targetOn),
    ('Más', Ic.more, Ic.moreOn),
  ];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: index,
              children: [
                HoyScreen(onTab: (i) => setState(() => index = i)),
                const DeudasScreen(),
                const GastosScreen(),
                const PlanScreen(),
                const MasScreen(),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: bottom + 10,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: p.nav,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: p.line),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => index = i),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: i == index ? p.tint : Colors.transparent,
                            borderRadius: BorderRadius.circular(27),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(i == index ? _tabs[i].$3 : _tabs[i].$2,
                                  size: 23, color: i == index ? p.pri : p.muted),
                              const SizedBox(height: 2),
                              Text(_tabs[i].$1,
                                  style: ts(p, 11,
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
        ],
      ),
    );
  }
}
