import 'package:flutter/material.dart';
import '../icons.dart';
import '../theme.dart';
import '../widgets.dart';
import '../store.dart';
import 'arranque.dart';
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
  final _navs = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void _go(int i) {
    if (i == index) {
      _navs[i].currentState?.popUntil((r) => r.isFirst);
    }
    setState(() => index = i);
  }

  Widget _tab(int i) {
    switch (i) {
      case 0:
        return HoyScreen(onTab: _go);
      case 1:
        return const DeudasScreen();
      case 2:
        return const GastosScreen();
      case 3:
        return const PlanScreen();
      default:
        return const MasScreen();
    }
  }

  /// Computadora: barra lateral fija y cada pestaña con su propia navegación.
  Widget _desktop(BuildContext context) {
    final p = Pal.of(context);
    final s = StoreScope.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Row(children: [
        Container(
          width: 248,
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CeroMark(size: 36, ring: Colors.white),
              const SizedBox(width: 10),
              Text('Cero', style: hs(26, w: FontWeight.w600, ls: -0.5)),
            ]),
            const SizedBox(height: 6),
            Text('Tus deudas, camino a cero', style: hs(12, color: const Color(0x99FFFFFF))),
            const SizedBox(height: 30),
            for (var i = 0; i < _tabs.length; i++) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _go(i),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: i == index ? const Color(0x2938E0A8) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      Icon(i == index ? _tabs[i].$3 : _tabs[i].$2,
                          size: 22, color: i == index ? mint : const Color(0xB3FFFFFF)),
                      const SizedBox(width: 14),
                      Text(_tabs[i].$1,
                          style: hs(15,
                              w: i == index ? FontWeight.w700 : FontWeight.w500,
                              color: i == index ? mint : const Color(0xD9FFFFFF))),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
                  child: Text(s.userName.isEmpty ? 'T' : s.userName[0].toUpperCase(),
                      style: hs(15, w: FontWeight.w700, color: const Color(0xFF04261B))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: hs(14, w: FontWeight.w700)),
                    Text('Hecho por A. Uribe', style: hs(11, color: const Color(0x99FFFFFF))),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: IndexedStack(
            index: index,
            children: [
              for (var i = 0; i < 5; i++)
                Navigator(
                  key: _navs[i],
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (ctx) => Scaffold(
                      backgroundColor: Pal.of(ctx).bg,
                      body: deskBody(ctx, _tab(i), max: i <= 1 ? 1180 : 860),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  static const _tabs = <(String, IconData, IconData)>[
    ('Hoy', Ic.home, Ic.homeOn),
    ('Deudas', Ic.debts, Ic.debtsOn),
    ('Gastos', Ic.wallet, Ic.walletOn),
    ('Plan', Ic.target, Ic.targetOn),
    ('Más', Ic.more, Ic.moreOn),
  ];

  @override
  Widget build(BuildContext context) {
    if (isWide(context)) return _desktop(context);
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
                for (var i = 0; i < 5; i++) _tab(i),
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
