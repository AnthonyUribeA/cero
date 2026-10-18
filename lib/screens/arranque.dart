import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'root.dart';

class CeroMark extends StatelessWidget {
  final double size;
  final Color? ring;
  const CeroMark({super.key, this.size = 120, this.ring});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return CustomPaint(size: Size(size, size), painter: _MarkPainter(p, ring));
  }
}

class _MarkPainter extends CustomPainter {
  final Pal p;
  final Color? ring;
  _MarkPainter(this.p, this.ring);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 120;
    final ringPaint = Paint()
      ..color = ring ?? p.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * k;
    canvas.drawCircle(Offset(60 * k, 60 * k), 32 * k, ringPaint);
    final tick = Paint()
      ..color = p.greenFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(46 * k, 61 * k)
      ..lineTo(56 * k, 71 * k)
      ..lineTo(76 * k, 49 * k);
    canvas.drawPath(path, tick);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.p != p || old.ring != ring;
}

class ArranqueScreen extends StatefulWidget {
  const ArranqueScreen({super.key});

  @override
  State<ArranqueScreen> createState() => _ArranqueScreenState();
}

class _ArranqueScreenState extends State<ArranqueScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RootShell(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 1.1),
            radius: 1.2,
            colors: [Color(0xFF0F5A45), Color(0xFF0A2A22), Colors.black],
            stops: [0, 0.45, 0.85],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CeroMark(ring: Colors.white),
                      const SizedBox(height: 18),
                      Text('Cero', style: hs(46, w: FontWeight.w700, ls: -1.2)),
                      const SizedBox(height: 8),
                      Text('Tus deudas, camino a cero',
                          style: hs(16, color: const Color(0xFF38E0A8), w: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text('Hecho por A. Uribe',
                    style: hs(12, w: FontWeight.w600, color: const Color(0x99FFFFFF), ls: 0.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
